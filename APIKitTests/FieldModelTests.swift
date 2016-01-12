//
//  FieldModelTests.swift
//  APIKit
//
//  Created by Sam Williams on 12/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import XCTest
import MagneticFields

class FieldModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    class Company: Model {
        let name = Field<String>()
        let size = Field<Int>()
        let parentCompany = Field<Company>().transform(ModelValueTransformer<Company>())
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
        let parentDict = dict["parentCompany"]
        XCTAssert(parentDict is AttributeDictionary)
        
        if let parentDict = parentDict as? AttributeDictionary {
            XCTAssertEqual(parentDict["name"] as? String, "Parent Company")
        }
    }
    
}
