//
//  FieldTests.swift
//  APIKit
//
//  Created by Sam Williams on 11/25/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import XCTest

class Entity:Model {
    let name:Field<String> = Field()
}

class View:FieldObserver {
    var value:String?
    
    func fieldValueChanged(field: FieldType) {
        if let field = field as? Field<String> {
            self.value = field.value
        }
    }
}

class FieldTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOperators() {
        let entity = Entity()
        entity.name <-- "Bob"
        XCTAssertEqual(entity.name.value, "Bob")
        
//        "John" --> entity.name
//        XCTAssertEqual(entity.name.value, "John")
        
        //        let view = View()
        //        view <-- entity.name
        //        XCTAssertEqual(entity.name.value, view.value)
    }
    
    func testObservation() {
        let view = View()
        let entity = Entity()
        entity.name.addObserver(view)
        entity.name <-- "Alice"
        XCTAssertEqual(view.value, "Alice")
        
        var value:String = "test"
        entity.name.observe { field in
            value = field.value!
        }
        entity.name <-- "NEW VALUE"
        XCTAssertEqual(value, "NEW VALUE")
    }
    
//    func testBinding() {
//        let view = View()
//        let entity = Entity()
//        
//        view <--> entity.name
//        
//        view.value = "viewValue"
//        entity.name.value = "nameValue"
//        
//        view.value = "new viewValue"
//        XCTAssertEqual(view.value, entity.name.value)
//        
//        entity.name.value = "new nameValue"
//        XCTAssertEqual(view.value, entity.tname.value)
//    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
