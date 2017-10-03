//
//  USIGNormalizadorTests.swift
//  USIGNormalizadorTests
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import XCTest
@testable import USIGNormalizador

class USIGNormalizadorTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testLocation() {
        let expect = expectation(description: "Se obtiene la localización")
        let timeout = 5.0
        
        USIGNormalizador.location(latitude: -34.627847, longitude: -58.365986) { result in
            XCTAssert(result.address == "NECOCHEA Y PI Y MARGALL, CABA")
            XCTAssert(result.street == "NECOCHEA")
            XCTAssert(result.type == "calle_y_calle")
            XCTAssert(result.corner != nil)
            XCTAssert(result.corner! == "PI Y MARGALL")
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(timeout)) al intentar obtener la localización: \(error.localizedDescription)")
            }
        }
    }
}
