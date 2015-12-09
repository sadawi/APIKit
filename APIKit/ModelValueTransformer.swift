//
//  ModelValueTransformer.swift
//  Pods
//
//  Created by Sam Williams on 12/8/15.
//
//

import Foundation
import MagneticFields

public class ModelValueTransformer<T: FieldModel>: ValueTransformer<T> {
    public init() {
        super.init(importAction: { value in
            if let value = value as? AttributeDictionary {
                return T.fromDictionaryValue(value)
            } else {
                return nil
            }
            },
            exportAction: { value in
                
            // Why do I have to cast it to FieldModel?  T is already a FieldModel.
            if let value = value as? FieldModel {
                return value.dictionaryValue
            } else {
                return nil
                }
            }
        )
    }
    
}