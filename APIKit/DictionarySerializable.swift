//
//  DictionarySerializable.swift
//  APIKit
//
//  Created by Sam Williams on 11/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

public class DictionarySerializable {
    
    public class func fromDictionaryValue(dictionaryValue:[String:AnyObject]) -> Self? {
        let instance = self.init()
        instance.dictionaryValue = dictionaryValue
        return instance
    }
    
    required public init() {
    }
    
    public var dictionaryValue:[String:AnyObject] {
        get {
            return [:]
        }
        set {
        }
    }
    
}