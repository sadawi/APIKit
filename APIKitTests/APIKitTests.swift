//
//  APIKitTests.swift
//  APIKitTests
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import XCTest
@testable import APIKit

class Person:Model {
    var name:String?
    var age:Int?
    
    init(name:String?, age:Int?) {
        self.name = name
        self.age = age
    }
}

class Pet:Model {
    var name:String?
    var species:String?
    
    init(name:String?, species:String?) {
        self.name = name
        self.species = species
    }
}

class APIKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let store = MemoryDataStore()
        store << Person(name: "Bob", age:44)
        store << Person(name: "Alice", age: 55)

        ModelManager.sharedInstance.dataStore = store
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testResources() {
        let expectation = expectationWithDescription("Waiting")
        ModelManager.sharedInstance.dataStore.list(Person).then { results -> Void in
            print(results)
            XCTAssertEqual(2, results.count)
            expectation.fulfill()
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
