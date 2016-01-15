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
public typealias Identifier = String

public protocol ModelRegistry {
    func didInstantiateModel<T:Model>(model:T)
    func canonicalModelForModel<T:Model>(model:T) -> T?
}

public class Model: NSObject, Routable, NSCopying {
    /**
     An object that is responsible for keeping track of canonical instances
     */
    public static var registry:ModelRegistry?
    
    /**
     Attempts to instantiate a new object from a dictionary representation of its attributes.
     If a registry is set, will attempt to reuse the canonical instance for its identifier
     
     - parameter dictionaryValue: The attributes
     - parameter useRegistry: Whether we should attempt to canonicalize models and register new ones
     - parameter configure: A closure to configure a deserialized model, taking a Bool flag indicating whether it was newly instantiated (vs. reused from registry)
     */
    public class func fromDictionaryValue(dictionaryValue:AttributeDictionary, useRegistry:Bool = true, configure:((Model,Bool) -> Void)?=nil) -> Self? {
        var instance = self.init()
        (instance as Model).dictionaryValue = dictionaryValue
        
        var isNew = true
        
        if useRegistry {
            if let registry = self.registry {
                // If we have a canonical object for this id, swap it in
                if let canonical = registry.canonicalModelForModel(instance) {
                    isNew = false
                    instance = canonical
                    (instance as Model).dictionaryValue = dictionaryValue
                } else {
                    isNew = true
                    registry.didInstantiateModel(instance)
                }
            }
        }
        configure?(instance, isNew)
        return instance
        
    }
    
    /**
     Creates a clone of this model.  It won't exist in the registry.
     */
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self.dynamicType.fromDictionaryValue(self.dictionaryValue, useRegistry: false)!
    }

    
    /**
     Which field should be treated as the identifier?
     If all the models in your system have the same identifier field (e.g., "id"), you'll probably want to just put that in your
     base model class.
     */
    public var identifierField: FieldType? {
        return nil
    }
    
    /**
     Attempts to find the identifier as a String or Int, and cast it to an Identifier (aka String)
     (because it's useful to have an identifier with known type!)
     */
    public var identifier:Identifier? {
        get {
            let value = self.identifierField?.anyObjectValue
            
            if let value = value as? Identifier {
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
        }
    }
    
    public required override init() {
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
    
    public func visitAllFields(recursive recursive:Bool = true, action:(FieldType -> Void)) {
        for (_, field) in self.fields() {
            
            action(field)
            
            if recursive {
                if let value = field.anyObjectValue as? Model {
                    value.visitAllFields(recursive: recursive, action: action)
                } else if let values = field.anyObjectValue as? [Model] {
                    for value in values {
                        value.visitAllFields(recursive: recursive, action: action)
                    }
                }
            }
        }
    }
    
    public var dictionaryValue:AttributeDictionary {
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
            let include = self.fieldsForDictionaryValue()
            for (name, field) in self.fields() {
                if include.contains({ $0 === field }) {
                    field.readFromDictionary(newValue, name: field.key ?? name)
                }
            }
        }
    }
    
    // MARK: - Shells
    
    public func shells(recursive recursive:Bool = false) -> [Model] {
        let results = NSMutableSet()
        results.addObjectsFromArray(self.shellFields().map{$0.anyObjectValue as! Model})
        return results.allObjects as! [Model]
    }
    
    /**
     Finds all the fields whose value is a shell (i.e., just an identifier)
     */
    public func shellFields(recursive recursive:Bool = false) -> [FieldType] {
        var results:[FieldType] = []
        self.visitAllFields(recursive: recursive) { field in
            if let model = field.anyObjectValue as? Model where model.shell == true {
                results.append(field)
            }
        }
        
        return results
    }
    
    
    /**
     Attempts to turn all the shells into full objects.
     
     - parameter lookup: A closure to be used to look up a model from its shell.  Must be a synchronous operation!
     */
    public func fillShells(recursive recursive:Bool = false, lookup: (Model -> Model?)) {
        for field in self.shellFields() {
            if let shellValue = field.anyObjectValue as? Model, model = lookup(shellValue) {
                if recursive {
                    // Recursively fill the new model's shells, too
                    model.fillShells(recursive: true, lookup: lookup)
                }
                field.anyObjectValue = model as AnyObject
            }
        }
    }
    
}