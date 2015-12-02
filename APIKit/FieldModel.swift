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
    
    public func fieldForKeyPath(path:String) -> FieldType? {
        // TODO: nested keypaths
        return self.fields()[path]
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
    
    public override func prepareForSave() {
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