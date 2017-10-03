//
//  USIGNormalizador.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/2/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation
import Moya

public class USIGNormalizador {
    public static let api: MoyaProvider<USIGNormalizadorAPI> = MoyaProvider<USIGNormalizadorAPI>()
    
    public class func search() -> USIGNormalizadorController {
        let storyboard = UIStoryboard(name: "USIGNormalizador", bundle: Bundle(for: USIGNormalizador.self))
        
        return storyboard.instantiateViewController(withIdentifier: "USIGNormalizador") as! USIGNormalizadorController
    }
    
    public class func location(latitude: Double, longitude: Double, completion: @escaping (USIGNormalizadorAddress) -> Void) {
        let request = USIGNormalizadorAPI.normalizarCoordenadas(latitud: latitude, longitud: longitude)
        
        USIGNormalizador.api.request(request) { response in
            guard let json = try? response.value?.mapJSON(failsOnEmptyData: false) as? [String: Any],
                let address = json?["direccion"] as? String,
                let street = json?["nombre_calle"] as? String,
                let type = json?["tipo"] as? String else { return }
            
            let result = USIGNormalizadorAddress(
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                street: street.trimmingCharacters(in: .whitespacesAndNewlines),
                number: nil,
                type: type.trimmingCharacters(in: .whitespacesAndNewlines),
                corner: (json?["nombre_calle_cruce"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            completion(result)
        }
    }
}
