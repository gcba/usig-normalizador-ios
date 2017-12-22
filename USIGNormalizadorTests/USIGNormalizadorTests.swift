//
//  USIGNormalizadorTests.swift
//  USIGNormalizadorTests
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import XCTest
import Moya
@testable import USIGNormalizador

class USIGNormalizadorTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNormalizadorSearch() {
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
    
    func testNormalizadorSearchWithMax() {
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
    
    func testNormalizadorSearchWithNumber() {
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
    
    func testNormalizadorLocation() {
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
    
    func testEpokApiSearch() {
        let request = USIGEpokAPI.buscar(texto: "aeroparque", categoria: nil, clase: nil, boundingBox: nil, start: nil, limit: nil, total: nil)
        let api = MoyaProvider<USIGEpokAPI>()
        let expect = expectation(description: "Se obtienen los detalles de un lugar")
        let timeout = 5.0
        let parseError = "Error al parsear la respuesta de la API de lugares"
        
        api.request(request, completion: { response in
            XCTAssert(response.error == nil)
            XCTAssert(response.value != nil)
            
            guard let json = try? response.value?.mapJSON(failsOnEmptyData: true) as? [String: Any],
                let totalString = json?["totalFull"] as? String,
                let clases = json?["clasesEncontradas"] as? Array<[String: String]>,
                let instancias = json?["instancias"] as? Array<[String: String]>,
                let limitString = json?["total"] as? String,
                let total = Int(totalString),
                let limit = Int(limitString) else {
                XCTFail(parseError)
                    
                return
            }
            
            XCTAssert(total > 0)
            XCTAssert(clases.count > 0)
            XCTAssert(instancias.count > 0)
            XCTAssert(limit > 0)
            
            expect.fulfill()
        })
        
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(timeout)) al intentar buscar un lugar: \(error.localizedDescription)")
            }
        }
    }
}
