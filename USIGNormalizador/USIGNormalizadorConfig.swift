//
//  USIGNormalizadorConfig.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/9/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation

class USIGNormalizadorConfig {
    static let endpoint: String = "https://servicios.usig.buenosaires.gob.ar"
    static let exclusionsDefault: String = USIGNormalizadorExclusions.AMBA.rawValue
    static let maxResultsDefault: Int = 10
    static let pinColorDefault: UIColor = UIColor.darkGray
    static let pinImageDefault: UIImage! = UIImage(named: "PinSolid", in: Bundle(for: USIGNormalizador.self), compatibleWith: nil)
    static let pinTextDefault: String = "Fijar la ubicación en el mapa"
    static let shouldShowPinDefault: Bool = false
    static let shouldForceNormalizationDefault: Bool = true
}
