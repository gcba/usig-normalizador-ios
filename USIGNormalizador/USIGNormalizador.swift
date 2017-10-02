//
//  USIGNormalizador.swift
//  USIGNormalizador
//
//  Created by Rita Zerrizuela on 10/2/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation
import Moya

public class USIGNormalizador {
    public static let api: MoyaProvider<USIGNormalizadorAPI> = MoyaProvider<USIGNormalizadorAPI>()
    
    public class func search() -> USIGNormalizadorController {
        let storyboard = UIStoryboard(name: "USIGNormalizador", bundle: Bundle(for: USIGNormalizador.self))
        
        return storyboard.instantiateViewController(withIdentifier: "USIGNormalizador") as! USIGNormalizadorController
    }
}
