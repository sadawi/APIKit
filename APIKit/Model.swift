//
//  Model.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

public typealias AttributeDictionary = [String:AnyObject]

public class Model: DictionarySerializable, Routable, NSCoding {
    public var identifier:String?
    
    public var persisted:Bool {
        get {
            return self.identifier != nil
        }
    }
    
    public class var identifierKey:String {
        get { return "id" }
    }
    
    // MARK: Routable
    
    public class var path: String {
        get { return "models" }
    }
    
    // MARK: DictionarySerializable overrides
    
    public override var dictionaryValue:AttributeDictionary {
        get {
            var result = super.dictionaryValue
            
            if let id = self.identifier {
                result["id"] = id
            }
            return result;
        }
        set {
            super.dictionaryValue = newValue
            self.identifier = newValue["id"] as? String
        }
    }
    
    // MARK: - NSCoding
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.setValue(self.dictionaryValue, forKey: "attributes")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        if let attributes = aDecoder.valueForKey("attributes") as? AttributeDictionary {
            self.dictionaryValue = attributes
        } else {
            return nil
        }
    }

    required public init() {
    }

}