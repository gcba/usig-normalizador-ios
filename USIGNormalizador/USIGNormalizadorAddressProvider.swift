//
//  USIGNormalizadorAddressProvider.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 08/01/2018.
//  Copyright © 2018 GCBA. All rights reserved.
//

import Foundation
import RxSwift
import Moya

internal protocol USIGNormalizadorProvider {
    associatedtype API: TargetType
    associatedtype Config
    
    var config: Config { get }
    var apiProvider: Reactive<MoyaProvider<API>> { get }
    
    func getStream(from searchStream: Observable<String>) -> Observable<[USIGNormalizadorResponse]>
    func getResponse(from result: Any) -> USIGNormalizadorResponse
}

extension USIGNormalizadorProvider {
    func getResponse(from result: Any) -> USIGNormalizadorResponse {
        guard let json = result as? [String: Any] else { return USIGNormalizadorResponse(source: API.self, addresses: nil, error: .other("Unknown error")) }
        
        if let message = json["errorMessage"] as? String {
            if message.lowercased().contains("calle inexistente") || message.lowercased().contains("no existe a la altura") {
                return USIGNormalizadorResponse(source: API.self, addresses: nil, error: .streetNotFound("Street not found"))
            }
            else {
                return USIGNormalizadorResponse(source: API.self, addresses: nil, error: .service("Unknown service error"))
            }
        }
        
        guard var addresses = json["direccionesNormalizadas"] as? Array<[String: Any]>, !addresses.isEmpty else {
            return USIGNormalizadorResponse(source: API.self, addresses: nil, error: .other("Unknown error"))
        }
        
        addresses = addresses.map { item in
            var mutableItem = item
            
            mutableItem["source"] = API.self
            
            return mutableItem
        }
        
        return USIGNormalizadorResponse(source: API.self, addresses: addresses.map { item in USIGNormalizadorAddress(from: item) }, error: nil)
    }
}

internal struct NormalizadorProviderConfig {
    let excluyendo: String?
    let geocodificar: Bool
    let max: Int
    let minCharacters: Int
}

internal struct EpokProviderConfig {
    let categoria: String?
    let clase: String?
    let boundingBox: [Double]?
    let start: Int?
    let limit: Int?
    let total: Bool?
    let minCharacters: Int
    let normalization: NormalizadorProviderConfig
}

internal class NormalizadorProvider: USIGNormalizadorProvider {
    typealias API = USIGNormalizadorAPI
    typealias Config = NormalizadorProviderConfig
    
    required init(with config: NormalizadorProviderConfig, api apiProvider: MoyaProvider<API>) {
        self.config = config
        self.apiProvider = apiProvider.rx
    }
    
    let config: Config
    let apiProvider: Reactive<MoyaProvider<API>>
    
    class func makeNormalizationRequest(from query: String, config: NormalizadorProviderConfig, apiProvider: Reactive<MoyaProvider<USIGNormalizadorAPI>>) -> Observable<Any> {
        let address = query.removeWhitespace().uppercased()
        let request = USIGNormalizadorAPI.normalizar(direccion: address, excluyendo: config.excluyendo, geocodificar: config.geocodificar, max: config.max)
        
        return apiProvider
            .request(request)
            .asObservable()
            .mapJSON()
            .catchErrorJustReturn([:] as [String: Any])
    }

    func getStream(from searchStream: Observable<String>) -> Observable<[USIGNormalizadorResponse]> {
        // Avoid capturing self
        let config = self.config
        let apiProvider = self.apiProvider
        let getResponse = self.getResponse
        
        return searchStream
            // Filter by chars
            .flatMap { query -> Observable<String?> in query.count < config.minCharacters ? Observable.just(nil) : Observable.of(query) }
            .flatMap { query -> Observable<Any> in
                guard let text = query else {return Observable.just(USIGNormalizadorResponse(source: API.self, addresses: [], error: nil)) }
                
                return NormalizadorProvider.makeNormalizationRequest(from: text, config: config, apiProvider: apiProvider)
            }
            .flatMap { item -> Observable<[USIGNormalizadorResponse]> in
                guard !(item is USIGNormalizadorResponse) else { return Observable.just([item as! USIGNormalizadorResponse]) }
                
                let response: [USIGNormalizadorResponse] = [getResponse(item)]
                
                return Observable.from(optional: response)
        }
    }
}

internal class EpokProvider: USIGNormalizadorProvider {
    typealias API = USIGEpokAPI
    typealias Config = EpokProviderConfig

    required init(with config: Config, apiProvider: MoyaProvider<API>, normalizationAPIProvider: MoyaProvider<USIGNormalizadorAPI>) {
        self.config = config
        self.apiProvider = apiProvider.rx
        self.normalizationAPIProvider = normalizationAPIProvider.rx
    }
    
    let config: Config
    let apiProvider: Reactive<MoyaProvider<API>>
    let normalizationAPIProvider: Reactive<MoyaProvider<USIGNormalizadorAPI>>
    
    private func makeEpokSearchRequest(_ query: String) -> Observable<Any> {
        let request = USIGEpokAPI.buscar(
            texto: query,
            categoria: config.categoria,
            clase: config.clase,
            boundingBox: config.boundingBox,
            start: config.start,
            limit: config.limit,
            total: config.total
        )
        
        return apiProvider
            .request(request)
            .asObservable()
            .mapJSON()
            .catchErrorJustReturn([:] as [String: Any])
    }
    
    private func makeEpokGetObjectContentRequest(_ id: String) -> Observable<Any> {
        let request = USIGEpokAPI.getObjectContent(id: id)
        
        return apiProvider
            .request(request)
            .asObservable()
            .mapJSON()
            .catchErrorJustReturn([:] as [String: Any])
    }
    
    private func getCoordinates(from point: String) -> [String: String]? {
        let parts = point.split(separator: "(")
        
        if parts.count > 1 {
            let coordinates = parts[1].split(separator: " ")
                        
            if coordinates.count == 2 {
                return ["x": String(coordinates[0]), "y": String(coordinates[1].dropLast())]
            }
        }
        
        return nil
    }
    
    func getStream(from searchStream: Observable<String>) -> Observable<[USIGNormalizadorResponse]> {
        // Avoid capturing self
        let config = self.config
        let makeEpokSearchRequest = self.makeEpokSearchRequest
        let normalizationConfig = self.config.normalization
        let normalizationAPIProvider = self.normalizationAPIProvider
        let makeEpokGetObjectContentRequest = self.makeEpokGetObjectContentRequest
        let getResponse = self.getResponse
        let getCoordinates = self.getCoordinates
        
        return searchStream
            // Filter by chars
            .flatMap { query -> Observable<String?> in query.count < config.minCharacters ? Observable.just(nil) : Observable.of(query) }
            // Make EPOK Search request
            .flatMap { query -> Observable<Any> in
                guard let text = query else {return Observable.just(USIGNormalizadorResponse(source: API.self, addresses: [], error: nil)) }
                
                return makeEpokSearchRequest(text)
            }
            //  Parse, check and make EPOK GetObjectContent request
            .flatMap { result -> Observable<[Any]> in
                guard !(result is USIGNormalizadorResponse) else { return Observable.just([result as! USIGNormalizadorResponse]) }
                
                guard let json = result as? [String: Any], let instances = json["instancias"] as? Array<[String: String]>, !instances.isEmpty else {
                    return Observable.just([USIGNormalizadorResponse(source: API.self, addresses: nil, error: .other("Cannot cast EPOK SearchRequest json arrays"))])
                }
                
                let requests: [Observable<Any>] = instances.filter { item in item["id"] != nil }.map { item in makeEpokGetObjectContentRequest(item["id"]!) }
                
                return Observable.from(requests)
                    .merge()
                    .toArray()
            }
            // Parse, check and make Normalization request
            .flatMap { result -> Observable<[USIGNormalizadorResponse]> in
                guard !(result is [USIGNormalizadorResponse]) else { return Observable.just(result as! [USIGNormalizadorResponse]) }
                
                guard let jsonArray = result as? [[String: Any]] else {
                    return Observable.just(
                        [USIGNormalizadorResponse(source: API.self, addresses: nil, error: .other("Cannot cast EPOK GetObjectContentRequest json arrays"))]
                    )
                }
                
                var requests: [Observable<Any>] = []
                var places: [String: [String]] = [:]
                
                for json in jsonArray {
                    if let normalizedAddress = (json["direccionNormalizada"] as? String)?.uppercased(),
                        !normalizedAddress.isEmpty,
                        let content = json["contenido"] as? [[String: Any]],
                        let ubicacion = json["ubicacion"] as? [String: Any],
                        let centroide = ubicacion["centroide"] as? String {
                        var name: String?
                        var district: String?
                        
                        for item in content {
                            guard let nameId = item["nombreId"] as? String else { continue }
                            
                            if nameId == "nombre", let value = item["valor"] as? String {
                                name = value
                            }
                            else if nameId == "partido", let value = item["valor"] as? String {
                                district = value
                            }
                        }
                        
                        if let name = name, let district = district, let exclusions = normalizationConfig.excluyendo, !exclusions.contains(district.snakeCased()) {
                            let request = NormalizadorProvider.makeNormalizationRequest(
                                from: normalizedAddress,
                                config: normalizationConfig,
                                apiProvider: normalizationAPIProvider
                            )
                            
                            requests.append(request)
                            places[normalizedAddress] = [name, centroide]
                        }
                    }
                }
                
                guard !requests.isEmpty else { return Observable.just([] as! [USIGNormalizadorResponse]) } // No EPOK object has a normalized address
                
                // Parse, check and reduce addresses
                return Observable.from(requests)
                    .merge()
                    .toArray()
                    .scan([] as [[String: Any]], accumulator: { (matrix, item) -> [[String: Any]] in
                        guard let responses = item as? [[String: Any]] else { return [] }
                        
                        var normalizationResponses: [[String: Any]] = []
                        
                        for (var response) in responses {
                            if var normalizedAddresses = response["direccionesNormalizadas"] as? [[String: Any]], !normalizedAddresses.isEmpty, response["errorMessage"] == nil {
                                for (addressIndex, address) in normalizedAddresses.enumerated() {
                                    if let fullAddress = (address["direccion"] as? String)?.uppercased(),
                                        let key = places.keys.first(where: { key in fullAddress.hasPrefix(key) }) {
                                        normalizedAddresses[addressIndex]["label"] = places[key]![0]
                                        response["direccionesNormalizadas"] = normalizedAddresses
                                        
                                        places.removeValue(forKey: key)
                                    }
                                }
                                
                                normalizationResponses.append(response)
                            }
                        }
                        
                        return normalizationResponses
                    })
                    // Build response objects
                    .flatMap { array -> Observable<[USIGNormalizadorResponse]> in
                        var responses: [USIGNormalizadorResponse] = array.filter {item in !item.isEmpty }.map {item in getResponse(item) }
                        var unnormalizedPlaces: [USIGNormalizadorAddress] = []
                        
                        for (key, var value) in places {
                            let addressValues: [String: Any] = [
                                "direccion": key,
                                "nombre_calle": value[0],
                                "label": value[0],
                                "tipo": "calle_y_calle",
                                "coordenadas": getCoordinates(value[1]) as Any,
                                "source": API.self
                            ]
                            
                            unnormalizedPlaces.append(USIGNormalizadorAddress(from: addressValues))
                        }
                        
                        responses.append(USIGNormalizadorResponse(source: API.self, addresses: unnormalizedPlaces, error: nil))
                        
                        return Observable.of(responses)
                    }
        }
    }
}
