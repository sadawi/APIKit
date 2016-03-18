//
//  TypeDictionaryTests.swift
//  APIKit
//
//  Created by Sam Williams on 3/17/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import XCTest
import APIKit

class TypeDictionaryTests: XCTestCase {

    func testTypeDictionary() {
        var dict = TypeDictionary<String>()
        dict[String.self] = "string"
        
        XCTAssertEqual(1, dict.count)
        var count = 0
        for (type, string) in dict {
            XCTAssert(type == String.self)
            XCTAssert(string == "string")
            count = count + 1
        }
        XCTAssertEqual(count, 1)
        
        dict[Int.self] = "integer"

        XCTAssertEqual(2, dict.count)
    }

}
