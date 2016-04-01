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

private class BaseModel:Model {
    let id          = Field<String>()
    override var identifierField:FieldType {
        return self.id
    }
}

private class Category:BaseModel {
    let categoryName = Field<String>()
}

private class Product:BaseModel {
    let productName = Field<String>()
    let category = ModelField<Category>()
}

private class Company:BaseModel {
    let name        = Field<String>()
    let products    = *ModelField<Product>()
    let widgets     = *ModelField<Product>(foreignKey: true, key: "widgetIDs")
}

private class Person:BaseModel {
    let name    = Field<String>()
    let age     = Field<Int>()
    let company = ModelField<Company>(foreignKey: true)
    // TODO: pets (avoid cycles!)
    
    required init() { }
    
    init(name:String?, age:Int?) {
        self.name.value = name
        self.age.value = age
    }
}

private class Pet:BaseModel {
    let name    = Field<String>()
    let species = Field<String>()
    let owner   = ModelField<Person>(foreignKey: true)
    
    required init() { }

    init(name:String?, species:String?) {
        self.name.value = name
        self.species.value = species
    }
}

private class Left: Model {
    let id = Field<String>()
    let right = ModelField<Right>()
}

private class Right: Model {
    let id = Field<String>()
    let left = ModelField<Left>()
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
    
    func testArrayVisit() {
        let company = Company.fromDictionaryValue(["products": [["id":"100", "productName": "iPhone"]]])
        XCTAssertEqual(company?.products.value?.count, 1)
        var iphone = false
        company?.visitAllFieldValues(recursive: true) { value in
            if (value as? String) == "iPhone" {
                iphone = true
            }
        }
        XCTAssert(iphone)
    }
    
    func testCycles() {
        let left = Left()
        let right = Right()
        
        left.id.value = "leftID"
        right.id.value = "rightID"
        
        left.right.value = right
        right.left.value = left
        
        let leftDict = left.dictionaryValue
        XCTAssertEqual(leftDict.count, 2)
        
        XCTAssertEqual(leftDict["id"] as? String, "leftID")

        let leftRightDict = leftDict["right"] as? AttributeDictionary
        XCTAssertEqual(leftRightDict?["id"] as? String, "rightID")
        
        let leftRightLeftDict = leftRightDict?["left"] as? AttributeDictionary
        // Should only have the identifier
        XCTAssertEqual(leftRightLeftDict?.count, 1)
        XCTAssertNil(leftRightLeftDict?["left"])
        XCTAssertNil(leftRightLeftDict?["right"])
        XCTAssertEqual(leftRightLeftDict?["id"] as? String, "leftID")
        
        var fields:[FieldType] = []
        left.visitAllFields { field in
            fields.append(field)
        }
        XCTAssertEqual(fields.count, 4)

        var fieldValues:[Any?] = []
        left.visitAllFieldValues { value in
            fieldValues.append(value)
        }
        XCTAssertEqual(fieldValues.count, 4)
    
    }
    
    func testArrayShells() {
        let company = Company.fromDictionaryValue(["widgetIDs": ["44", "55"]])
        let shells = company?.shells(recursive: true)
        XCTAssertEqual(shells?.count, 2)
    }

    func testShells() {
        let didSave = expectationWithDescription("save")
        
        let phil = Person.fromDictionaryValue(["name": "Phil", "age": 44, "company": "testID"])!
        
        ModelManager.sharedInstance.dataStore.save(phil).then { model -> Void in
            // Fails because 555 is not a valid owner id (should be string)
            let grazi0 = Pet.fromDictionaryValue(["name": "Grazi", "owner": 555])
            XCTAssertNil(grazi0?.owner.value?.id.value)

            let grazi1 = Pet.fromDictionaryValue(["name": "Grazi", "owner": phil.id.value!])
            XCTAssertEqual(grazi1?.owner.value?.id.value, phil.id.value)
            
            let shells = grazi1!.shells()
            XCTAssertEqual(1, shells.count)
            let shell = shells.first as? Person
            XCTAssertEqual(shell?.identifier, phil.identifier)
            
            let grazi2 = Pet()
            grazi2.owner.value = phil
            let shells2 = grazi2.shells(recursive: true)
            XCTAssertEqual(1, shells2.count)
            let shell2 = shells2.first as? Company
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

    func testVisitAllFields() {
        let company = Company()
        company.name.value = "Apple"
        
        let iphone = Product()
        iphone.productName.value = "iPhone"
        company.products.value = [iphone]
        
        var keys:[String] = []
        
        company.visitAllFields(recursive: false) { field in
            if let k = field.key {
                keys.append(k)
            }
        }
        XCTAssertEqual(keys.sort(), ["id", "name", "products", "widgetIDs"])
        
        keys = []
        company.visitAllFields(recursive: true) { field in
            if let k = field.key {
                keys.append(k)
            }
        }
        XCTAssertEqual(keys.sort(), ["category", "id", "id", "name", "productName", "products", "widgetIDs"])
    }

    func testVisitAllFieldsSimple() {
        let category = Category()
        category.categoryName.value = "phones"
        
        let iphone = Product()
        iphone.productName.value = "iPhone"
        iphone.category.value = category
        
        var keys:[String] = []
        
        category.visitAllFields(recursive: false) { field in
            if let k = field.key {
                keys.append(k)
            }
        }
        XCTAssertEqual(keys.sort(), ["categoryName", "id"])
        
        keys = []
        iphone.visitAllFields(recursive: true) { field in
            if let k = field.key {
                keys.append(k)
            }
        }
        XCTAssertEqual(keys.sort(), ["category", "categoryName", "id", "id", "productName"])
    }
    
    func testSaveDelete() {
        let didSave = expectationWithDescription("save")
        let didList = expectationWithDescription("list")
        let didDelete = expectationWithDescription("delete")
        
        let store = MemoryDataStore()
        let a = Person()
        a.identifier = "12324"
        store.save(a).then { _ -> () in
            didSave.fulfill()
            store.list(Person.self).then { people -> () in
                XCTAssertEqual(people.count, 1)
                didList.fulfill()

                store.deleteAll(Person.self).then { () -> () in
                    store.list(Person.self).then { people -> () in
                        XCTAssertEqual(people.count, 0)
                        didDelete.fulfill()
                    }
                }
            }
        }
        
        self.waitForExpectationsWithTimeout(1, handler:nil)

    }

    func testSaveDeleteEverything() {
        let didDeleteB = expectationWithDescription("deleteB")
        let didDeleteA = expectationWithDescription("deleteA")
        
        let store = MemoryDataStore()
        
        let a = Person()
        a.identifier = "123244"
        
        let b = Product()
        b.identifier = "12345566"
        
        when(store.save(a), store.save(b)).then { _ -> () in
            store.list(Person.self).then { people -> () in
                XCTAssertEqual(people.count, 1)
                
                store.deleteAll().then { () -> () in
                    store.list(Person.self).then { people -> () in
                        XCTAssertEqual(people.count, 0)
                        didDeleteA.fulfill()
                    }
                    
                    store.list(Product.self).then { products -> () in
                        XCTAssertEqual(products.count, 0)
                        didDeleteB.fulfill()
                    }
                }
            }
        }
        
        self.waitForExpectationsWithTimeout(1, handler:nil)
        
    }

    
}
