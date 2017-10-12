//
//  USIGNormalizadorError.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/3/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation

public enum USIGNormalizadorError: Error {
    case notInRange(String, Int?, URLResponse?)
    case streetNotFound(String, Int?, URLResponse?)
    case service(String, Int?, URLResponse?)
    case other(String, Int?, URLResponse?)
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
    
    public var statusCode: Int? {
        switch self {
        case .notInRange(_, let status, _): return status
        case .streetNotFound(_, let status, _): return status
        case .service(_, let status, _): return status
        case .other(_, let status, _): return status
        }
    }
    
    public var response: URLResponse? {
        switch self {
        case .notInRange(_, _, let res): return res
        case .streetNotFound(_, _, let res): return res
        case .service(_, _, let res): return res
        case .other(_, _, let res): return res
        }
    }
}
