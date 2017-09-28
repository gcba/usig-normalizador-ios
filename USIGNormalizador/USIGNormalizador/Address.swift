//
//  Address.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation
import Moya

enum USIG {
    case normalizar(direccion: String, geocodificar: Bool, max: Int)
    case normalizarCoordenadas(latitud: Float, longitud: Float)
}

extension USIG: TargetType {
    var baseURL: URL { return URL(string: "https://servicios.usig.buenosaires.gob.ar")! }
    
    var path: String {
        switch self {
        case .normalizarCoordenadas(_, _):
            fallthrough
        case .normalizar(_, _, _):
            return "/normalizar"
        }
    }
    
    var method: Moya.Method { return .get }
    
    var parameters: [String: Any]? {
        let exclusions = "almirante_brown,avellaneda,berazategui,berisso,canuelas,ensenada,escobar,esteban_echeverria,ezeiza," +
            "florencio_varela,general_rodriguez,general_san_martin,hurlingham,ituzaingo,jose_c_paz,la_matanza,lanus,la_plata," +
            "lomas_de_zamora,malvinas_argentinas,marcos_paz,merlo,moreno,moron,pilar,presidente_peron,quilmes,san_fernando," +
        "san_isidro,san_miguel,san_vicente,tigre,tres_de_febrero,vicente_lopez"
        
        switch self {
        case .normalizar(let direccion, let geocodificar, let max):
            return ["direccion": direccion, "geocodificar": geocodificar, "maxOptions": max, "exclude": exclusions]
        case .normalizarCoordenadas(let latitud, let longitud):
            return ["lat": latitud, "lng": longitud]
        }
    }
    
    var sampleData: Data {
        switch self {
        case .normalizarCoordenadas(_, _):
            fallthrough
        case .normalizar(_, _, _):
            return ("{\"direccionesNormalizadas\":[{\"altura\":null,\"cod_calle\":7120,\"cod_calle_cruce\":null,\"cod_partido\":\"caba\"," +
                "\"direccion\":\"GOLETA SANTA CRUZ, CABA, CABA\",\"nombre_calle\":\"GOLETA SANTA CRUZ\",\"nombre_calle_cruce\":null,\"" +
                "nombre_localidad\":\"CABA\",\"nombre_partido\":\"CABA\",\"tipo\":\"calle\"}]}").data(using: .utf8)!
        }
    }
    
    var task: Task { return .request }
    var parameterEncoding: ParameterEncoding { return URLEncoding.default }
}
