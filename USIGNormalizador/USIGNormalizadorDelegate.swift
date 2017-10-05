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
    func maxResults(_ search: USIGNormalizadorController) -> Int
    func pinColor(_ search: USIGNormalizadorController) -> UIColor
    func pinImage(_ search: USIGNormalizadorController) -> UIImage!
    func pinText(_ search: USIGNormalizadorController) -> String
    func shouldShowPin(_ search: USIGNormalizadorController) -> Bool
    func shouldForceNormalization(_ search: USIGNormalizadorController) -> Bool
    func didSelectValue(_ search: USIGNormalizadorController, value: USIGNormalizadorAddress)
    func didSelectPin(_ search: USIGNormalizadorController)
    func didSelectUnnormalizedAddress(_ search: USIGNormalizadorController, value: String)
}

extension USIGNormalizadorControllerDelegate {
    public func exclude(_ search: USIGNormalizadorController) -> String { return USIGNormalizadorExclusions.GBA.rawValue }
    public func maxResults(_ search: USIGNormalizadorController) -> Int { return 10 }
    public func pinColor(_ search: USIGNormalizadorController) -> UIColor { return UIColor.darkGray }
    public func pinImage(_ search: USIGNormalizadorController) -> UIImage! { return UIImage(named: "PinSolid", in: Bundle(for: USIGNormalizador.self), compatibleWith: nil) }
    public func pinText(_ search: USIGNormalizadorController) -> String { return "Fijar la ubicación en el mapa" }
    public func shouldShowPin(_ search: USIGNormalizadorController) -> Bool { return false }
    public func shouldForceNormalization(_ search: USIGNormalizadorController) -> Bool { return false }
    public func didSelectPin(_ search: USIGNormalizadorController) {}
    public func didSelectUnnormalizedAddress(_ search: USIGNormalizadorController, value: String) {}
}
