//
//  TransformerCache.swift
//  APIKit
//
//  Created by Sam Williams on 5/5/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

import MagneticFields

private struct TransformerCache {
    static var transformers = TypeDictionary<ValueTransformerType>()
}

extension MagneticFields.ValueTransformer {
    class var sharedInstance: ValueTransformer {
        if let existing = TransformerCache.transformers[self] as? ValueTransformer {
            return existing
        } else {
            let newInstance = self.init()
            TransformerCache.transformers[self] = newInstance
            return newInstance
        }
    }
}
