//
//  RemoteRequestTests.swift
//  APIKit
//
//  Created by Sam Williams on 2/10/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import XCTest

class RemoteRequestTests: XCTestCase {

    
    func testRequestEncoding() {
        let dict = ["people": [["name": "Bob", "age": 65], ["name": "Alice"]]]
        let json = RequestEncoder.encodeParameters(dict)
        XCTAssertEqual("people[0][age]=65&people[0][name]=Bob&people[1][name]=Alice", json)
    }
    
    func testEncoding() {
        let parameters = ["query": "New York"]
        XCTAssertEqual(RequestEncoder.encodeParameters(parameters, escape: true), "query=New%20York")
        XCTAssertEqual(RequestEncoder.encodeParameters(parameters, escape: false), "query=New York")
        XCTAssertEqual(RequestEncoder.encodeParameters(parameters), "query=New York")
    }

}
