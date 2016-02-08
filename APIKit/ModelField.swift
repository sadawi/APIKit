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
        self.setDefaultValueTransformers()
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
    
    // MARK: - ModelFieldType
    
    public func inverseValueAdded(value: Model?) {
        if let value = value as? T {
            self.value = value
        }
    }
    
    public func inverseValueRemoved(value: Model?) {
        self.value = nil
    }

}