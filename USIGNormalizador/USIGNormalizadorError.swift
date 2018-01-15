//
//  USIGNormalizadorError.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/3/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation

public enum USIGNormalizadorError: Error {
    case streetNotFound(String)
    case notInRange(String)
    case service(String)
    case other(String)
}

public extension USIGNormalizadorError {
    public var message: String {
        switch self {
        case .streetNotFound(let description): return description
        case .notInRange(let description): return description
        case .service(let description): return description
        case .other(let description): return description
        }
    }
}
