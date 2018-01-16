//
//  USIGNormalizadorConfig.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/9/17.
//  Copyright © 2017 GCBA. All rights reserved.
//
//  Icons by SimpleIcon https://creativecommons.org/licenses/by/3.0/
//

import Foundation

class USIGNormalizadorConfig {
    static let endpointNormalizador: String = "https://servicios.usig.buenosaires.gob.ar"
    static let endpointEpok: String = "https://epok.buenosaires.gob.ar"
    static let exclusionsDefault: String = USIGNormalizadorExclusions.AMBA.rawValue
    static let maxResultsDefault: Int = 10
    static let pinColorDefault: UIColor = UIColor.lightGray
    static let pinImageDefault: UIImage! = UIImage(named: "pinSolid", in: Bundle(for: USIGNormalizador.self), compatibleWith: nil)
    static let pinTextDefault: String = "Fijar la ubicación en el mapa"
    static let addressColorDefault: UIColor = UIColor.lightGray
    static let addressImageDefault: UIImage! = UIImage(named: "addressSolid", in: Bundle(for: USIGNormalizador.self), compatibleWith: nil)
    static let placeColorDefault: UIColor = UIColor.lightGray
    static let placeImageDefault: UIImage! = UIImage(named: "placeSolid", in: Bundle(for: USIGNormalizador.self), compatibleWith: nil)
    static let shouldShowPinDefault: Bool = false
    static let shouldForceNormalizationDefault: Bool = true
    static let shouldIncludePlacesDefault: Bool = true
    static let shouldShowDetailsDefault: Bool = false
}
