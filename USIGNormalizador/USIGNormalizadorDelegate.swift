//
//  USIGNormalizadorDelegate.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/2/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation

public protocol USIGNormalizadorDelegate {
    func exclusions(_ search: USIGNormalizadorController) -> String
    func valueChanged(_ search: USIGNormalizadorController)
}
