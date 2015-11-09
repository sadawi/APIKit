//
//  Model.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

class Model: DictionarySerializable, Routable {
    var identifier:String?
    
    var persisted:Bool {
        get {
            return self.identifier != nil
        }
    }
    
    // MARK: Routable
    
    class var path: String {
        get { return "models" }
    }
    
    // MARK: DictionarySerializable overrides
    
    override var dictionaryValue:[String:AnyObject] {
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