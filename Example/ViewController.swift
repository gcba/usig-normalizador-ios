//
//  ViewController.swift
//  Example
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import UIKit
import CoreLocation
import USIGNormalizador

class ViewController: UIViewController {
    fileprivate var currentAddress: USIGNormalizadorAddress?

    fileprivate let locationManager = CLLocationManager()
    fileprivate var showPin = true
    fileprivate var forceNormalization = true
    fileprivate var includePlaces = true
    fileprivate var cabaOnly = true

    // MARK: - Outlets

    @IBOutlet weak var searchLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var geoLabel: UILabel!
    @IBOutlet weak var geoButton: UIButton!
    @IBOutlet weak var pinSwitch: UISwitch!
    @IBOutlet weak var mandatorySwitch: UISwitch!
    @IBOutlet weak var placesSwitch: UISwitch!
    @IBOutlet weak var cabaSwitch: UISwitch!

    // MARK: - Actions

    @IBAction func pinSwitchValueChanged(_ sender: Any) {
        showPin = pinSwitch.isOn
    }

    @IBAction func mandatorySwitchValueChanged(_ sender: Any) {
        forceNormalization = mandatorySwitch.isOn
    }
    
    @IBAction func placesSwitchValueChanged(_ sender: Any) {
        includePlaces = placesSwitch.isOn
    }
    
    @IBAction func cabaSwitchValueChanged(_ sender: Any) {
        cabaOnly = cabaSwitch.isOn
    }

    @IBAction func searchButtonTapped(sender: UIButton) {
        let searchController = USIGNormalizador.searchController()
        let navigationController = UINavigationController(rootViewController: searchController)

        searchController.delegate = self
        searchController.edit = searchLabel.text

        present(navigationController, animated: true, completion: nil)
    }

    @IBAction func geoButtonTapped(sender: UIButton) {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.requestWhenInUseAuthorization()
        requestLocation()
    }

    // MARK: - Overrides
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchLabel.sizeToFit()
        geoLabel.sizeToFit()
    }

    // MARK: - Location

    fileprivate func requestLocation() {
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse, let currentLocation = locationManager.location else { return }

        USIGNormalizador.location(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude) { result, error in
            DispatchQueue.main.async {
                self.geoLabel.text = result?.address ?? error?.message
            }
        }
    }
}

extension ViewController: USIGNormalizadorControllerDelegate {
    func exclude(_ searchController: USIGNormalizadorController) -> String { return cabaOnly ? USIGNormalizadorExclusions.AMBA.rawValue : "" }
    func shouldShowPin(_ searchController: USIGNormalizadorController) -> Bool { return showPin }
    func shouldForceNormalization(_ searchController: USIGNormalizadorController) -> Bool { return forceNormalization }
    func shouldIncludePlaces(_ searchController: USIGNormalizadorController) -> Bool { return includePlaces }

    func didSelectValue(_ searchController: USIGNormalizadorController, value: USIGNormalizadorAddress) {
        currentAddress = value

        DispatchQueue.main.async {
            self.searchLabel.text = value.address
        }
    }

    func didSelectPin(_ searchController: USIGNormalizadorController) {
        DispatchQueue.main.async {
            self.searchLabel.text = "PIN"
        }
    }

    func didSelectUnnormalizedAddress(_ searchController: USIGNormalizadorController, value: String) {
        DispatchQueue.main.async {
            self.searchLabel.text = value
        }
    }
    
    func didCancelSelection(_ searchController: USIGNormalizadorController) {
        DispatchQueue.main.async {
            self.searchLabel.text = "CANCELADO"
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        requestLocation()
    }
}
