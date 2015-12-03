//
//  Model.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

public typealias AttributeDictionary = [String:AnyObject]



public class Model: DictionarySerializable, Routable {
    // Always storing id as a string (but assuming it's an Int in the API)
    // TODO: better way to handle string vs. int identifier types
    public var identifier:String?
    
    // TODO: permissions
    public var editable:Bool = true
    
    public var persisted:Bool {
        get {
            return self.identifier != nil
        }
    }
    
    public class var identifierKey:String {
        get { return "id" }
    }
    
    public class var name:String {
        get {
            if let name = NSStringFromClass(self).componentsSeparatedByString(".").last {
                return name
            } else {
                return "Unknown"
            }
        }
    }
    
    // MARK: Routable
    
    public class var path: String {
        get {
            assert(false, "This must be overridden")
            return "models"
        }
    }
    
    public func beforeSave() {
        // Nothing yet.
    }
    
    public func afterCreate() { }
    public func afterDelete() { }
    
    // MARK: DictionarySerializable overrides
    
    public override var dictionaryValue:AttributeDictionary {
        get {
            var result = super.dictionaryValue
            
            if let id = self.identifier {
                result[self.dynamicType.identifierKey] = Int(id)
            }
            return result;
        }
        set {
            super.dictionaryValue = newValue
            if let value = newValue[self.dynamicType.identifierKey] as? Int {
                self.identifier = String(value)
            }
        }
    }
    
}