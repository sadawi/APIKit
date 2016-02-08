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
    
    private class Profile: Model {
        let person:ModelField<Person> = ModelField<Person>(inverse: { $0.profile })
    }
    
    private class Company: Model {
        let name = Field<String>()
        let size = Field<Int>()
        let parentCompany = ModelField<Company>()
//        let employees = *ModelField<Person>() //.inverse { person in return person.company }
    }
    
    private class Person: Model {
        let name = Field<String>()
        let company = ModelField<Company>() // (inverse: { $0.employees })
        let profile = ModelField<Profile>(inverse: { $0.person })
    }
    
    func testFieldModel() {
        let co = Company()
        co.name.value = "The Widget Company"
        co.size.value = 22
        
        let fields = co.fields
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
    
    func testInverseFields() {
//        let company1 = Company()
//        let company2 = Company()
        let person1 = Person()
        let profileA = Profile()
        
        person1.profile.value = profileA
        XCTAssertEqual(profileA.person.value, person1)
        
        let profileB = Profile()
        profileB.person.value = person1
        XCTAssertEqual(person1.profile.value, profileB)
        
        XCTAssertNil(profileA.person.value)
        
//        person1.company.value = company1
//        XCTAssertEqual(1, company1.employees.value?.count)
    }
    
}
