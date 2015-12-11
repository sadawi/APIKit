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