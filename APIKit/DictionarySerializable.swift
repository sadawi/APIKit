//
//  DictionarySerializable.swift
//  APIKit
//
//  Created by Sam Williams on 11/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

open class DictionarySerializable: NSObject, NSCopying {
    
    /**
        Attempts to instantiate a new object from a dictionary representation of its attributes.
        It's a class method to allow returning a canonical object instance for an identifier, if desired.
    */
    open class func fromDictionaryValue(_ dictionaryValue:AttributeDictionary) -> Self? {
        let instance = self.init()
        instance.dictionaryValue = dictionaryValue
        return instance
    }
    
    override required public init() {
    }
    
    /**
        Constructs a dictionary representation of this instance's attributes
    */
    open var dictionaryValue:AttributeDictionary {
        get {
            return [:]
        }
        set {
        }
    }
    
    open func copy(with zone: NSZone?) -> Any {
        return type(of: self).fromDictionaryValue(self.dictionaryValue)!
    }
    
}
