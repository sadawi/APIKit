//
//  Array+Difference.swift
//  APIKit
//
//  Created by Sam Williams on 2/10/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

public extension _ArrayType where Generator.Element: Hashable {
    func difference<T where T:_ArrayType, T.Generator.Element == Generator.Element>(other: T) -> Array<Generator.Element> {
        let selfSet = Set(self)
        let otherSet = Set(other)
        return Array(selfSet.subtract(otherSet))
    }
    
    func symmetricDifference(other: Array<Generator.Element>) -> (Array<Generator.Element>, Array<Generator.Element>) {
        let selfSet = Set(self)
        let otherSet = Set(other)
        return (Array(selfSet.subtract(otherSet)), Array(otherSet.subtract(selfSet)))
    }
}