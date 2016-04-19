//
//  Model+Validation.swift
//  APIKit
//
//  Created by Sam Williams on 4/5/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation
import MagneticFields

/**
 Validation
 */
public extension Model {
    public func addError(keyPath path:String, message:String) {
        if let field = self.fieldForKeyPath(path) {
            field.addValidationError(message)
        }
    }
    
    /**
     Test whether this model passes validation.  All fields will have their validation states updated.
     
     By default, related models are not themselves validated.  Use the `requireValid()` method on those fields for deeper validation.
     */
    public func validate() -> ValidationState {
        self.resetValidationState()
        var messages: [String] = []
        
        self.visitAllFields(recursive: false) { field in
            if case .Invalid(let fieldMessages) = field.validate() {
                messages.appendContentsOf(fieldMessages)
            }
        }
        
        if messages.count == 0 {
            return .Valid
        } else {
            return .Invalid(messages)
        }
    }
    
    public func resetValidationState() {
        self.visitAllFields { $0.resetValidationState() }
    }
}
