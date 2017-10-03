//
//  USIGNormalizadorDelegate.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/2/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation

public protocol USIGNormalizadorControllerDelegate {
    func exclude(_ search: USIGNormalizadorController) -> String
    func didChange(_ search: USIGNormalizadorController, value: USIGNormalizadorAddress)
    func didSelectPin(_ search: USIGNormalizadorController)
}

extension USIGNormalizadorControllerDelegate {
    public func exclude(_ search: USIGNormalizadorController) -> String { return USIGNormalizadorExclusions.GBA.rawValue }
    public func didChange(_ search: USIGNormalizadorController, value: USIGNormalizadorAddress) {}
    public func didSelectPin(_ search: USIGNormalizadorController) {}
}
