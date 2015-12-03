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
    public func addError(keyPath path:String, message:String) {
        if let field = self.fieldForKeyPath(path) {
            field.addValidationError(message)
        }
    }

    public func fieldForKeyPath(components:[String]) -> FieldType? {
        guard components.count > 0 else { return nil }
        
        let fields = self.fields()
        if let firstField = fields[components[0]] {
            let remainingComponents = Array(components[1..<components.count])
            if remainingComponents.count == 0 {
                // No more components.  Just return the field
                return firstField
            } else if let firstValue = firstField.anyValue as? FieldModel {
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
    
    /**
        Look at the instance's fields, do some introspection and processing.
    */
    func processFields() {
        for (key, field) in self.fields() {
            if field.key == nil {
                field.key = key
            }
        }
    }
    
    public required init() {
        super.init()
        self.processFields()
    }
    
    public override func beforeSave() {
        self.resetValidationState()
    }
    
    public func resetValidationState() {
        for (_, field) in self.fields() {
            field.resetValidationState()
        }
    }

//    public override var dictionaryValue:AttributeDictionary {
//        get {
//            var result:AttributeDictionary = [:]
//            for (name, field) in self.fields() {
//                var resultValue = field.anyObjectValue
//                if let value = resultValue as? DictionarySerializable {
//                    resultValue = value.dictionaryValue
//                }
//                result[name] = resultValue
//            }
//            return result
//        }
//        set {
//        }
//    }
}