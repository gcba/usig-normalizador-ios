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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let normalizador = USIGNormalizador.new()
        let navigationController = UINavigationController(rootViewController: viewController)
        
        normalizador.maxResults = 10
        
        present(navigationController, animated: true, completion: nil)
    }
}

