//
//  USIGNormalizador.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/2/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation
import RxSwift
import Moya

public class USIGNormalizador {
    private static let disposeBag: DisposeBag = DisposeBag()
    
    // MARK: - Public API

    public static let api: MoyaProvider<USIGNormalizadorAPI> = MoyaProvider<USIGNormalizadorAPI>()

    public class func searchController() -> USIGNormalizadorController {
        let storyboard = UIStoryboard(name: "USIGNormalizador", bundle: Bundle(for: USIGNormalizador.self))

        return storyboard.instantiateViewController(withIdentifier: "USIGNormalizador") as! USIGNormalizadorController
    }

    public class func search(query: String, excluding: String? = USIGNormalizadorExclusions.AMBA.rawValue, maxResults: Int = 10, includePlaces: Bool = true,
                             completion: @escaping ([USIGNormalizadorAddress]?, USIGNormalizadorError?) -> Void) {
        let normalizationAPIProvider = RxMoyaProvider<USIGNormalizadorAPI>()
        let normalizationConfig = NormalizadorProviderConfig(excluyendo: excluding, geocodificar: true, max: maxResults, minCharacters: 0)
        let normalizationAddressProvider = NormalizadorProvider(with: normalizationConfig, api: normalizationAPIProvider)
        let searchStream = Observable.just(query)
        let normalizationStream = normalizationAddressProvider.getStream(from: searchStream)
        var sources: [Observable<[USIGNormalizadorResponse]>] = [normalizationStream]
        
        if includePlaces {
            let epokConfig = EpokProviderConfig(
                categoria: nil,
                clase: nil,
                boundingBox: nil,
                start: nil,
                limit: maxResults,
                total: false,
                minCharacters: 0,
                normalization: normalizationConfig
            )
            
            let epokAddressProvider = EpokProvider(with: epokConfig, apiProvider: RxMoyaProvider<USIGEpokAPI>(), normalizationAPIProvider: normalizationAPIProvider)
            let epokStream = epokAddressProvider.getStream(from: searchStream)
            
            sources.append(epokStream)
        }
        
        AddressManager()
            .getStreams(from: sources)
            .observeOn(ConcurrentMainScheduler.instance)
            .subscribe(onNext: { results in
                let filteredResults = results.filter({ response in response.error == nil && response.addresses != nil && response.addresses!.count > 0 })

                if filteredResults.count == 0 {
                    for result in results {
                        if let error = result.error {
                            switch error {
                            case .streetNotFound(let message):
                                completion(nil, USIGNormalizadorError.streetNotFound(message))
                                
                                return
                            case .service(let message):
                                completion(nil, USIGNormalizadorError.service(message))
                                
                                return
                            case .other(let message):
                                completion(nil, USIGNormalizadorError.other(message))
                                
                                return
                            default: break
                            }
                        }
                    }
                }
                
                completion(Array(filteredResults.flatMap({ response in response.addresses! }).prefix(maxResults)), nil)
            })
            .addDisposableTo(disposeBag)
    }

    public class func location(latitude: Double, longitude: Double, completion: @escaping (USIGNormalizadorAddress?, USIGNormalizadorError?) -> Void) {
        let request = USIGNormalizadorAPI.normalizarCoordenadas(latitud: latitude, longitud: longitude)

        api.request(request) { response in
            if let error = response.error, let errorMessage = error.errorDescription {
                completion(nil, USIGNormalizadorError.other(errorMessage))

                return
            }

            guard let json = (try? response.value?.mapJSON(failsOnEmptyData: false)) as? [String: Any],
                json["direccion"] is String,
                json["nombre_calle"] is String,
                json["tipo"] is String else {
                    completion(nil, USIGNormalizadorError.notInRange("Location (\(latitude), \(longitude)) not in range"))

                    return
            }

            completion(USIGNormalizadorAddress(from: json), nil)
        }
    }
}
