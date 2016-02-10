//
//  ArrayTests.swift
//  APIKit
//
//  Created by Sam Williams on 2/10/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import XCTest

class ArrayTests: XCTestCase {
    func testArrayExtension() {
        let a1 = ["red", "blue"]
        let a2 = ["red"]
        XCTAssertEqual(["blue"], a1.difference(a2))
        
        let a3 = ["blue", "green"]
        let (left, right) = a1.symmetricDifference(a3)
        XCTAssertEqual(["red"], left)
        XCTAssertEqual(["green"], right)
    }
}