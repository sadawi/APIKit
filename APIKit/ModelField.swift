//
//  ModelField.swift
//  APIKit
//
//  Created by Sam Williams on 12/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation
import MagneticFields

public protocol ModelFieldType: FieldType {
    var model: Model? { get set }
    var foreignKey:Bool { get set }

    func inverseValueRemoved(value: Model?)
    func inverseValueAdded(value: Model?)
}

public class ModelField<T: Model>: Field<T>, ModelFieldType {
    public var foreignKey:Bool = false
    public weak var model: Model?
    private var _inverse: (T->ModelFieldType)?
    
    public init(value:T?=nil, name:String?=nil, priority:Int=0, key:String?=nil, foreignKey:Bool=false, inverse: (T->ModelFieldType)?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
        self.foreignKey = foreignKey
        self._inverse = inverse
    }
    
    public override func defaultValueTransformer() -> ValueTransformer<T> {
        return self.foreignKey ? ModelForeignKeyValueTransformer<T>() : ModelValueTransformer<T>()
    }
    
    public func inverse(model:T) -> ModelFieldType? {
        return self._inverse?(model)
    }
    
    public override func valueUpdated(oldValue oldValue:T?, newValue: T?) {
        super.valueUpdated(oldValue: oldValue, newValue: newValue)
        
        if oldValue != newValue {
            if let value = oldValue {
                let inverseField = self.inverse(value)
                inverseField?.inverseValueRemoved(self.model)
            }
            if let value = newValue {
                let inverseField = self.inverse(value)
                inverseField?.inverseValueAdded(self.model)
            }
        }
    }
    
    public func requireValid() -> Self {
        return self.require(message: "Value is invalid", allowNil:true) { value in
            return value.validate().isValid
        }
    }
    
    // MARK: - ModelFieldType
    
    public func inverseValueAdded(value: Model?) {
        if let value = value as? T {
            self.value = value
        }
    }
    
    public func inverseValueRemoved(value: Model?) {
        self.value = nil
    }
    
    var modelValue: Model? {
        return self.value
    }
    
    
    public override func writeUnseenValueToDictionary(inout dictionary: [String : AnyObject], inout seenFields: [FieldType], key: String) {
        if let modelValueTransformer = self.valueTransformer() as? ModelValueTransformer<T> {
            dictionary[key] = modelValueTransformer.exportValue(self.value, seenFields: &seenFields)
        } else { 
            super.writeUnseenValueToDictionary(&dictionary, seenFields: &seenFields, key: key)
        }
    }
    
    public override func writeSeenValueToDictionary(inout dictionary: [String : AnyObject], inout seenFields: [FieldType], key: String) {
        // Only writes the identifier field, if it exists
        if let identifierField = self.value?.identifierField, let modelValueTransformer = self.valueTransformer() as? ModelValueTransformer<T> {
            dictionary[key] = modelValueTransformer.exportValue(self.value, fields: [identifierField], seenFields: &seenFields)
        }
    }
}

public class ModelArrayField<T: Model>: ArrayField<T>, ModelFieldType {
    public weak var model: Model?
    private var _inverse: (T->ModelFieldType)?
    public var foreignKey: Bool = false
    
    public override var value:[T]? {
        didSet {
            let oldValues = oldValue ?? []
            let newValues = self.value ?? []
            
            let (removed, added) = oldValues.symmetricDifference(newValues)
            
            for value in removed {
                self.valueRemoved(value)
            }
            for value in added {
                self.valueAdded(value)
            }
            self.valueUpdated(oldValue: oldValue, newValue: self.value)
        }
    }
    
    public init(_ field:ModelField<T>, value:[T]?=[], name:String?=nil, priority:Int=0, key:String?=nil, inverse: (T->ModelFieldType)?=nil) {
        super.init(field, value: value, name: name, priority: priority, key: key)
        self.foreignKey = field.foreignKey
        self._inverse = inverse ?? field._inverse
    }

    public override func valueRemoved(value: T) {
        self.inverse(value)?.inverseValueRemoved(self.model)
    }
    
    public override func valueAdded(value: T) {
        self.inverse(value)?.inverseValueAdded(self.model)
    }
    
    public func inverse(model:T) -> ModelFieldType? {
        return self._inverse?(model)
    }
    
    // MARK: - ModelFieldType
    
    public func inverseValueAdded(value: Model?) {
        if let value = value as? T {
            self.append(value)
        }
    }
    
    public func inverseValueRemoved(value: Model?) {
        if let value = value as? T {
            self.removeFirst(value)
        }
    }
    
    var modelValue: [Model]? {
        return self.value
    }

}

public prefix func *<T:Model>(right:ModelField<T>) -> ModelArrayField<T> {
    return ModelArrayField<T>(right)
}
