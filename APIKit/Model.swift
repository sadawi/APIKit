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
    var memory: MemoryDataStore
    
    public init() {
        self.memory = MemoryDataStore.sharedInstance
    }
    
    public init(dataStore: MemoryDataStore) {
        self.memory = dataStore
    }
    
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
     The class to instantiate, based on a dictionary value.
     
     Whatever class you attempt to return must be cast to T.Type, which is inferred to be Self.
     
     In other words, if you don't return a subclass, it's likely that you'll silently get an instance of
     whatever class defines this method.
     */
    public class func instanceClassForDictionaryValue<T>(dictionaryValue: AttributeDictionary) -> T.Type? {
        return self as? T.Type
    }
    
    private static var prototypes = TypeDictionary<Model>()
    
    internal static func prototypeForType<T: Model>(type: T.Type) -> T {
        if let existing = prototypes[type] as? T {
            return existing
        } else {
            let prototype = type.init()
            prototypes[type] = prototype
            return prototype
        }
    }
    
    /**
     Generates a RESTful path component for a single model using its identifier.
     
     Example: "users/42"
     */
    public var path:String? {
        get {
            if let id = self.identifier, let collectionPath = self.dynamicType.collectionPath {
                return "\(collectionPath)/\(id)"
            } else {
                return nil
            }
        }
    }
    
    /**
     Attempts to instantiate a new object from a dictionary representation of its attributes.
     If a registry is set, will attempt to reuse the canonical instance for its identifier
     
     - parameter dictionaryValue: The attributes
     - parameter useRegistry: Whether we should attempt to canonicalize models and register new ones
     - parameter configure: A closure to configure a deserialized model, taking a Bool flag indicating whether it was newly instantiated (vs. reused from registry)
     */
    public class func fromDictionaryValue(dictionaryValue:AttributeDictionary, useRegistry:Bool = true, configure:((Model,Bool) -> Void)?=nil) -> Self? {
        var instance = (self.instanceClassForDictionaryValue(dictionaryValue) ?? self).init()
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
    
    public func afterInit()     { }
    public func afterCreate()   { }
    public func beforeSave()    { }
    public func afterDelete()   { }
    
    public func cascadeDelete(cascade: ((Model)->Void), inout seenModels: Set<Model>) {
        self.visitAllFields(action: { field in
            if let modelField = field as? ModelFieldType where modelField.cascadeDelete {
                if let model = modelField.anyObjectValue as? Model {
                    cascade(model)
                } else if let models = modelField.anyObjectValue as? [Model] {
                    for model in models {
                        cascade(model)
                    }
                }
            }
        }, seenModels: &seenModels)
    }
    
    // MARK: FieldModel
    
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
    public func defaultFieldsForDictionaryValue() -> [FieldType] {
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
            self.initializeField(field)
            if let modelField = field as? ModelFieldType {
                modelField.model = self
            }
        }
    }
    
    /**
     Performs any model-level field initialization your class may need, before any field values are set.
     */
    public func initializeField(field:FieldType) {
    }
    
    public required override init() {
        super.init()
        self.processFields()
        self.afterInit()
    }
    
    public func visitAllFields(recursive recursive:Bool = true, action:(FieldType -> Void)) {
        var seenModels: Set<Model> = Set()
        self.visitAllFields(recursive: recursive, action: action, seenModels: &seenModels)
    }
    
    public func visitAllFields(recursive recursive:Bool = true, action:(FieldType -> Void), inout seenModels:Set<Model>) {
        guard !seenModels.contains(self) else { return }
        
        seenModels.insert(self)
        
        for (_, field) in self.fields {
            
            action(field)
            
            if recursive {
                if let value = field.anyObjectValue as? Model {
                    value.visitAllFields(recursive: recursive, action: action, seenModels: &seenModels)
                } else if let values = field.anyObjectValue as? NSArray {
                    for value in values {
                        if let model = value as? Model {
                            model.visitAllFields(recursive: recursive, action: action, seenModels: &seenModels)
                        }
                    }
                }
            }
        }
    }

    public func visitAllFieldValues(recursive recursive:Bool = true, action:(Any? -> Void)) {
        var seenModels: Set<Model> = Set()
        self.visitAllFieldValues(recursive: recursive, action: action, seenModels: &seenModels)
}

    public func visitAllFieldValues(recursive recursive:Bool = true, action:(Any? -> Void), inout seenModels:Set<Model>) {
        guard !seenModels.contains(self) else { return }

        seenModels.insert(self)

        for (_, field) in self.fields {
            
            action(field.anyValue)
            
            if recursive {
                if let value = field.anyObjectValue as? Model {
                    value.visitAllFieldValues(recursive: recursive, action: action, seenModels: &seenModels)
                } else if let value = field.anyValue, let values = value as? NSArray {
                    // I'm not sure why I can't cast to [Any]
                    // http://stackoverflow.com/questions/26226911/how-to-tell-if-a-variable-is-an-array
                    
                    for value in values {
                        action(value)
                        if let modelValue = value as? Model {
                            modelValue.visitAllFieldValues(recursive: recursive, action: action, seenModels: &seenModels)
                        }
                    }
                }
            }
        }
    }
    
    /**
     Converts this object to its dictionary representation, optionally limited to a subset of its fields.  By default, it will 
     export all fields in `defaultFieldsForDictionaryValue`, which itself defaults to all fields.
     
     - parameter fields: An array of field objects (belonging to this model) to be included in the dictionary value.
     - parameter explicitNull: Whether nil values should be serialized as NSNull. Note that if this is false, dictionary.keys will not include those with nil values.
     - parameter includeField: A closure determining whether a field should be included in the result.  By default, it will be included iff its state is .Set (i.e., it has been explicitly set since it was loaded)
     */
    public func dictionaryValue(fields fields:[FieldType]?=nil, explicitNull: Bool = false, includeField: ((FieldType) -> Bool)?=nil) -> AttributeDictionary {
        var seenFields:[FieldType] = []
        var includeField = includeField
        if includeField == nil {
            includeField = { $0.state == .Set }
        }
        return self.dictionaryValue(fields: fields, seenFields: &seenFields, explicitNull: explicitNull, includeField: includeField)
    }
    
    internal func dictionaryValue(fields fields:[FieldType]?=nil, inout seenFields: [FieldType], explicitNull: Bool = false, includeField: ((FieldType) -> Bool)?=nil) -> AttributeDictionary {
        let fields = fields ?? self.defaultFieldsForDictionaryValue()
        
        var result:AttributeDictionary = [:]
        let include = fields
        for (_, field) in self.fields {
            if include.contains({ $0 === field }) && includeField?(field) != false {
                field.writeToDictionary(&result, seenFields: &seenFields, explicitNull: explicitNull)
            }
        }
        return result
    }
    
    /**
     Read field values from a dictionary representation.  If a field's key is missing from the dictionary,
     but the field is included in the fields to be imported, its value will be set to nil.
     
     - parameter dictionaryValue: The dictionary representation of this model's new field values.
     - parameter fields: An array of field objects whose values are to be found in the dictionary
     */
    public func setDictionaryValue(dictionaryValue: AttributeDictionary, fields:[FieldType]?=nil) {
        let fields = (fields ?? self.defaultFieldsForDictionaryValue())
        for (_, field) in self.fields {
            if fields.contains({ $0 === field }) {
                field.readFromDictionary(dictionaryValue)
            }
        }
    }
    
    /**
     The default dictionary representation of this model.
     
     If you want to customize the input/output, override `dictionaryValue(fields:)` and/or `setDictionaryValue(_:fields:)`.
     */
    public final var dictionaryValue:AttributeDictionary {
        get {
            return self.dictionaryValue()
        }
        set {
            self.setDictionaryValue(newValue)
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
    
    // MARK: Validation
    
    public func addError(keyPath path:String, message:String) {
        if let field = self.fieldForKeyPath(path) {
            field.addValidationError(message)
        }
    }
    
    /**
     Test whether this model passes validation.  All fields will have their validation states updated.
     
     By default, related models are not themselves validated.  Use the `requireValid()` method on those fields for deeper validation.
     */
    public func validate() -> ValidationState {
        self.resetValidationState()
        var messages: [String] = []
        
        self.visitAllFields(recursive: false) { field in
            if case .Invalid(let fieldMessages) = field.validate() {
                messages.appendContentsOf(fieldMessages)
            }
        }
        
        if messages.count == 0 {
            return .Valid
        } else {
            return .Invalid(messages)
        }
    }
    
    public func resetValidationState() {
        self.visitAllFields { $0.resetValidationState() }
    }

}