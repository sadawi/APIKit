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
    
    public func validate() -> Bool {
        self.resetValidationState()
        
        var allValid = true
        self.visitAllFields { field in
            // Make sure to call validate() on each field (don't short circuit if false)
            let valid = (field.validate() == .Valid)
            
            allValid = allValid && valid
        }
        return allValid
    }
    
    public func resetValidationState() {
        self.visitAllFields { $0.resetValidationState() }
    }
    
}
