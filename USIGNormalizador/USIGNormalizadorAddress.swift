//
//  USIGNormalizadorAddress.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation

public struct USIGNormalizadorAddress {
    public let address: String
    public let street: String
    public let number: Int?
    public let type: String
    public let corner: String?
    public let latitude: Double?
    public let longitude: Double?
    public let districtCode: String?
}

extension USIGNormalizadorAddress: Equatable {
    public static func ==(lhs: USIGNormalizadorAddress, rhs: USIGNormalizadorAddress) -> Bool {
        return lhs.address == rhs.address && lhs.type == rhs.type
    }
}

extension USIGNormalizadorAddress: CustomStringConvertible {
    public var description: String {
        return "Address: \(address), " +
            "Street: \(street), " +
            "Number: \(String(describing: number)), " +
            "Type: \(type), " +
            "Corner: \(String(describing: corner)), " +
            "Latitude: \(String(describing: latitude)), " +
            "Longitude: \(String(describing: longitude))"
    }
}
