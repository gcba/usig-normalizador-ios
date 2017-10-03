//
//  USIGNormalizadorError.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/3/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation

protocol USIGNormalizadorErrorType: Error {
    var message: String { get }
}

public struct USIGNormalizadorError: USIGNormalizadorErrorType {
    private var _message: String
    public var message: String { return _message }
    
    init(_ message: String) {
        _message = message
    }
}
