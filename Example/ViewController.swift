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
    fileprivate let locationManager = CLLocationManager()
    fileprivate var showPin = true
    fileprivate var forceNormalization = true
    
    // MARK: - Outlets
    
    @IBOutlet weak var searchLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var geoLabel: UILabel!
    @IBOutlet weak var geoButton: UIButton!
    @IBOutlet weak var pinSwitch: UISwitch!
    @IBOutlet weak var mandatorySwitch: UISwitch!
    
    // MARK: - Actions
    
    @IBAction func pinSwitchValueChanged(_ sender: Any) {
        showPin = pinSwitch.isOn
    }
    
    @IBAction func mandatorySwitchValueChanged(_ sender: Any) {
        forceNormalization = mandatorySwitch.isOn
    }
    
    @IBAction func searchButtonTapped(sender: UIButton) {
        let search = USIGNormalizador.search()
        let navigationController = UINavigationController(rootViewController: search)
        
        search.delegate = self
        
        present(navigationController, animated: true, completion: nil)
    }
    
    @IBAction func geoButtonTapped(sender: UIButton) {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestWhenInUseAuthorization()
        requestLocation()
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchLabel.sizeToFit()
        geoLabel.sizeToFit()
    }
    
    // MARK: - Location
    
    fileprivate func requestLocation() {
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse, let currentLocation = locationManager.location else { return }
        
        USIGNormalizador.location(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude) { result, error in
            DispatchQueue.main.async { [unowned self] in
                self.geoLabel.text = result?.address ?? error?.message
            }
        }
    }
}

extension ViewController: USIGNormalizadorControllerDelegate {
    func shouldShowPin(_ search: USIGNormalizadorController) -> Bool { return showPin }
    func shouldForceNormalization(_ search: USIGNormalizadorController) -> Bool { return forceNormalization }
    
    func didSelectValue(_ search: USIGNormalizadorController, value: USIGNormalizadorAddress) {
        DispatchQueue.main.async { [unowned self] in
            self.searchLabel.text = value.address
        }
    }
    
    func didSelectPin(_ search: USIGNormalizadorController) {
        DispatchQueue.main.async { [unowned self] in
            self.searchLabel.text = "PIN"
        }
    }
    
    func didSelectUnnormalizedAddress(_ search: USIGNormalizadorController, value: String) {
        DispatchQueue.main.async { [unowned self] in
            self.searchLabel.text = value
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        requestLocation()
    }
}
