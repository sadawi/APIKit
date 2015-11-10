//
//  DictionarySerializable.swift
//  APIKit
//
//  Created by Sam Williams on 11/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

public class DictionarySerializable {
    
    /**
        Attempts to instantiate a new object from a dictionary representation of its attributes
    */
    public class func fromDictionaryValue(dictionaryValue:AttributeDictionary) -> Self? {
        let instance = self.init()
        instance.dictionaryValue = dictionaryValue
        return instance
    }
    
    required public init() {
    }
    
    /**
        Constructs a dictionary representation of this instance's attributes
    */
    public var dictionaryValue:AttributeDictionary {
        get {
            return [:]
        }
        set {
        }
    }
    
}