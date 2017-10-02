//
//  USIGNormalizadorAPI.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation
import Moya

public enum USIGNormalizadorExclusions: String {
    case GBA = "almirante_brown,avellaneda,berazategui,berisso,canuelas,ensenada,escobar,esteban_echeverria,ezeiza,florencio_varela,general_rodriguez,general_san_martin,hurlingham,ituzaingo,jose_c_paz,la_matanza,lanus,la_plata,lomas_de_zamora,malvinas_argentinas,marcos_paz,merlo,moreno,moron,pilar,presidente_peron,quilmes,san_fernando,san_isidro,san_miguel,san_vicente,tigre,tres_de_febrero,vicente_lopez"
    case none = ""
}

public enum USIGNormalizadorAPI {
    case normalizar(direccion: String, excluyendo: String?, geocodificar: Bool, max: Int)
    case normalizarCoordenadas(latitud: Float, longitud: Float)
}

extension USIGNormalizadorAPI: TargetType {
    public var baseURL: URL { return URL(string: "https://servicios.usig.buenosaires.gob.ar")! }
    
    public var path: String {
        switch self {
        case .normalizarCoordenadas(_, _):
            fallthrough
        case .normalizar(_, _, _, _):
            return "/normalizar"
        }
    }
    
    public var method: Moya.Method { return .get }
    
    public var parameters: [String: Any]? {
        switch self {
        case .normalizar(let direccion, let excluyendo, let geocodificar, let max):
            return ["direccion": direccion, "geocodificar": geocodificar, "maxOptions": max, "exclude": excluyendo ?? ""]
        case .normalizarCoordenadas(let latitud, let longitud):
            return ["lat": latitud, "lng": longitud]
        }
    }
    
    public var sampleData: Data {
        switch self {
        case .normalizarCoordenadas(_, _):
            fallthrough
        case .normalizar(_, _, _, _):
            return ("{\"direccionesNormalizadas\":[{\"altura\":null,\"cod_calle\":7120,\"cod_calle_cruce\":null,\"cod_partido\":\"caba\"," +
                "\"direccion\":\"GOLETA SANTA CRUZ, CABA, CABA\",\"nombre_calle\":\"GOLETA SANTA CRUZ\",\"nombre_calle_cruce\":null,\"" +
                "nombre_localidad\":\"CABA\",\"nombre_partido\":\"CABA\",\"tipo\":\"calle\"}]}").data(using: .utf8)!
        }
    }
    
    public var task: Task { return .request }
    public var parameterEncoding: ParameterEncoding { return URLEncoding.default }
}
