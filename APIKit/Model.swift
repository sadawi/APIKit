//
//  Model.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

public class Model: DictionarySerializable, Routable {
    public var identifier:String?
    
    public var persisted:Bool {
        get {
            return self.identifier != nil
        }
    }
    
    // MARK: Routable
    
    public class var path: String {
        get { return "models" }
    }
    
    // MARK: DictionarySerializable overrides
    
    public override var dictionaryValue:[String:AnyObject] {
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

}