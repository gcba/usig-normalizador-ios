//
//  ViewController.swift
//  Example
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import UIKit
import USIGNormalizador

class ViewController: UIViewController {
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    
    @IBAction func searchButtonTapped(sender: UIButton) {
        let search = USIGNormalizador.search()
        let navigationController = UINavigationController(rootViewController: search)
        
        search.delegate = self
        search.maxResults = 10
        
        present(navigationController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLabel.sizeToFit()
    }
}

extension ViewController: USIGNormalizadorControllerDelegate {
    func didChange(_ search: USIGNormalizadorController, value: USIGNormalizadorAddress) {
        DispatchQueue.main.async { [unowned self] in
            self.addressLabel.text = value.address
        }
    }
}
