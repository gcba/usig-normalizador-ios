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
    var apiProvider: MoyaProvider<API> { get }
    
    func getStream(from searchStream: Observable<String>) -> Observable<[USIGNormalizadorResponse]>
    func getResponse(from result: Any) -> USIGNormalizadorResponse
}

extension USIGNormalizadorProvider {
    func getResponse(from result: Any) -> USIGNormalizadorResponse {
        guard let json = result as? [String: Any] else {
            return USIGNormalizadorResponse(source: API.self, addresses: nil, error: .other("Unknown error"))
        }
        
        if let message = json["errorMessage"] as? String {
            if message.lowercased().contains("calle inexistente") || message.lowercased().contains("no existe a la altura") {
                return USIGNormalizadorResponse(source: API.self, addresses: nil, error: .streetNotFound("Street not found"))
            }
            else {
                return USIGNormalizadorResponse(source: API.self, addresses: nil, error: .service("Unknown service error"))
            }
        }
        
        guard var addresses = json["direccionesNormalizadas"] as? Array<[String: Any]>, addresses.count > 0 else {
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
        self.apiProvider = apiProvider
    }
    
    let config: Config
    let apiProvider: MoyaProvider<API>
    
    class func makeNormalizationRequest(from query: String?, config: NormalizadorProviderConfig, apiProvider: MoyaProvider<USIGNormalizadorAPI>) -> Observable<Any> {
        guard let text = query else {
            return Observable.just(USIGNormalizadorResponse(source: API.self, addresses: [], error: nil))
        }
        
        let address = text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let request = USIGNormalizadorAPI.normalizar(direccion: address, excluyendo: config.excluyendo, geocodificar: config.geocodificar, max: config.max)
        
        return apiProvider.rx
            .request(request)
            .mapJSON()
            .asObservable()
            .catchErrorJustReturn(Observable.just(USIGNormalizadorResponse(source: API.self, addresses: nil, error: .other("Cannot parse Normalization json"))))
    }

    func getStream(from searchStream: Observable<String>) -> Observable<[USIGNormalizadorResponse]> {
        // Avoid capturing self
        let config = self.config
        let apiProvider = self.apiProvider
        let getResponse = self.getResponse
        
        return searchStream
            // Filter by chars
            .flatMap({ query -> Observable<String?> in query.count < config.minCharacters ? Observable.just(nil) : Observable.of(query) })
            .flatMap { query in NormalizadorProvider.makeNormalizationRequest(from: query, config: config, apiProvider: apiProvider) }
            .flatMap { item in Observable.from(optional: [getResponse(item)]) }
    }
}

internal class EpokProvider: USIGNormalizadorProvider {
    typealias API = USIGEpokAPI
    typealias Config = EpokProviderConfig

    required init(with config: Config, apiProvider: MoyaProvider<API>, normalizationAPIProvider: MoyaProvider<USIGNormalizadorAPI>) {
        self.config = config
        self.apiProvider = apiProvider
        self.normalizationAPIProvider = normalizationAPIProvider
    }
    
    let config: Config
    let apiProvider: MoyaProvider<API>
    let normalizationAPIProvider: MoyaProvider<USIGNormalizadorAPI>
    
    private func makeEpokSearchRequest(_ query: String?) -> Observable<Any> {
        guard let text = query else {
            return Observable.just(USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: [], error: nil))
        }
        
        let request = USIGEpokAPI.buscar(
            texto: text,
            categoria: config.categoria,
            clase: config.clase,
            boundingBox: config.boundingBox,
            start: config.start,
            limit: config.limit,
            total: config.total
        )
        
        return apiProvider.rx
            .request(request)
            .mapJSON()
            .asObservable()
            .catchErrorJustReturn(
                Observable.just(USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: nil, error: .other("Cannot parse EPOK Search json")))
        )
    }
    
    private func makeEpokGetObjectContentRequest(_ object: String?) -> Observable<Any> {
        guard let id = object else {
            return Observable.just(USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: nil, error: .other("EPOK id for GetObjectContent is nil")))
        }
        
        let request = USIGEpokAPI.getObjectContent(id: id)
        
        return apiProvider.rx
            .request(request)
            .mapJSON()
            .asObservable()
            .catchErrorJustReturn(
                Observable.just(USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: nil, error: .other("Cannot parse EPOK GetObjectContent json")))
        )
    }
    
    private func filterNormalizationResults(_ value: Any) -> Bool {
        if let json = value as? [String: Any],
            (json["direccionesNormalizadas"] as? [[String: Any]] == nil || (json["direccionesNormalizadas"] as! [[String: Any]]).count == 0),
            json["errorMessage"] as? String != nil {
            return false
        }
        
        return true
    }
    
    func getStream(from searchStream: Observable<String>) -> Observable<[USIGNormalizadorResponse]> {
        // Avoid capturing self
        let config = self.config
        let normalizationConfig = self.config.normalization
        let normalizationAPIProvider = self.normalizationAPIProvider
        let filterNormalizationResults = self.filterNormalizationResults
        let makeEpokGetObjectContentRequest = self.makeEpokGetObjectContentRequest
        let getResponse = self.getResponse
        
        return searchStream
            // Filter by chars
            .flatMap({ query -> Observable<String?> in query.count < config.minCharacters ? Observable.just(nil) : Observable.of(query) })
            // Make EPOK Search request
            .flatMap(makeEpokSearchRequest)
            //  Parse, check and make EPOK GetObjectContent request
            .flatMap { result -> Observable<[Any]> in
                guard let json = result as? [String: Any], let instances = json["instancias"] as? Array<[String: String]>, instances.count > 0 else {
                    return Observable.just([result])
                }
                
                let requests: [Observable<Any>] = instances.filter { item in item["id"] != nil }.map { item in makeEpokGetObjectContentRequest(item["id"]!) }
                
                return Observable.from(requests)
                    .merge()
                    .toArray()
            }
            // Parse, check and make Normalization request
            .flatMap { result -> Observable<[USIGNormalizadorResponse]> in
                guard let jsonArray = result as? [[String: Any]] else {
                    if result is [USIGNormalizadorResponse] {
                        return Observable.just(result as! [USIGNormalizadorResponse])
                    }
                    
                    return Observable.just(
                        [USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: nil, error: .other("Cannot cast EPOK GetObjectContentRequest json arrays"))]
                    )
                }
                
                var requests: [Observable<Any>] = []
                var places: [String: String] = [:]
                
                for json in jsonArray {
                    if let normalizedAddress = (json["direccionNormalizada"] as? String)?.uppercased(), !normalizedAddress.isEmpty,
                        let content = json["contenido"] as? [[String: Any]] {
                        var name: String?
                        
                        for item in content {
                            if let nameId = item["nombreId"] as? String, nameId == "nombre", let value = item["valor"] as? String {
                                name = value
                            }
                        }
                        
                        if name != nil {
                            let request = NormalizadorProvider.makeNormalizationRequest(
                                from: normalizedAddress,
                                config: normalizationConfig,
                                apiProvider: normalizationAPIProvider
                            )
                            
                            requests.append(request)
                            places[normalizedAddress] = name!
                        }
                    }
                }
                
                guard requests.count > 0 else {
                    return Observable.just([USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: [], error: nil)]) // No EPOK object has a normalized address
                }
                
                // Parse, check and reduce addresses
                return Observable.from(requests)
                    .merge()
                    .toArray()
                    .filter(filterNormalizationResults)
                    .scan([] as [[String: Any]], accumulator: { (matrix, item) -> [[String: Any]] in
                        let responses = item as! [[String: Any]]
                        var normalizationResponses: [[String: Any]] = []
                        
                        for (var response) in responses {
                            var normalizedAddresses = response["direccionesNormalizadas"] as! [[String: Any]] // We already checked -> filterNormalizationResults
                            
                            for (addressIndex, address) in normalizedAddresses.enumerated() {
                                if let fullAddress = (address["direccion"] as? String)?.uppercased(), let key = places.keys.first(where: { key in fullAddress.hasPrefix(key) }) {
                                    normalizedAddresses[addressIndex]["label"] = places[key]
                                    response["direccionesNormalizadas"] = normalizedAddresses
                                }
                            }
                            
                            normalizationResponses.append(response)
                        }
                        
                        return normalizationResponses
                    })
                    // Build response objects
                    .flatMap({ array -> Observable<[USIGNormalizadorResponse]> in
                        let responses: [USIGNormalizadorResponse] = array.map {item in getResponse(item) }
                        
                        return Observable.of(responses)
                    })
        }
    }
}
