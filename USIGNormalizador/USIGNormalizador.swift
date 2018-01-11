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

    // MARK: - Public API

    public static let api: MoyaProvider<USIGNormalizadorAPI> = MoyaProvider<USIGNormalizadorAPI>()

    public class func searchController() -> USIGNormalizadorController {
        let storyboard = UIStoryboard(name: "USIGNormalizador", bundle: Bundle(for: USIGNormalizador.self))

        return storyboard.instantiateViewController(withIdentifier: "USIGNormalizador") as! USIGNormalizadorController
    }

    public class func search(query: String, excluding: String? = USIGNormalizadorExclusions.AMBA.rawValue, maxResults: Int = 10,
        completion: @escaping ([USIGNormalizadorAddress]?, USIGNormalizadorError?) -> Void) {
        let request = USIGNormalizadorAPI.normalizar(direccion: query, excluyendo: excluding, geocodificar: true, max: maxResults)
        
        api.request(request) { response in
            let defaultError = "Error calling USIG API"
            
            if let error = response.error, let errorMessage = error.errorDescription {
                completion(nil, USIGNormalizadorError.other(errorMessage, response.value?.statusCode, response.value?.response))
                
                return
            }
            
            guard let json = try? response.value?.mapJSON(failsOnEmptyData: false) as? [String: Any] else {
                completion(nil, USIGNormalizadorError.other(defaultError, response.value?.statusCode, response.value?.response))
                
                return
            }
            
            if let message = json?["errorMessage"] as? String {
                if message.lowercased().contains("calle inexistente") || message.lowercased().contains("no existe a la altura") {
                    completion(nil, USIGNormalizadorError.streetNotFound("Street not found", response.value?.statusCode, response.value?.response))
                    
                    return
                }
                else {
                    completion(nil, USIGNormalizadorError.service("\(message)", response.value?.statusCode, response.value?.response))
                    
                    return
                }
            }
            
            guard let addresses = json?["direccionesNormalizadas"] as? Array<[String: Any]>, addresses.count > 0 else {
                completion(nil, USIGNormalizadorError.other(defaultError, response.value?.statusCode, response.value?.response))
                
                return
            }
            
            completion(USIGNormalizador.getAddresses(addresses), nil)
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
                address: address.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
                street: street.trimmingCharacters(in: .whitespacesAndNewlines),
                number: json?["altura"] as? Int,
                type: type.trimmingCharacters(in: .whitespacesAndNewlines),
                corner: (json?["nombre_calle_cruce"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: latitude,
                longitude: longitude,
                districtCode: (json?["cod_partido"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                label: json?["label"] as? String,
                source: USIGNormalizadorAPI.self
            )

            completion(result, nil)
        }
    }

    // MARK: - Utilities

    internal class func getAddress(_ json: [String: Any]) -> USIGNormalizadorAddress {
        let coordinates = json["coordenadas"] as? [String: Any]

        return USIGNormalizadorAddress(
            address: (json["direccion"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            street: (json["nombre_calle"] as! String).trimmingCharacters(in: .whitespacesAndNewlines),
            number: json["altura"] as? Int,
            type: (json["tipo"] as! String).trimmingCharacters(in: .whitespacesAndNewlines),
            corner: (json["nombre_calle_cruce"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: USIGNormalizador.parseCoordinate(fromDict: coordinates, key: "y"),
            longitude: USIGNormalizador.parseCoordinate(fromDict: coordinates, key: "x"),
            districtCode: (json["cod_partido"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
            label: json["label"] as? String,
            source: json["source"] as? TargetType.Type ?? USIGNormalizadorAPI.self
        )
    }

    internal class func getAddresses(_ jsonArray: Array<[String: Any]>) -> [USIGNormalizadorAddress] {
        return jsonArray.map { item in USIGNormalizador.getAddress(item) }
    }

    internal class func parseCoordinate(fromDict dict: [String: Any]?, key: String) -> Double? {
        guard let coordinatesDict = dict else { return nil }

        if let coordinateString = coordinatesDict[key] as? String {
            return Double(coordinateString)
        }

        return coordinatesDict[key] as? Double
    }
}
