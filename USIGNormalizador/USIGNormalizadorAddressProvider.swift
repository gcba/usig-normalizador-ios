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

internal protocol USIGNormalizadorAddressProvider {
    associatedtype API: TargetType
    
    func getStream(from searchStream: Observable<String?>, api provider: RxMoyaProvider<API>) -> Observable<USIGNormalizadorResponse>
    func getResponse(from result: Any, source: TargetType.Type) -> USIGNormalizadorResponse
    func makeNormalizationRequest(from query: String, APIProvider: RxMoyaProvider<USIGNormalizadorAPI>) -> Observable<Any>
}

extension USIGNormalizadorAddressProvider {
    func getResponse(from result: Any, source: TargetType.Type = USIGNormalizadorAPI.self) -> USIGNormalizadorResponse {
        guard let json = result as? [String: Any] else {
            return USIGNormalizadorResponse(source: source, addresses: nil, error: .other("unknown", nil, nil))
        }
        
        if let message = json["errorMessage"] as? String {
            if message.lowercased().contains("calle inexistente") || message.lowercased().contains("no existe a la altura") {
                return USIGNormalizadorResponse(source: source, addresses: nil, error: .streetNotFound("streetNotFound", nil, nil))
            }
            else {
                return USIGNormalizadorResponse(source: source, addresses: nil, error: .service("service", nil, nil))
            }
        }
        
        guard let addresses = json["direccionesNormalizadas"] as? Array<[String: Any]>, addresses.count > 0 else {
            return USIGNormalizadorResponse(source: source, addresses: nil, error: .other("unknown", nil, nil))
        }
        
        return USIGNormalizadorResponse(source: source, addresses: USIGNormalizador.getAddresses(addresses), error: nil)
    }
    
    // TODO: Abstract config --> Make config struct or repurpose existing class
    func makeNormalizationRequest(from query: String, APIProvider: RxMoyaProvider<USIGNormalizadorAPI>) -> Observable<Any> {
        let address = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let request = USIGNormalizadorAPI.normalizar(direccion: address, excluyendo: USIGNormalizadorConfig.exclusionsDefault, geocodificar: true, max: USIGNormalizadorConfig.maxResultsDefault)
        
        return APIProvider
            .request(request)
            .mapJSON()
            .catchErrorJustReturn(Observable.just(USIGNormalizadorResponse(source: USIGNormalizadorAPI.self, addresses: nil, error: .other("json parsing", nil, nil))))
    }
}

internal class NormalizadorAddressProvider: USIGNormalizadorAddressProvider {
    typealias API = USIGNormalizadorAPI

    func getStream(from searchStream: Observable<String?>, api provider: RxMoyaProvider<API>) -> Observable<USIGNormalizadorResponse> {
        // Avoid capturing self
        let makeNormalizationRequest = self.makeNormalizationRequest
        let getResponse = self.getResponse
        
        return searchStream
            .flatMapLatest({ query -> Observable<Any> in
                guard let text = query else { return Observable.empty() }
                
                return makeNormalizationRequest(text, provider)
            })
            .flatMap { item in Observable.from(optional: getResponse(item, USIGNormalizadorAPI.self)) }
    }
}

internal class EpokAddressProvider: USIGNormalizadorAddressProvider {
    typealias API = USIGEpokAPI
    
    let normalizationAPIProvider: RxMoyaProvider<USIGNormalizadorAPI>
    let epokAPIProvider: RxMoyaProvider<API>
    
    init(epokAPIProvider: RxMoyaProvider<USIGEpokAPI>, normalizationAPIProvider: RxMoyaProvider<USIGNormalizadorAPI>) {
        self.epokAPIProvider = epokAPIProvider
        self.normalizationAPIProvider = normalizationAPIProvider
    }
    
    private func makeEpokSearchRequest(_ query: String?) -> Observable<Any> {
        guard let text = query else { return Observable.empty() }
        
        let request = USIGEpokAPI.buscar(texto: text, categoria: nil, clase: nil, boundingBox: nil, start: nil, limit: 3, total: nil)
        
        return epokAPIProvider
            .request(request)
            .mapJSON()
            .catchErrorJustReturn(Observable.just(USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: nil, error: .other("json parsing", nil, nil))))
    }
    
    private func makeEpokGetObjectContentRequest(_ object: String?) -> Observable<Any> {
        guard let id = object else { return Observable.just(USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: nil, error: .other("nil id", nil, nil))) }
        
        let request = USIGEpokAPI.getObjectContent(id: id)
        
        return epokAPIProvider
            .request(request)
            .mapJSON()
            .catchErrorJustReturn(Observable.just(USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: nil, error: .other("json parsing", nil, nil))))
    }
    
    private func filterNormalizationResults(_ value: Any) -> Bool {
        if let json = value as? [String: Any],
            (json["direccionesNormalizadas"] as? [[String: Any]] == nil || (json["direccionesNormalizadas"] as! [[String: Any]]).count == 0),
            json["errorMessage"] as? String != nil {
            return false
        }
        
        return true
    }
    
    func getStream(from searchStream: Observable<String?>, api provider: RxMoyaProvider<USIGEpokAPI>) -> Observable<USIGNormalizadorResponse> {
        // Avoid capturing self
        let normalizationAPIProvider = self.normalizationAPIProvider
        let makeNormalizationRequest = self.makeNormalizationRequest
        let filterNormalizationResults = self.filterNormalizationResults
        let makeEpokGetObjectContentRequest = self.makeEpokGetObjectContentRequest
        let getResponse = self.getResponse
        
        return searchStream
             // Make EPOK Search request
            .flatMapLatest(makeEpokSearchRequest)
            //  Parse, check and make EPOK GetObjectContent request
            .flatMap { result -> Observable<[Any]> in
                if result is USIGNormalizadorError { return Observable.just([result]) }
                
                guard let json = result as? [String: Any], let instances = json["instancias"] as? Array<[String: String]>, instances.count > 0 else {
                    return Observable.just([result])
                }
                
                let requests: [Observable<Any>] = instances.filter { item in item["id"] != nil }.map { item in makeEpokGetObjectContentRequest(item["id"]!) }
                
                return Observable.from(requests)
                    .merge()
                    .toArray()
            }
            // Parse, check and make Normalization request
            .flatMap { result -> Observable<USIGNormalizadorResponse> in
                guard let jsonArray = result as? [[String: Any]] else {
                    return Observable.just(USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: nil, error: .other("json array casting", nil, nil)))
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
                            requests.append(makeNormalizationRequest(normalizedAddress, normalizationAPIProvider))
                            places[normalizedAddress] = name!
                        }
                    }
                }
                
                guard requests.count > 0 else {
                    return Observable.just(USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: nil, error: .other("empty", nil, nil)))
                }
                
                // Parse, check and build response objects
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
                    .flatMap({ array -> Observable<USIGNormalizadorResponse> in
                        let responses: [USIGNormalizadorResponse] = array.map {item in getResponse(item, USIGEpokAPI.self) }
                        let addresses: [USIGNormalizadorAddress] = responses.filter{ item in item.error == nil && item.addresses != nil } .flatMap { item in item.addresses! }

                        return Observable.of(USIGNormalizadorResponse(source: USIGEpokAPI.self, addresses: addresses, error: nil))
                    })
        }
    }
}
