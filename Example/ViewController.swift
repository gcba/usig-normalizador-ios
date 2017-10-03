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
    
    @IBOutlet weak var searchLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var geoLabel: UILabel!
    @IBOutlet weak var geoButton: UIButton!
    
    @IBAction func searchButtonTapped(sender: UIButton) {
        let search = USIGNormalizador.search()
        let navigationController = UINavigationController(rootViewController: search)
        
        search.delegate = self
        search.maxResults = 10
        
        present(navigationController, animated: true, completion: nil)
    }
    
    @IBAction func geoButtonTapped(sender: UIButton) {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestWhenInUseAuthorization()
        requestLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchLabel.sizeToFit()
    }
    
    fileprivate func requestLocation() {
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse, let currentLocation = locationManager.location else { return }
        
        let request = USIGNormalizadorAPI.normalizarCoordenadas(latitud: currentLocation.coordinate.latitude, longitud: currentLocation.coordinate.longitude)
        
        USIGNormalizador.api.request(request) { response in
            guard let json = try? response.value?.mapJSON(failsOnEmptyData: false) as? [String: Any], let address = json?["direccion"] as? String else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.geoLabel.text = address
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
}

extension ViewController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        requestLocation()
    }
}
