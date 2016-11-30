//
//  Array+Difference.swift
//  APIKit
//
//  Created by Sam Williams on 2/10/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

public extension Collection where Iterator.Element: Hashable {
    func difference<T>(_ other: T) -> Array<Iterator.Element> where T:Collection, T.Iterator.Element == Iterator.Element {
        let selfSet = Set(self)
        let otherSet = Set(other)
        return Array(selfSet.subtracting(otherSet))
    }
    
    func symmetricDifference(_ other: Array<Iterator.Element>) -> (Array<Iterator.Element>, Array<Iterator.Element>) {
        let selfSet = Set(self)
        let otherSet = Set(other)
        return (Array(selfSet.subtracting(otherSet)), Array(otherSet.subtracting(selfSet)))
    }
}
