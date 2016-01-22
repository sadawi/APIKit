//
//  Server.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation
import PromiseKit

enum Operation {
    case Any
    case Create
    case Read
    case Update
    case Delete
}

let DataStoreErrorDomain = "DataStore"

public protocol DataStore {
    /**
     Inserts a record.  May give the object an identifier.
     // TODO: Decide on strict id semantics.  Do we leave an existing identifier alone, or replace it with a new one?
     The returned object should be a new instance, different from the provided one.
     */
    func create<T:Model>(model:T) -> Promise<T>
    
    /**
     Updates an existing record
     */
    func update<T:Model>(model:T) -> Promise<T>
    
    /**
     Deletes a record.
     TODO: cascade
     */
    func delete<T:Model>(model:T) -> Promise<T>
    
    /**
     Retrieves a record with the specified identifier.  The Promise should fail if the record can't be found.
     */
    func lookup<T: Model>(modelClass:T.Type, identifier:String) -> Promise<T>
    
    var delegate:DataStoreDelegate? { get set }
}

public protocol ListableDataStore {
    /**
     Retrieves a list of all models of the specified type.
     */
    func list<T: Model>(modelClass:T.Type) -> Promise<[T]>
    
    // TODO: delete all from a class
}

public extension DataStore {
    /**
     Determines whether a model has been persisted to this data store.
     
     This version is very dumb and just checks for the presence of an identifier.
     But the signature is Promise-based, so a DataStore implementation might actually do something asynchronous here.
     */
    public func containsModel(model:Model) -> Promise<Bool> {
        return Promise(model.identifier != nil)
    }
    
    /**
     Upsert.  Creates a new record or updates an existing one, depending on whether we think it's been persisted.
     */
    public func save(model:Model) -> Promise<Model> {
        return self.containsModel(model).then { result in
            return result ? self.update(model) : self.create(model)
        }
    }
}

func <<(left:DataStore, right:Model) -> Promise<Model> {
    return left.save(right)
}

