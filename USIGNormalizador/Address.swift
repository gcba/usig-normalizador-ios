//
//  Address.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation
import Moya

public struct Address {
    var address: String
    let street: String
    let number: Int?
    let type: String
    let corner: String?
}

extension Address: Equatable {
    public static func ==(lhs: Address, rhs: Address) -> Bool {
        return lhs.address == rhs.address && lhs.type == rhs.type
    }
}

