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

/**
 An object that keeps track of canonical model instances, presumably indexed by identifier.
*/
public protocol ModelRegistry {
    /// Registers a new model in the registry.
    func didInstantiateModel<T:Model>(model:T)
    
    /// Tries to find a registered canonical instance matching the provided model.  Should return nil if no such object has been registered.
    func canonicalModelForModel<T:Model>(model:T) -> T?
}

/**
 A very simple ModelRegistry adapter for a MemoryDataStore
*/
public struct MemoryRegistry: ModelRegistry {
    var memory = MemoryDataStore.sharedInstance
    
    public func didInstantiateModel<T:Model>(model: T) {
        if model.identifier != nil {
            self.memory.updateImmediately(model)
        }
    }
    
    public func canonicalModelForModel<T:Model>(model: T) -> T? {
        if let identifier = model.identifier {
            return self.memory.lookupImmediately(T.self, identifier: identifier)
        } else {
            return nil
        }
    }
}

public class Model: NSObject, Routable, NSCopying {
    /**
     An object that is responsible for keeping track of canonical instances
     */
    public static var registry:ModelRegistry? = MemoryRegistry()
    
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
    
    public class func withIdentifier(identifier: Identifier) -> Self {
        let instance = self.init()
        instance.identifier = identifier
        if let canonical = Model.registry?.canonicalModelForModel(instance) {
            return canonical
        } else {
            instance.registerInstance()
            return instance
        }
    }
    
    public func registerInstance() {
        self.dynamicType.registry?.didInstantiateModel(self)
    }
    
    public func canonicalInstance() -> Self {
        return self.dynamicType.registry?.canonicalModelForModel(self) ?? self
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
    
    public class var collectionPath: String? {
        get {
            return nil
        }
    }
    
    public func afterInit() { }
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
        
        let fields = self.fields
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
    
    /**
     Builds a mapping of keys to fields.  Keys are either the field's `key` property (if specified) or the property name of the field.
     This can be slow, since it uses reflection.  If you find this to be a performance bottleneck, consider overriding this var
     with an explicit mapping of keys to fields.
     */
    public var fields: [String:FieldType] {
        return _fields
    }
    lazy private var _fields: [String:FieldType] = {
        var result:[String:FieldType] = [:]
        let mirror = Mirror(reflecting: self)
        mirror.eachChild { child in
            if let label = child.label, value = child.value as? FieldType {
                // If the field has its key defined, use that; otherwise fall back to the property name.
                let key = value.key ?? label
                result[key] = value
            }
        }
        
        return result
    }()
    
    /**
     Which fields should we include in the dictionaryValue?
     By default, includes all of them.
     */
    public func fieldsForDictionaryValue() -> [FieldType] {
        return Array(self.fields.values)
    }
    
    /**
     Look at the instance's fields, do some introspection and processing.
     */
    internal func processFields() {
        for (key, field) in self.fields {
            if field.key == nil {
                field.key = key
            }
            if let modelField = field as? ModelFieldType {
                modelField.model = self
            }
        }
    }
    
    public required override init() {
        super.init()
        self.processFields()
        self.afterInit()
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
        for (_, field) in self.fields {
            
            action(field)
            
            if recursive {
                if let value = field.anyObjectValue as? Model {
                    value.visitAllFields(recursive: recursive, action: action)
                } else if let values = field.anyObjectValue as? NSArray {
                    for value in values {
                        if let model = value as? Model {
                            model.visitAllFields(recursive: recursive, action: action)
                        }
                    }
                }
            }
        }
    }

    public func visitAllFieldValues(recursive recursive:Bool = true, action:(Any? -> Void)) {
        for (_, field) in self.fields {
            
            action(field.anyValue)
            
            if recursive {
                if let value = field.anyObjectValue as? Model {
                    value.visitAllFieldValues(recursive: recursive, action: action)
                } else if let value = field.anyValue, let values = value as? NSArray {
                    // I'm not sure why I can't cast to [Any]
                    // http://stackoverflow.com/questions/26226911/how-to-tell-if-a-variable-is-an-array
                    
                    for value in values {
                        action(value)
                        if let modelValue = value as? Model {
                            modelValue.visitAllFieldValues(recursive: recursive, action: action)
                        }
                    }
                }
            }
        }
    }
    
    public func dictionaryValueWithFields(fields:[FieldType]?=nil) -> AttributeDictionary {
        let fields = fields ?? self.fieldsForDictionaryValue()
        var result:AttributeDictionary = [:]
        let include = fields
        for (name, field) in self.fields {
            if include.contains({ $0 === field }) && field.state == .Set {
                field.writeToDictionary(&result, name: field.key ?? name)
            }
        }
        return result
    }
    
    
    public var dictionaryValue:AttributeDictionary {
        get {
            return self.dictionaryValueWithFields()
        }
        set {
            let include = self.fieldsForDictionaryValue()
            for (name, field) in self.fields {
                if include.contains({ $0 === field }) {
                    field.readFromDictionary(newValue, name: field.key ?? name)
                }
            }
        }
    }
    
    /**
     Finds all values that are shells (i.e., a model instantiated from just a foreign key)
     */
    public func shells(recursive recursive:Bool = false) -> [Model] {
        var results:[Model] = []
        self.visitAllFieldValues(recursive: recursive) { value in
            if let model = value as? Model where model.shell == true {
                results.append(model)
            }
        }
        return results
    }
    
    /**
     All models related with foreignKey fields
     */
    public func foreignKeyModels() -> [Model] {
        var results:[Model] = []
        
        self.visitAllFields { field in
            if let modelField = field as? ModelFieldType where modelField.foreignKey == true {
                if let value = modelField.anyObjectValue as? Model {
                    results.append(value)
                } else if let values = modelField.anyObjectValue as? [Model] {
                    for value in values {
                        results.append(value)
                    }
                }
            }
        }
        return results
    }
}
