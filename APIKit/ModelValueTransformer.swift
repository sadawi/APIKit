//
//  ModelValueTransformer.swift
//  Pods
//
//  Created by Sam Williams on 12/8/15.
//
//

import Foundation
import MagneticFields

public class ModelValueTransformer<T: Model>: ValueTransformer<T> {
    
    public required init() {
        super.init()
    }

    public override func importValue(value: AnyObject?) -> T? {
        // TODO: conditionally casting to AttributeDictionary might be slowish
        if let value = value as? AttributeDictionary {
            return T.fromDictionaryValue(value)
        } else {
            return nil
        }
    }
    
    public override func exportValue(value: T?, explicitNull: Bool = false) -> AnyObject? {
        var seenFields: [FieldType] = []
        return self.exportValue(value, seenFields: &seenFields, explicitNull: explicitNull)
    }

    public func exportValue(value: T?, fields: [FieldType]?=nil, inout seenFields: [FieldType], explicitNull: Bool = false) -> AnyObject? {
        // Why do I have to cast it to Model?  T is already a Model.
        if let value = value as? Model {
            return value.dictionaryValue(fields: fields, seenFields: &seenFields, explicitNull: explicitNull)
        } else {
            return self.dynamicType.nullValue(explicit: explicitNull)
        }
    }
}

public class ModelForeignKeyValueTransformer<T: Model>: ValueTransformer<T> {
    public required init() {
        super.init(importAction: { value in
            
            // Normally we'd check for null by simply trying to cast to the correct type, but only a model instance knows the type of its identifier field.
            if let value = value where !ModelForeignKeyValueTransformer<T>.valueIsNull(value) {
                
                // Attempt to initialize an object with just an id value
                let dummy = Model.prototypeForType(T.self)
                if let idField = dummy.identifierField, idKey = idField.key {
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