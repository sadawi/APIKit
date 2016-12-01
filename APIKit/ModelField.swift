//
//  ModelField.swift
//  APIKit
//
//  Created by Sam Williams on 12/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation
import MagneticFields

public enum DeleteBehavior {
    case nullify
    case delete
}

public protocol ModelFieldType: FieldType {
    var model: Model? { get set }
    var foreignKey:Bool { get set }
    var cascadeDelete: Bool { get }

    func inverseValueRemoved(_ value: Model?)
    func inverseValueAdded(_ value: Model?)
}

open class ModelField<T: Model>: Field<T>, ModelFieldType {
    open var foreignKey:Bool = false
    open weak var model: Model?
    
    open var cascadeDelete: Bool = true
    
    fileprivate var _inverse: ((T)->ModelFieldType)?
    
    public init(value:T?=nil, name:String?=nil, priority:Int=0, key:String?=nil, foreignKey:Bool=false, inverse: ((T)->ModelFieldType)?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
        self.foreignKey = foreignKey
        self._inverse = inverse
    }
    
    open override func defaultValueTransformer() -> MagneticFields.ValueTransformer<T> {
        return self.foreignKey ? ModelForeignKeyValueTransformer<T>.sharedInstance : ModelValueTransformer<T>.sharedInstance
    }
    
    open func inverse(_ model:T) -> ModelFieldType? {
        return self._inverse?(model)
    }
    
    open override func valueUpdated(oldValue:T?, newValue: T?) {
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
    
    open func requireValid() -> Self {
        return self.require(message: "Value is invalid", allowNil:true) { value in
            return value.validate().isValid
        }
    }
    
    // MARK: - ModelFieldType
    
    open func inverseValueAdded(_ value: Model?) {
        if let value = value as? T {
            self.value = value
        }
    }
    
    open func inverseValueRemoved(_ value: Model?) {
        self.value = nil
    }
    
    var modelValue: Model? {
        return self.value
    }
    
    
    open override func writeUnseenValue(to dictionary: inout [String : AnyObject], seenFields: inout [FieldType], key: String, explicitNull: Bool = false) {
        if let modelValueTransformer = self.valueTransformer() as? ModelValueTransformer<T> {
            dictionary[key] = modelValueTransformer.exportValue(self.value, seenFields: &seenFields, explicitNull: explicitNull)
        } else { 
            super.writeUnseenValue(to: &dictionary, seenFields: &seenFields, key: key, explicitNull: explicitNull)
        }
    }
    
    open override func writeSeenValue(to dictionary: inout [String : AnyObject], seenFields: inout [FieldType], key: String) {
        // Only writes the identifier field, if it exists
        if let identifierField = self.value?.identifierField, let modelValueTransformer = self.valueTransformer() as? ModelValueTransformer<T> {
            dictionary[key] = modelValueTransformer.exportValue(self.value, fields: [identifierField], seenFields: &seenFields)
        }
    }
}

open class ModelArrayField<T: Model>: ArrayField<T>, ModelFieldType {
    open weak var model: Model?
    fileprivate var _inverse: ((T)->ModelFieldType)?
    open var foreignKey: Bool = false
    open var cascadeDelete: Bool = true

    open override var value:[T]? {
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
    
    public init(_ field:ModelField<T>, value:[T]?=[], name:String?=nil, priority:Int=0, key:String?=nil, inverse: ((T)->ModelFieldType)?=nil) {
        super.init(field, value: value, name: name, priority: priority, key: key)
        self.foreignKey = field.foreignKey
        self._inverse = inverse ?? field._inverse
    }

    open override func valueRemoved(_ value: T) {
        self.inverse(value)?.inverseValueRemoved(self.model)
    }
    
    open override func valueAdded(_ value: T) {
        self.inverse(value)?.inverseValueAdded(self.model)
    }
    
    open func inverse(_ model:T) -> ModelFieldType? {
        return self._inverse?(model)
    }
    
    // MARK: - ModelFieldType
    
    open func inverseValueAdded(_ value: Model?) {
        if let value = value as? T {
            self.append(value)
        }
    }
    
    open func inverseValueRemoved(_ value: Model?) {
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
