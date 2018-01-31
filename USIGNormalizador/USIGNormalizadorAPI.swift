//
//  USIGNormalizadorAPI.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation
import Moya

// MARK: - USIG Normalizador API

public enum USIGNormalizadorAPI {
    case normalizar(direccion: String, excluyendo: String?, geocodificar: Bool, max: Int)
    case normalizarCoordenadas(latitud: Double, longitud: Double)
}

public enum USIGNormalizadorExclusions: String {
    case AMBA = "almirante_brown,avellaneda,berazategui,berisso,canuelas,ensenada,escobar,esteban_echeverria,ezeiza,florencio_varela,general_rodriguez,general_san_martin,hurlingham,ituzaingo,jose_c_paz,la_matanza,lanus,la_plata,lomas_de_zamora,malvinas_argentinas,marcos_paz,merlo,moreno,moron,pilar,presidente_peron,quilmes,san_fernando,san_isidro,san_miguel,san_vicente,tigre,tres_de_febrero,vicente_lopez"
    case none = ""
}

extension USIGNormalizadorAPI: TargetType {
    public var baseURL: URL { return URL(string: USIGNormalizadorConfig.endpointNormalizador)! }

    public var path: String {
        switch self {
        case .normalizarCoordenadas(_, _):
            fallthrough
        case .normalizar(_, _, _, _):
            return "/normalizar"
        }
    }

    public var method: Moya.Method { return .get }
    public var headers: [String : String]? { return ["Accept": "application/json"] }
    public var parameterEncoding: ParameterEncoding { return URLEncoding.default }

    public var sampleData: Data {
        switch self {
        case .normalizarCoordenadas(_, _):
            return ("{\"altura\":null,\"cod_calle\":1078,\"cod_calle_cruce\":27017,\"cod_partido\":\"caba\",\"coordenadas\":{\"srid\":4326," + "\"x\":-58.4094824967142,\"y\":-34.601681984424},\"direccion\":\"ANCHORENA, TOMAS MANUEL DE, DR. Y ZELAYA, CABA\"," +
                "\"nombre_calle\":\"ANCHORENA, TOMAS MANUEL DE, DR.\",\"nombre_calle_cruce\":\"ZELAYA\",\"nombre_localidad\":\"CABA\"," +
                "\"nombre_partido\":\"CABA\",\"tipo\":\"calle_y_calle\"}").data(using: .utf8)!
        case .normalizar(_, _, _, _):
            return ("{\"direccionesNormalizadas\":[{\"altura\":null,\"cod_calle\":7120,\"cod_calle_cruce\":null,\"cod_partido\":\"caba\"," +
                "\"direccion\":\"GOLETA SANTA CRUZ, CABA, CABA\",\"nombre_calle\":\"GOLETA SANTA CRUZ\",\"nombre_calle_cruce\":null,\"" +
                "nombre_localidad\":\"CABA\",\"nombre_partido\":\"CABA\",\"tipo\":\"calle\"}]}").data(using: .utf8)!
        }
    }
   
    public var task: Task {
        switch self {
        case .normalizar(let direccion, let excluyendo, let geocodificar, let max):
            var params: [String: Any] = [:]
            
            params["direccion"] = direccion
            params["geocodificar"] = geocodificar ? "true" : "false"
            params["maxOptions"] = max
            params["exclude"] = excluyendo // If excluyendo is nil, the key doesn`t get added at all
            params["tipoResultado"] = "calle_altura_calle_y_calle"

            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        case .normalizarCoordenadas(let latitud, let longitud):
            let params: [String: Any] = ["lat": latitud, "lng": longitud, "tipoResultado": "calle_altura_calle_y_calle"]
            
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        }
    }
}

// MARK: - USIG Epok API

public enum USIGEpokAPI {
    case getCategorias()
    case getObjectContent(id: String)
    case buscar(texto: String, categoria: String?, clase: String?, boundingBox: [Double]?, start: Int?, limit: Int?, total: Bool?)
    case reverseGeocoderLugares(categorias: [String], latitud: Double, longitud: Double, srid: Int?, radio: Int?)
}

extension USIGEpokAPI: TargetType {
    public var baseURL: URL { return URL(string: USIGNormalizadorConfig.endpointEpok)! }

    public var path: String {
        switch self {
        case .getCategorias:
            return "/getCategorias/"
        case .getObjectContent(_):
            return "/getObjectContent/"
        case .buscar(_, _, _, _, _, _, _):
            return "/buscar/"
        case .reverseGeocoderLugares(_, _, _, _, _):
            return "/reverseGeocoderLugares/"
        }
    }

    public var method: Moya.Method { return .get }
    public var headers: [String : String]? { return ["Accept": "application/json"] }
    public var parameterEncoding: ParameterEncoding { return URLEncoding.default }
    public var sampleData: Data { return Data() }
    
    public var task: Task {
        switch self {
        case .getCategorias:
            return .requestPlain
        case .getObjectContent(let id):
            return .requestParameters(parameters: ["id": id], encoding: URLEncoding.default)
        case .buscar(let texto, let categoria, let clase, let boundingBox, let start, let limit, let total):
            var params: [String: Any] = [:]
            
            params["texto"] = texto
            params["categoria"] = categoria
            params["clase"] = clase
            params["bbox"] = boundingBox != nil ? boundingBox!.flatMap { item in String(item) }.joined(separator: ",") : nil
            params["start"] = start
            params["limit"] = limit
            params["totalFull"] = total != nil ? (total! ? "true" : "false") : nil
            
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        case .reverseGeocoderLugares(let categorias, let latitud, let longitud, let srid, let radio):
            var params: [String: Any] = [:]
            
            params["categorias"] = categorias.joined(separator: ",")
            params["y"] = latitud
            params["x"] = longitud
            params["srid"] = srid
            params["radio"] = radio
            
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        }
    }
}

// MARK: - USIG Response

internal struct USIGNormalizadorResponse {
    let source: TargetType.Type
    let addresses: [USIGNormalizadorAddress]?
    let error: USIGNormalizadorError?
}

