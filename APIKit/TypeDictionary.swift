//
//  TypeDictionary.swift
//  APIKit
//
//  Created by Sam Williams on 3/17/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

public struct TypeDictionary<T>: Sequence {
    fileprivate var dictionary: [TypeWrapper: T] = [:]
    
    public init() {
    }
    
    public var count: Int {
        return self.dictionary.count
    }
    
    public subscript(type: Any.Type) -> T? {
        get {
            return self.dictionary[TypeWrapper(type)]
        }
        set {
            self.dictionary[TypeWrapper(type)] = newValue
        }
    }
    
    public func makeIterator() -> AnyIterator<(Any.Type, T)> {
        var nextIndex = dictionary.keys.count-1
        
        return AnyIterator {
            if (nextIndex < 0) {
                return nil
            }
            let k = Array(self.dictionary.keys)[nextIndex]
            nextIndex = nextIndex - 1
            return (k.type, self.dictionary[k]!)
        }
    }

}

private struct TypeWrapper:Hashable {
    var type:Any.Type
    init(_ type:Any.Type) {
        self.type = type
    }
    var hashValue:Int {
        return String(describing: self.type).hashValue
    }
}

private func ==(left:TypeWrapper, right:TypeWrapper) -> Bool {
    return left.hashValue == right.hashValue
}
