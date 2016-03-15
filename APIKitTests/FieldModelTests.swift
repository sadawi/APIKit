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
        let employees:ModelArrayField<Person> = *ModelField<Person>(inverse: { person in return person.company })
    }
    
    private class Person: Model {
        let name = Field<String>()
        let company = ModelField<Company>(inverse: { company in return company.employees })
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
    
    func testSelectiveDictionary() {
        let co = Company()
        co.name.value = "Apple"
        let dictionary = co.dictionaryValueWithFields([co.name])
        XCTAssertEqual(dictionary as! [String: String], ["name": "Apple"])
    }
    
    func testInverseFields() {
        let person1 = Person()
        let profileA = Profile()
        
        person1.profile.value = profileA
        XCTAssertEqual(profileA.person.value, person1)
        
        let profileB = Profile()
        profileB.person.value = person1
        XCTAssertEqual(person1.profile.value, profileB)
        
        XCTAssertNil(profileA.person.value)
        
        let company1 = Company()
        let company2 = Company()

        person1.company.value = company1
        XCTAssertEqual(1, company1.employees.value?.count)
        
        company1.employees.removeFirst(person1)
        XCTAssertEqual(0, company1.employees.value?.count)
        XCTAssertNil(person1.company.value)
        
        company2.employees.value = [person1]
        XCTAssertEqual(person1.company.value, company2)
        XCTAssertEqual(0, company1.employees.value?.count)
    }
    
    private class Letter: Model {
        override class func newInstanceForDictionaryValue(dictionaryValue: AttributeDictionary) -> Self? {
            if let letter = dictionaryValue["letter"] as? String {
                return self.instance(letter)
            }
            return nil
        }
        
        class func instance<T where T: Letter>(letter: String) -> T? {
            if letter == "a" {
                return A() as? T
            } else if letter == "b" {
                return B() as? T
            } else {
                return nil
            }
        }
    }
    
    private class A: Letter {
    }
    
    private class B: Letter {
    }
    
    func testCustomSubclass() {
        let a = Letter.fromDictionaryValue(["letter": "a"])
        XCTAssert(a is A)

        let b = Letter.fromDictionaryValue(["letter": "b"])
        XCTAssert(b is B)
    }

}
