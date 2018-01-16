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
    func pinImage(_ searchController: USIGNormalizadorController) -> UIImage!
    func pinColor(_ searchController: USIGNormalizadorController) -> UIColor
    func pinText(_ searchController: USIGNormalizadorController) -> String
    func addressImage(_ searchController: USIGNormalizadorController) -> UIImage!
    func addressColor(_ searchController: USIGNormalizadorController) -> UIColor
    func placeImage(_ searchController: USIGNormalizadorController) -> UIImage!
    func placeColor(_ searchController: USIGNormalizadorController) -> UIColor
    func shouldShowPin(_ searchController: USIGNormalizadorController) -> Bool
    func shouldForceNormalization(_ searchController: USIGNormalizadorController) -> Bool
    func shouldIncludePlaces(_ searchController: USIGNormalizadorController) -> Bool
    func shouldShowSuffix(_ searchController: USIGNormalizadorController) -> Bool
    func didSelectValue(_ searchController: USIGNormalizadorController, value: USIGNormalizadorAddress)
    func didSelectPin(_ searchController: USIGNormalizadorController)
    func didSelectUnnormalizedAddress(_ searchController: USIGNormalizadorController, value: String)
    func didCancelSelection(_ searchController: USIGNormalizadorController)
}

extension USIGNormalizadorControllerDelegate {
    public func exclude(_ searchController: USIGNormalizadorController) -> String { return USIGNormalizadorConfig.exclusionsDefault }
    public func maxResults(_ searchController: USIGNormalizadorController) -> Int { return USIGNormalizadorConfig.maxResultsDefault }
    public func pinImage(_ searchController: USIGNormalizadorController) -> UIImage! { return USIGNormalizadorConfig.pinImageDefault }
    public func pinColor(_ searchController: USIGNormalizadorController) -> UIColor { return USIGNormalizadorConfig.pinColorDefault }
    public func pinText(_ searchController: USIGNormalizadorController) -> String { return USIGNormalizadorConfig.pinTextDefault }
    public func addressImage(_ searchController: USIGNormalizadorController) -> UIImage! { return USIGNormalizadorConfig.addressImageDefault }
    public func addressColor(_ searchController: USIGNormalizadorController) -> UIColor { return USIGNormalizadorConfig.addressColorDefault }
    public func placeImage(_ searchController: USIGNormalizadorController) -> UIImage! { return USIGNormalizadorConfig.placeImageDefault }
    public func placeColor(_ searchController: USIGNormalizadorController) -> UIColor { return USIGNormalizadorConfig.placeColorDefault }
    public func shouldShowPin(_ searchController: USIGNormalizadorController) -> Bool { return USIGNormalizadorConfig.shouldShowPinDefault }
    public func shouldForceNormalization(_ searchController: USIGNormalizadorController) -> Bool { return USIGNormalizadorConfig.shouldForceNormalizationDefault }
    public func shouldIncludePlaces(_ searchController: USIGNormalizadorController) -> Bool { return USIGNormalizadorConfig.shouldIncludePlacesDefault }
    public func shouldShowSuffix(_ searchController: USIGNormalizadorController) -> Bool { return USIGNormalizadorConfig.shouldShowSuffixDefault }
    public func didSelectPin(_ searchController: USIGNormalizadorController) {}
    public func didSelectUnnormalizedAddress(_ searchController: USIGNormalizadorController, value: String) {}
    public func didCancelSelection(_ searchController: USIGNormalizadorController) {}
}
