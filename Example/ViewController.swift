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
    fileprivate var isMandatory = true
    
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
        isMandatory = mandatorySwitch.isOn
    }
    
    @IBAction func searchButtonTapped(sender: UIButton) {
        let search = USIGNormalizador.search()
        let navigationController = UINavigationController(rootViewController: search)
        
        search.delegate = self
        search.maxResults = 10
        search.showPin = showPin
        search.pinImageTint = UIColor(white: 0.9, alpha: 1)
        search.pinButtonTint = UIColor(red: 0.00, green: 0.46, blue: 1.00, alpha: 1.0)
        
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
    func didChange(_ search: USIGNormalizadorController, value: USIGNormalizadorAddress) {
        DispatchQueue.main.async { [unowned self] in
            self.searchLabel.text = value.address
        }
    }
    
    func didSelectPin(_ search: USIGNormalizadorController) {
        DispatchQueue.main.async { [unowned self] in
            self.searchLabel.text = "PIN"
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        requestLocation()
    }
}
