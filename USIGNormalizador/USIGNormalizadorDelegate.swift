//
//  USIGNormalizadorDelegate.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/2/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation

public protocol USIGNormalizadorControllerDelegate {
    func exclude(_ searchController: USIGNormalizadorController) -> String
    func maxResults(_ searchController: USIGNormalizadorController) -> Int
    func pinColor(_ searchController: USIGNormalizadorController) -> UIColor
    func pinImage(_ searchController: USIGNormalizadorController) -> UIImage!
    func pinText(_ searchController: USIGNormalizadorController) -> String
    func shouldShowPin(_ searchController: USIGNormalizadorController) -> Bool
    func shouldForceNormalization(_ searchController: USIGNormalizadorController) -> Bool
    func didSelectValue(_ searchController: USIGNormalizadorController, value: USIGNormalizadorAddress)
    func didSelectPin(_ searchController: USIGNormalizadorController)
    func didSelectUnnormalizedAddress(_ searchController: USIGNormalizadorController, value: String)
}

extension USIGNormalizadorControllerDelegate {
    public func exclude(_ searchController: USIGNormalizadorController) -> String { return USIGNormalizadorExclusions.AMBA.rawValue }
    public func maxResults(_ searchController: USIGNormalizadorController) -> Int { return 10 }
    public func pinColor(_ searchController: USIGNormalizadorController) -> UIColor { return UIColor.darkGray }
    public func pinImage(_ searchController: USIGNormalizadorController) -> UIImage! { return UIImage(named: "PinSolid", in: Bundle(for: USIGNormalizador.self), compatibleWith: nil) }
    public func pinText(_ searchController: USIGNormalizadorController) -> String { return "Fijar la ubicación en el mapa" }
    public func shouldShowPin(_ searchController: USIGNormalizadorController) -> Bool { return false }
    public func shouldForceNormalization(_ searchController: USIGNormalizadorController) -> Bool { return true }
    public func didSelectPin(_ searchController: USIGNormalizadorController) {}
    public func didSelectUnnormalizedAddress(_ searchController: USIGNormalizadorController, value: String) {}
}
