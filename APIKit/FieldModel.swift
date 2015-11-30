//
//  FieldModel.swift
//  Pods
//
//  Created by Sam Williams on 11/27/15.
//
//

import Foundation
import MagneticFields

public class FieldModel: Model {
    public func fields() -> [String:FieldType] {
        var result:[String:FieldType] = [:]
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let label = child.label, value = child.value as? FieldType {
                result[label] = value
            }
        }
        return result
    }
    
    public override var dictionaryValue:AttributeDictionary {
        get {
            var result:AttributeDictionary = [:]
            for (name, field) in self.fields() {
                var resultValue = field.anyObjectValue
                if let value = resultValue as? DictionarySerializable {
                    resultValue = value.dictionaryValue
                }
                result[name] = resultValue
            }
            return result
        }
        set {
        }
    }
}