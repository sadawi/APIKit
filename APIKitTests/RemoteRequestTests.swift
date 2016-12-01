//
//  RemoteRequestTests.swift
//  APIKit
//
//  Created by Sam Williams on 2/10/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import XCTest

class RemoteRequestTests: XCTestCase {

    func testSimpleRequestEncoding() {
        let dict = ["name": "Bob"]
        let json = ParameterEncoder().encodeParameters(dict as AnyObject)
        XCTAssertEqual("name=Bob", json)
    }
    
    func testRequestEncoding() {
        let dict = ["people": [["name": "Bob", "age": 65], ["name": "Alice"]]]
        let json = ParameterEncoder().encodeParameters(dict as AnyObject)
        XCTAssertEqual("people[0][age]=65&people[0][name]=Bob&people[1][name]=Alice", json)
    }
    
    func testEncoding() {
        let parameters = ["query": "New York"]
        
        let encoder = ParameterEncoder()
        XCTAssertEqual(encoder.encodeParameters(parameters as AnyObject), "query=New York")
        encoder.escapeStrings = true
        XCTAssertEqual(encoder.encodeParameters(parameters as AnyObject), "query=New%20York")
        encoder.escapeStrings = false
        XCTAssertEqual(encoder.encodeParameters(parameters as AnyObject), "query=New York")
    }
    
    func testNils() {
        let parameters:[String:AnyObject] = ["age": NSNull()]
        let encoder = ParameterEncoder()
        XCTAssertEqual(encoder.encodeParameters(parameters as AnyObject), "")
        encoder.includeNullValues = true
        XCTAssertEqual(encoder.encodeParameters(parameters as AnyObject), "age=")

        let dict = ["people": [["name": "Bob", "age": NSNull()], ["name": "Alice"]]]
        encoder.includeNullValues = false
        let json = encoder.encodeParameters(dict as AnyObject)
        XCTAssertEqual("people[0][name]=Bob&people[1][name]=Alice", json)

    }

}
