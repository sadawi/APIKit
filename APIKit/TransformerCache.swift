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

extension ValueTransformer {
    static var sharedInstance: ValueTransformer<T> {
        if let existing = TransformerCache.transformers[self] as? ValueTransformer<T> {
            return existing
        } else {
            let newInstance = ValueTransformer<T>()
            TransformerCache.transformers[self] = newInstance
            return newInstance
        }
    }
}