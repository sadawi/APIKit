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
    
    public override init() {
        super.init(importAction: { value in
            if let value = value as? AttributeDictionary {
                return T.fromDictionaryValue(value)
            } else {
                return nil
            }
            },
            exportAction: { value in
            // Why do I have to cast it to Model?  T is already a Model.
            if let value = value as? Model {
                return value.dictionaryValue
            } else {
                return nil
                }
            }
        )
    }
    
}

public class ModelForeignKeyValueTransformer<T: Model>: ValueTransformer<T> {
    
    public override init() {
        super.init(importAction: { value in
            // Attempt to initialize an object with just an id value
            let dummy = T()
            if let idField = dummy.identifierField, idKey = idField.key, value = value {
                let attributes = [idKey: value]
                let model = T.fromDictionaryValue(attributes) { model, isNew in
                    // We only know it's definitely a shell if it wasn't reused from an existing model
                    if isNew {
                        model.shell = true
                    }
                }
                return model
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