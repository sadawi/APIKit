//
//  APIKitTests.swift
//  APIKitTests
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import XCTest
import PromiseKit
import MagneticFields

@testable import APIKit

class Person:Model {
    var name:String?
    var age:Int?
    
    required init() { }
    
    init(name:String?, age:Int?) {
        self.name = name
        self.age = age
    }
}

class Pet:Model {
    var name:String?
    var species:String?
    
    required init() { }
    
    init(name:String?, species:String?) {
        self.name = name
        self.species = species
    }
}

class APIKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let store = MemoryDataStore()
        store << Person(name: "Bob", age: 44)
        store << Person(name: "Alice", age: 55)

        ModelManager.sharedInstance.dataStore = store
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testResources() {
//        let expectation = expectationWithDescription("Waiting")
//        ModelManager.sharedInstance.dataStore.list(Person).then { results -> () in
//            XCTAssertEqual(2, results.count)
//            expectation.fulfill()
//        }
//        self.waitForExpectationsWithTimeout(1, handler:nil)
    }
    
    func testResource() {
        let didSave = expectationWithDescription("save")
        let didLookup = expectationWithDescription("lookup")
        
        let a = Person(name: "Kevin", age: 33)
        XCTAssertNil(a.identifier)
        
        ModelManager.sharedInstance.dataStore.save(a).then { model -> Promise<Person> in
            XCTAssertNotNil(model.identifier)
            didSave.fulfill()
            let id = model.identifier!
            return ModelManager.sharedInstance.dataStore.lookup(a.dynamicType, identifier: id)
            }.then { model -> () in
                XCTAssertNotNil(model)
                XCTAssert(model === a)
                didLookup.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler:nil)
    }

    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

    class Company: FieldModel {
        let name = Field<String>()
        let size = Field<Int>()
        let parentCompany = Field<Company>()
    }
    
    func testFieldModel() {
        let co = Company()
        co.name.value = "The Widget Company"
        co.size.value = 22
        
        let fields = co.fields()
        XCTAssertNotNil(fields["name"])
        
        let co2 = Company()
        co2.name.value = "Parent Company"
        co.parentCompany.value = co2

        let dict = co.dictionaryValue
        print(dict)
        
        XCTAssertEqual(dict["name"] as? String, "The Widget Company")
        XCTAssertEqual(dict["size"] as? Int, 22)
        let parentDict = dict["parentCompany"] as! AttributeDictionary
        XCTAssertNotNil(parentDict)
        XCTAssertEqual(parentDict["name"] as? String, "Parent Company")
    }
    
}
