//
//  USIGNormalizadorAddressManager.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 1/8/18.
//  Copyright © 2018 GCBA. All rights reserved.
//

import Foundation
import Foundation
import RxSwift
import Moya

internal protocol USIGNormalizadorAddressManager {
    func getStreams(from sources: [Observable<[USIGNormalizadorResponse]>], maxResults: Int) -> Observable<[USIGNormalizadorResponse]>
}

internal class AddressManager: USIGNormalizadorAddressManager {
    func getStreams(from sources: [Observable<[USIGNormalizadorResponse]>], maxResults: Int) -> Observable<[USIGNormalizadorResponse]> {
        let streams = sources.flatMap { stream in stream.observeOn(ConcurrentMainScheduler.instance) }
        
        let limitResults = self.limitResults
         
        return Observable.zip(streams).flatMap { matrix -> Observable<[USIGNormalizadorResponse]> in
            let filteredMatrix = matrix.map { item in item.filter({ response in response.error == nil && response.addresses != nil && !response.addresses!.isEmpty }) }
            let allResults = filteredMatrix.reduce([] as [USIGNormalizadorResponse], +)
            
            guard !allResults.isEmpty else { return Observable.of(matrix.reduce([] as [USIGNormalizadorResponse], +)) }
            
            let allAddresses = allResults.reduce([] as [USIGNormalizadorAddress], { (result, next) -> [USIGNormalizadorAddress] in return result + next.addresses!})
            
            guard allAddresses.count > maxResults else { return Observable.of(allResults) }
            
            let proportion = Int(floor(Double(allAddresses.count) / Double(sources.count)))
            let limitedResults = limitResults(allResults, proportion)
            
            return Observable.of(limitedResults)
        }
    }
    
    private func limitResults(_ results: [USIGNormalizadorResponse], by proportion: Int) -> [USIGNormalizadorResponse] {
        let counts = results.map { item in item.addresses!.count }
        var savings = results.map({ item in (proportion - item.addresses!.count) > 0 ? (proportion - item.addresses!.count) : 0 }).reduce(0, +)
        var i = 0
        
        let limitedResults: [USIGNormalizadorResponse] = results.map { item in
            var mutableItem = item
            
            if (counts[i] > proportion) && savings > 0 {
                let limitedAddresses = Array(item.addresses!.prefix(proportion + savings))
                
                mutableItem.addresses = limitedAddresses
                savings -= limitedAddresses.count - proportion
                i += 1
                
                return mutableItem
            }
            
            mutableItem.addresses = Array(item.addresses!.prefix(proportion))
            
            return mutableItem
        }
        
        return limitedResults
    }
}
