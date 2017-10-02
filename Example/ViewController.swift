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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let search = USIGNormalizador.search()
        let navigationController = UINavigationController(rootViewController: search)
        
        search.delegate = self
        search.maxResults = 10
        
        present(navigationController, animated: true, completion: nil)
    }
}

extension ViewController: USIGNormalizadorControllerDelegate {
    func didChange(_ search: USIGNormalizadorController, value: USIGNormalizadorAddress) {
        debugPrint(value.address)
    }
}
