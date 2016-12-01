//
//  ModelValueTransformer.swift
//  Pods
//
//  Created by Sam Williams on 12/8/15.
//
//

import Foundation
import MagneticFields

open class ModelValueTransformer<T: Model>: MagneticFields.ValueTransformer<T> {
    
    public required init() {
        super.init()
    }

    open override func importValue(_ value: AnyObject?) -> T? {
        // TODO: conditionally casting to AttributeDictionary might be slowish
        if let value = value as? AttributeDictionary {
            return T.fromDictionaryValue(value)
        } else {
            return nil
        }
    }
    
    open override func exportValue(_ value: T?, explicitNull: Bool = false) -> AnyObject? {
        var seenFields: [FieldType] = []
        return self.exportValue(value, seenFields: &seenFields, explicitNull: explicitNull)
    }

    open func exportValue(_ value: T?, fields: [FieldType]?=nil, seenFields: inout [FieldType], explicitNull: Bool = false) -> AnyObject? {
        // Why do I have to cast it to Model?  T is already a Model.
        if let value = value as? Model {
            return value.dictionaryValue(fields: fields, seenFields: &seenFields, explicitNull: explicitNull) as AnyObject
        } else {
            return type(of: self).nullValue(explicit: explicitNull)
        }
    }
}

open class ModelForeignKeyValueTransformer<T: Model>: MagneticFields.ValueTransformer<T> {
    public required override init() {
        super.init(importAction: { value in
            
            // Normally we'd check for null by simply trying to cast to the correct type, but only a model instance knows the type of its identifier field.
            if let value = value , !ModelForeignKeyValueTransformer<T>.valueIsNull(value) {
                
                // Attempt to initialize an object with just an id value
                let dummy = Model.prototypeForType(T.self)
                if let idField = dummy.identifierField, let idKey = idField.key {
                    let attributes = [idKey: value]
                    let model = T.fromDictionaryValue(attributes) { model, isNew in
                        // We only know it's definitely a shell if it wasn't reused from an existing model
                        if isNew {
                            model.shell = true
                        }
                    }
                    return model
                }
            }
            return nil
            },
            exportAction: { value in
                if let value = value as? Model {
                    return value.identifierField?.anyObjectValue
                } else {
                    return nil
                }
            }
        )
    }
    
}
