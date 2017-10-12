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
    
    public class func searchController() -> USIGNormalizadorController {
        let storyboard = UIStoryboard(name: "USIGNormalizador", bundle: Bundle(for: USIGNormalizador.self))
        
        return storyboard.instantiateViewController(withIdentifier: "USIGNormalizador") as! USIGNormalizadorController
    }
    
    public class func search(query: String, excluding: String? = nil, maxResults: Int = 10, completion: @escaping ([USIGNormalizadorAddress]?, USIGNormalizadorError?) -> Void) {
        let request = USIGNormalizadorAPI.normalizar(direccion: query, excluyendo: excluding, geocodificar: true, max: maxResults)
        
        api.request(request) { response in
            var result: [USIGNormalizadorAddress] = []
            let defaultError = "Error calling USIG API"
            
            if let error = response.error, let errorMessage = error.errorDescription {
                completion(nil, USIGNormalizadorError.other(errorMessage, response.value?.statusCode, response.value?.response))
                
                return
            }
            
            guard let json = try? response.value?.mapJSON(failsOnEmptyData: false) as? [String: Any] else {
                completion(nil, USIGNormalizadorError.other(defaultError, response.value?.statusCode, response.value?.response))
                
                return
            }
            
            guard let addresses = json?["direccionesNormalizadas"] as? Array<[String: Any]>, addresses.count > 0 else {
                if let message = json?["errorMessage"] as? String {
                    if message.lowercased().contains("calle inexistente") || message.lowercased().contains("no existe a la altura") {
                        completion(nil, USIGNormalizadorError.streetNotFound("Street not found", response.value?.statusCode, response.value?.response))
                    }
                    else {
                        completion(nil, USIGNormalizadorError.service("\(message)", response.value?.statusCode, response.value?.response))
                    }
                }
                else {
                    completion(nil, USIGNormalizadorError.other(defaultError, response.value?.statusCode, response.value?.response))
                }
                
                return
            }
            
            for item in addresses {
                let coordinates = item["coordenadas"] as? [String: Any]
                let latitudeString = coordinates?["y"] as? String
                let longitudeString = coordinates?["x"] as? String
                let latitude = latitudeString != nil ? Double(latitudeString!) : nil
                let longitude = longitudeString != nil ? Double(longitudeString!) : nil
                
                let address = USIGNormalizadorAddress(
                    address: (item["direccion"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
                    street: (item["nombre_calle"] as! String).trimmingCharacters(in: .whitespacesAndNewlines),
                    number: item["altura"] as? Int,
                    type: (item["tipo"] as! String).trimmingCharacters(in: .whitespacesAndNewlines),
                    corner: item["nombre_calle_cruce"] as? String,
                    latitude: latitude,
                    longitude: longitude
                )
                
                result.append(address)
            }
            
            completion(result, nil)
        }
    }
    
    public class func location(latitude: Double, longitude: Double, completion: @escaping (USIGNormalizadorAddress?, USIGNormalizadorError?) -> Void) {
        let request = USIGNormalizadorAPI.normalizarCoordenadas(latitud: latitude, longitud: longitude)
        
        api.request(request) { response in
            if let error = response.error, let errorMessage = error.errorDescription {
                completion(nil, USIGNormalizadorError.other(errorMessage, response.value?.statusCode, response.value?.response))
                
                return
            }
            
            guard let json = try? response.value?.mapJSON(failsOnEmptyData: false) as? [String: Any],
                let address = json?["direccion"] as? String,
                let street = json?["nombre_calle"] as? String,
                let type = json?["tipo"] as? String else {
                    completion(nil, USIGNormalizadorError.notInRange("Location (\(latitude), \(longitude)) not in range", response.value?.statusCode, response.value?.response))
                    
                    return
            }
            
            let result = USIGNormalizadorAddress(
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                street: street.trimmingCharacters(in: .whitespacesAndNewlines),
                number: nil,
                type: type.trimmingCharacters(in: .whitespacesAndNewlines),
                corner: (json?["nombre_calle_cruce"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: latitude,
                longitude: longitude
            )
            
            completion(result, nil)
        }
    }
}
