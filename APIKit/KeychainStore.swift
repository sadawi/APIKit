//
//  KeychainStore.swift
//  APIKit
//
//  Created by Sam Williams on 11/10/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import PromiseKit

public class KeychainStore: DataStore {
    public var delegate:DataStoreDelegate?
    
    public func create(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
        }
    }
    
    public func update(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
        }
    }
    
    public func delete(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
        }
    }
    
    public func lookup<T : Model>(modelClass: T.Type, identifier: String) -> Promise<T> {
        return Promise { fulfill, reject in
        }
    }
    
    
}
