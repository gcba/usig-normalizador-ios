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
    
    let timeout: TimeInterval = 5.0
    
    func testNormalizadorSearch() {
        let expect = expectation(description: "Se busca una calle y se obtiene una lista de resultados")
        
        USIGNormalizador.search(query: "Call") { result, error in
            XCTAssert(error == nil)
            XCTAssert(result != nil)
            XCTAssert(result!.count == 10)
            XCTAssert(result![0].address == "CALLAO AV., CABA, CABA")
            XCTAssert(result![0].street == "CALLAO AV.")
            XCTAssert(result![0].type == "calle")
            XCTAssert(result![0].number == nil)
            XCTAssert(result![0].latitude == nil)
            XCTAssert(result![0].longitude == nil)
            XCTAssert(result![0].districtCode != nil)
            XCTAssert(result![0].districtCode == "caba")
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(self.timeout)) al intentar buscar una calle: \(error.localizedDescription)")
            }
        }
    }
    
    func testNormalizadorSearchWithMax() {
        let max = 5
        let expect = expectation(description: "Se busca una calle y se obtiene una lista de no más de \(max) resultados")
        
        USIGNormalizador.search(query: "Call", maxResults: max) { result, error in
            XCTAssert(error == nil)
            XCTAssert(result != nil)
            XCTAssert(result!.count == 5)
            XCTAssert(result![0].address == "CALLAO AV., CABA, CABA")
            XCTAssert(result![0].street == "CALLAO AV.")
            XCTAssert(result![0].type == "calle")
            XCTAssert(result![0].number == nil)
            XCTAssert(result![0].latitude == nil)
            XCTAssert(result![0].longitude == nil)
            XCTAssert(result![0].districtCode != nil)
            XCTAssert(result![0].districtCode == "caba")
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(self.timeout)) al intentar buscar una calle: \(error.localizedDescription)")
            }
        }
    }
    
    func testNormalizadorSearchWithNumber() {
        let expect = expectation(description: "Se busca una calle y altura específicas y se obtiene un resultado")
        
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
                XCTFail("Falló waitForExpectations(timeout: \(self.timeout)) al intentar buscar una calle: \(error.localizedDescription)")
            }
        }
    }
    
    func testNormalizadorLocation() {
        let expect = expectation(description: "Se obtiene la localización en base a un par de coordenadas")
        
        USIGNormalizador.location(latitude: -34.627847, longitude: -58.365986) { result, error in
            XCTAssert(error == nil)
            XCTAssert(result != nil)
            XCTAssert(result!.address == "PI Y MARGALL 750, CABA")
            XCTAssert(result!.street == "PI Y MARGALL")
            XCTAssert((result!.type == "calle_altura") || (result!.type == "calle_y_calle"))
            XCTAssert(result!.number != nil)
            XCTAssert(result!.number == 750)
            XCTAssert(result!.corner == nil)
            XCTAssert(result!.latitude != nil)
            XCTAssert(result!.latitude == -34.627818571496498)
            XCTAssert(result!.longitude != nil)
            XCTAssert(result!.longitude == -58.3659754141202)
            XCTAssert(result!.districtCode != nil)
            XCTAssert(result!.districtCode == "caba")
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(self.timeout)) al intentar obtener la localización: \(error.localizedDescription)")
            }
        }
    }
    
    func testEpokApiSearch() {
        let request = USIGEpokAPI.buscar(texto: "aeroparque", categoria: nil, clase: nil, boundingBox: nil, start: nil, limit: nil, total: nil)
        let api = MoyaProvider<USIGEpokAPI>()
        let expect = expectation(description: "Se obtienen los detalles de un lugar")
        
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
                XCTFail("Error al parsear la respuesta de la API de lugares")
                    
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
                XCTFail("Falló waitForExpectations(timeout: \(self.timeout)) al intentar buscar un lugar: \(error.localizedDescription)")
            }
        }
    }
    
    func testEpokApiSearchWithLimit() {
        let limit = 2
        let request = USIGEpokAPI.buscar(texto: "aeroparque", categoria: nil, clase: nil, boundingBox: nil, start: nil, limit: limit, total: nil)
        let api = MoyaProvider<USIGEpokAPI>()
        let expect = expectation(description: "Se buscan los detalles de un lugar y se obtiene una lista de \(limit) resultados")
        
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
                    XCTFail("Error al parsear la respuesta de la API de lugares")
                    
                    return
            }
            
            XCTAssert(total == limit)
            XCTAssert(clases.count == limit)
            XCTAssert(instancias.count == limit)
            XCTAssert(limit == limit)
            
            expect.fulfill()
        })
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(self.timeout)) al intentar buscar un lugar: \(error.localizedDescription)")
            }
        }
    }
    
    func testEpokApiSearchWithLimitAndTotal() {
        let limit = 2
        let request = USIGEpokAPI.buscar(texto: "aeroparque", categoria: nil, clase: nil, boundingBox: nil, start: nil, limit: limit, total: true)
        let api = MoyaProvider<USIGEpokAPI>()
        let expect = expectation(description: "Se buscan los detalles de un lugar y se obtiene una lista de \(limit) resultados y el total encontrado")
        
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
                    XCTFail("Error al parsear la respuesta de la API de lugares")
                    
                    return
            }
            
            XCTAssert(total > limit)
            XCTAssert(clases.count > limit)
            XCTAssert(instancias.count == limit)
            XCTAssert(limit == limit)
            
            expect.fulfill()
        })
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(self.timeout)) al intentar buscar un lugar: \(error.localizedDescription)")
            }
        }
    }
    
    func testEpokApiGetObjectContent() {
        let request = USIGEpokAPI.getObjectContent(id: "terminales|9")
        let api = MoyaProvider<USIGEpokAPI>()
        let expect = expectation(description: "Se obtienen los detalles de un lugar")
        
        api.request(request, completion: { response in
            XCTAssert(response.error == nil)
            XCTAssert(response.value != nil)
            
            guard let json = try? response.value?.mapJSON(failsOnEmptyData: true) as? [String: Any],
                let direccionNormalizada = json?["direccionNormalizada"] as? String,
                let contenido = json?["contenido"] as? Array<[String: String]>,
                let fuente = json?["fuente"] as? String,
                let claseId = json?["claseId"] as? String,
                let clase = json?["clase"] as? String,
                let fechaAlta = json?["fechaAlta"] as? String,
                let fechaActualizacion = json?["fechaActualizacion"] as? String,
                let idForaneo = json?["idForaneo"] as? String,
                let fechaUltimaModificacion = json?["fechaUltimaModificacion"] as? String,
                let ubicacion = json?["ubicacion"] as? [String: String],
                let id = json?["id"] as? String else {
                    XCTFail("Error al parsear la respuesta de la API de lugares")
                    
                    return
            }
            
            XCTAssert(direccionNormalizada == "ANTARTIDA ARGENTINA AV. 1250")
            XCTAssert(contenido.count > 0)
            XCTAssert(!fuente.isEmpty)
            XCTAssert(claseId == "terminales")
            XCTAssert(clase == "Terminales")
            XCTAssert(!fechaAlta.isEmpty)
            XCTAssert(!fechaActualizacion.isEmpty)
            XCTAssert(!idForaneo.isEmpty)
            XCTAssert(!fechaUltimaModificacion.isEmpty)
            XCTAssert(!ubicacion.isEmpty)
            XCTAssert(id == "terminales|9")
            
            expect.fulfill()
        })
        
        waitForExpectations(timeout: timeout) { error in
            if let error = error {
                XCTFail("Falló waitForExpectations(timeout: \(self.timeout)) al intentar buscar un lugar: \(error.localizedDescription)")
            }
        }
    }
}
