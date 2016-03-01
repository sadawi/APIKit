//
//  KeychainStore.swift
//  APIKit
//
//  Created by Sam Williams on 11/10/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import PromiseKit
import MagneticFields

public class KeychainStore: DataStore {
    public var delegate:DataStoreDelegate?
    
    public init() {
        
    }
    
    public func create<T:Model>(model: T, fields: [FieldType]?) -> Promise<T> {
        return Promise { fulfill, reject in
        }
    }
    
    public func update<T:Model>(model: T, fields: [FieldType]?) -> Promise<T> {
        return Promise { fulfill, reject in
        }
    }
    
    public func delete<T:Model>(model: T) -> Promise<T> {
        return Promise { fulfill, reject in
        }
    }
    
    public func lookup<T : Model>(modelClass: T.Type, identifier: String) -> Promise<T> {
        return Promise { fulfill, reject in
        }
    }
    
    
}
