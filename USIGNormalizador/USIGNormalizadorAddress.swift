//
//  USIGNormalizadorAddress.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation
import Moya

public struct USIGNormalizadorAddress {
    public let address: String
    public let street: String
    public let number: Int?
    public let type: String
    public let corner: String?
    public let latitude: Double?
    public let longitude: Double?
    public let districtCode: String?
    public let districtName: String?
    public let localityName: String?
    public let label: String?
    internal let source: TargetType.Type
    
    init(from json: [String: Any]) {
        let coordinates = json["coordenadas"] as? [String: Any]
        
        self.address = (json["direccion"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.street = (json["nombre_calle"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.number = json["altura"] as? Int
        self.type = (json["tipo"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
        self.corner = (json["nombre_calle_cruce"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.districtCode = (json["cod_partido"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.districtName = (json["nombre_partido"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.localityName = (json["nombre_localidad"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.label = json["label"] as? String
        self.source = json["source"] as? TargetType.Type ?? USIGNormalizadorAPI.self
        
        self.latitude = USIGNormalizadorAddress.parseCoordinate(fromDict: coordinates, key: "y")
        self.longitude = USIGNormalizadorAddress.parseCoordinate(fromDict: coordinates, key: "x")
    }
    
    static private func parseCoordinate(fromDict dict: [String: Any]?, key: String) -> Double? {
        guard let coordinatesDict = dict else { return nil }
        
        if let coordinateString = coordinatesDict[key] as? String {
            return Double(coordinateString)
        }
        
        return coordinatesDict[key] as? Double
    }
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
            "Longitude: \(String(describing: longitude))," +
            "District Code: \(String(describing: districtCode))," +
            "District Name: \(String(describing: districtName))," +
            "Locality Name: \(String(describing: localityName))," +
            "Label: \(String(describing: label))"
    }
}
