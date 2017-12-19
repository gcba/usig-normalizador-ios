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
    
    func testSearch() {
        let expect = expectation(description: "Se busca una calle y se obtiene una lista de resultados")
        let timeout = 5.0
        
        USIGNormalizador.search(query: "Call") { result, error in
            XCTAssert(error == nil)
            XCTAssert(result != nil)
            XCTAssert(result!.count == 10)
            XCTAssert(result![0].address == "CALLAO AV., CABA, CABA")
            XCTAssert(result![0].street == "CALLAO AV.")
            XCTAssert(result![0].type == "calle")
            XCTAssert(result![0].districtCode != nil)
            XCTAssert(result![0].districtCode == "caba")
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(timeout)) al intentar buscar una calle: \(error.localizedDescription)")
            }
        }
    }
    
    func testSearchWithMax() {
        let max = 5
        let expect = expectation(description: "Se busca una calle y se obtiene una lista de no más de \(max) resultados")
        let timeout = 5.0
        
        USIGNormalizador.search(query: "Call", maxResults: max) { result, error in
            XCTAssert(error == nil)
            XCTAssert(result != nil)
            XCTAssert(result!.count == 5)
            XCTAssert(result![0].address == "CALLAO AV., CABA, CABA")
            XCTAssert(result![0].street == "CALLAO AV.")
            XCTAssert(result![0].type == "calle")
            XCTAssert(result![0].districtCode != nil)
            XCTAssert(result![0].districtCode == "caba")
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(timeout)) al intentar buscar una calle: \(error.localizedDescription)")
            }
        }
    }
    
    func testSearchWithNumber() {
        let expect = expectation(description: "Se busca una calle y altura específicas y se obtiene un resultado")
        let timeout = 5.0
        
        USIGNormalizador.search(query: "CALLAO AV. 123") { result, error in
            XCTAssert(error == nil)
            XCTAssert(result != nil)
            XCTAssert(result!.count == 1)
            XCTAssert(result![0].address == "CALLAO AV. 123, CABA")
            XCTAssert(result![0].street == "CALLAO AV.")
            XCTAssert(result![0].type == "calle_altura")
            XCTAssert(result![0].number != nil)
            XCTAssert(result![0].number == 123)
            XCTAssert(result![0].latitude != nil)
            XCTAssert(result![0].latitude == -34.607595)
            XCTAssert(result![0].longitude != nil)
            XCTAssert(result![0].longitude == -58.391966)
            XCTAssert(result![0].districtCode != nil)
            XCTAssert(result![0].districtCode == "caba")
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(timeout)) al intentar buscar una calle: \(error.localizedDescription)")
            }
        }
    }
    
    func testLocation() {
        let expect = expectation(description: "Se obtiene la localización en base a un par de coordenadas")
        let timeout = 5.0
        
        USIGNormalizador.location(latitude: -34.627847, longitude: -58.365986) { result, error in
            XCTAssert(error == nil)
            XCTAssert(result != nil)
            XCTAssert(result!.address == "NECOCHEA Y PI Y MARGALL, CABA")
            XCTAssert(result!.street == "NECOCHEA")
            XCTAssert(result!.type == "calle_y_calle")
            XCTAssert(result!.corner != nil)
            XCTAssert(result!.corner! == "PI Y MARGALL")
            XCTAssert(result!.latitude != nil)
            XCTAssert(result!.longitude != nil)
            XCTAssert(result!.districtCode != nil)
            XCTAssert(result!.districtCode == "caba")
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(timeout)) al intentar obtener la localización: \(error.localizedDescription)")
            }
        }
    }
}
