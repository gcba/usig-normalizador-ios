//
//  USIGNormalizadorError.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/3/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation

public enum USIGNormalizadorError: Error {
    case notInRange(String, Int, HTTPURLResponse)
    case jsonMapping(String, Int, HTTPURLResponse)
    case streetNotFound(String, Int, HTTPURLResponse)
    case service(String, Int, HTTPURLResponse)
    case other(String, Int, HTTPURLResponse)
}

public extension USIGNormalizadorError {
    public var message: String {
        switch self {
        case .notInRange(let description, _, _): return description
        case .streetNotFound(let description, _, _): return description
        case .service(let description, _, _): return description
        case .other(let description, _, _): return description
        }
    }
    
    public var statusCode: String {
        switch self {
        case .notInRange(_, let status, _): return status
        case .streetNotFound(_, let status, _): return status
        case .service(_, let status, _): return status
        case .other(_, let status, _): return status
        }
    }
    
    public var response: String {
        switch self {
        case .notInRange(_, _, let res): return res
        case .streetNotFound(_, _, let res): return res
        case .service(_, _, let res): return res
        case .other(_, _, let res): return res
        }
    }
}
