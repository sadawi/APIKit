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

class BaseModel:Model {
    let id          = Field<String>()
    override var identifierField:FieldType {
        return self.id
    }
}

class Department:BaseModel {
    let name        = Field<String>()
    let departments = *ModelField<Department>()
}

class Company:BaseModel {
    let name        = Field<String>()
    let departments = *ModelField<Department>()
}

class Person:BaseModel {
    let name    = Field<String>()
    let age     = Field<Int>()
    let company = ModelField<Company>()
    // TODO: pets (avoid cycles!)
    
    required init() { }
    
    init(name:String?, age:Int?) {
        self.name.value = name
        self.age.value = age
    }
}

class Pet:BaseModel {
    let name    = Field<String>()
    let species = Field<String>()
    let owner   = ModelField<Person>()
    
    required init() { }

    init(name:String?, species:String?) {
        self.name.value = name
        self.species.value = species
    }
}

class APIKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let store = MemoryDataStore()

        ModelManager.sharedInstance.dataStore = store
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFaults() {
        let didSave = expectationWithDescription("save")
        
        let phil = Person.fromDictionaryValue(["name": "Phil", "age": 44, "company": "testID"])!
        
        ModelManager.sharedInstance.dataStore.save(phil).then { model -> Void in
            // Fails because 555 is not a valid owner id (should be string)
            let grazi0 = Pet.fromDictionaryValue(["name": "Grazi", "owner": 555])
            XCTAssertNil(grazi0?.owner.value?.id.value)

            let grazi1 = Pet.fromDictionaryValue(["name": "Grazi", "owner": phil.id.value!])
            XCTAssertEqual(grazi1?.owner.value?.id.value, phil.id.value)
            
            let shells = grazi1!.shellFields()
            XCTAssertEqual(1, shells.count)
            let shell = shells.first as! ModelField<Person>
            XCTAssertEqual(shell.value?.identifier, phil.identifier)
            
            let grazi2 = Pet()
            grazi2.owner.value = phil
            let shells2 = grazi2.shellFields(recursive: true)
            XCTAssertEqual(1, shells2.count)
            let shell2 = shells2.first as? ModelField<Company>
            XCTAssertNotNil(shell2)
            
            didSave.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler:nil)
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
    

    
}
