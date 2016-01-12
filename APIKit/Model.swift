//
//  Model.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation
import MagneticFields

public typealias AttributeDictionary = [String:AnyObject]

public class Model: DictionarySerializable, Routable {
    /**
     Which field should be treated as the identifier?
     If all the models in your system have the same identifier field (e.g., "id"), you'll probably want to just put that in your 
     base model class.
     */
    public var identifierField: FieldType? {
        return nil
    }
    
    /**
     Attempts to find the identifier as a String or Int, and cast it to a String
     (because it's useful to have an identifier with known type!)
     */
    public var identifier:String? {
        get {
            let value = self.identifierField?.anyObjectValue
            
            if let value = value as? String {
                return value
            } else if let value = value as? Int {
                return String(value)
            } else {
                return nil
            }
        }
        set {
            if let id = newValue {
                if let stringField = self.identifierField as? Field<String> {
                    stringField.value = id
                } else if let intField = self.identifierField as? Field<Int> {
                    intField.value = Int(id)
                }
            }
        }
    }
    
    // TODO: permissions
    public var editable:Bool = true
    
    public var shell:Bool = false
    
    public var persisted:Bool {
        get {
            return self.identifier != nil
        }
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
    
    public func afterCreate() { }
    public func afterDelete() { }
    public func beforeSave() {
        self.resetValidationState()
    }
    
    // MARK: FieldModel
    
    public func addError(keyPath path:String, message:String) {
        if let field = self.fieldForKeyPath(path) {
            field.addValidationError(message)
        }
    }
    
    public func fieldForKeyPath(components:[String]) -> FieldType? {
        guard components.count > 0 else { return nil }
        
        let fields = self.fields()
        if let firstField = fields[components[0]] {
            let remainingComponents = Array(components[1..<components.count])
            if remainingComponents.count == 0 {
                // No more components.  Just return the field
                return firstField
            } else if let firstValue = firstField.anyValue as? Model {
                // There are more components remaining, and we can keep traversing key paths
                return firstValue.fieldForKeyPath(remainingComponents)
            }
        }
        return nil
    }
    
    public func fieldForKeyPath(path:String) -> FieldType? {
        return fieldForKeyPath(self.componentsForKeyPath(path))
    }
    
    /**
     Splits a field keypath into an array of field names to be traversed.
     For example, "address.street" might be split into ["address", "street"]
     
     To change the default behavior, you'll probably want to subclass.
     */
    public func componentsForKeyPath(path:String) -> [String] {
        return path.componentsSeparatedByString(".")
    }
    
    public func fields() -> [String:FieldType] {
        var result:[String:FieldType] = [:]
        let mirror = Mirror(reflecting: self)
        mirror.eachChild { child in
            if let label = child.label, value = child.value as? FieldType {
                result[label] = value
            }
        }
        
        return result
    }
    
    /**
     Which fields should we include in the dictionaryValue?
     By default, includes all of them.
     */
    public func fieldsForDictionaryValue() -> [FieldType] {
        return Array(self.fields().values)
    }
    
    /**
     Look at the instance's fields, do some introspection and processing.
     */
    func processFields() {
        for (key, field) in self.fields() {
            if field.key == nil {
                field.key = key
            }
            //            field.owner = self
            //            field.buildSerializer()
        }
    }
    
    //    public func serializerForField(field:FieldType) -> FieldSerializerType {
    //        return DictionaryFieldSerializer<T>()
    //    }
    
    public required init() {
        super.init()
        self.processFields()
    }
    
    public func validate() -> Bool {
        self.resetValidationState()
        
        var allValid = true
        self.visitAllFields { field in
            // Make sure to call validate() on each field (don't short circuit if false)
            let valid = (field.validate() == .Valid)
            
            allValid = allValid && valid
        }
        return allValid
    }
    
    public func resetValidationState() {
        self.visitAllFields { $0.resetValidationState() }
    }
    
    public func visitAllFields(action:(FieldType -> Void)) {
        for (_, field) in self.fields() {
            action(field)
            
            // And all the way down!
            if let value = field.anyValue as? Model {
                value.visitAllFields(action)
            }
        }
    }
    
    public override var dictionaryValue:AttributeDictionary {
        get {
            var result:AttributeDictionary = [:]
            let include = self.fieldsForDictionaryValue()
            for (name, field) in self.fields() {
                if include.contains({ $0 === field }) && field.state == .Set {
                    field.writeToDictionary(&result, name: field.key ?? name)
                }
            }
            return result
        }
        set {
            super.dictionaryValue = newValue
            let include = self.fieldsForDictionaryValue()
            for (name, field) in self.fields() {
                if include.contains({ $0 === field }) {
                    field.readFromDictionary(newValue, name: field.key ?? name)
                }
            }
        }
    }
    
}