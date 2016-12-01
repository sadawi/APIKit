//
//  Server.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation
import PromiseKit
import MagneticFields

enum Operation {
    case any
    case create
    case read
    case update
    case delete
}

let DataStoreErrorDomain = "DataStore"

public protocol DataStore {
    /**
     Inserts a record.  May give the object an identifier.
     // TODO: Decide on strict id semantics.  Do we leave an existing identifier alone, or replace it with a new one?
     The returned object should be a new instance, different from the provided one.
     */
    func create<T:Model>(_ model: T, fields: [FieldType]?) -> Promise<T>
    
    /**
     Updates an existing record
     */
    func update<T:Model>(_ model: T, fields: [FieldType]?) -> Promise<T>
    
    /**
     Deletes a record.
     */
    func delete<T:Model>(_ model:T) -> Promise<T>
    
    /**
     Retrieves a record with the specified identifier.  The Promise should fail if the record can't be found.
     */
    func lookup<T: Model>(_ modelClass:T.Type, identifier:String) -> Promise<T>
    
    var delegate:DataStoreDelegate? { get set }
}

public protocol ListableDataStore {
    /**
     Retrieves a list of all models of the specified type.
     */
    func list<T: Model>(_ modelClass:T.Type) -> Promise<[T]>
}

public protocol ClearableDataStore {
    /**
     Removes all stored instances of a model class, without fetching them.
     */
    func deleteAll<T: Model>(_ modelClass:T.Type) -> Promise<Void>
    func deleteAll() -> Promise<Void>
}

public extension DataStore {
    /**
     Determines whether a model has been persisted to this data store.
     
     This version is very dumb and just checks for the presence of an identifier.
     But the signature is Promise-based, so a DataStore implementation might actually do something asynchronous here.
     */
    public func containsModel(_ model:Model) -> Promise<Bool> {
        return Promise(value: model.identifier != nil)
    }
    
    func create<T:Model>(_ model:T) -> Promise<T> {
        return self.create(model, fields: nil)
    }
    
    public func update<T:Model>(_ model: T) -> Promise<T> {
        return self.update(model, fields: nil)
    }

    
    /**
     Upsert.  Creates a new record or updates an existing one, depending on whether we think it's been persisted.
     */
    public func save(_ model:Model, fields:[FieldType]?=nil) -> Promise<Model> {
        return self.containsModel(model).then(on: .global()) { (result:Bool) -> Promise<Model> in
            if result {
                return self.update(model, fields: fields)
            } else {
                return self.create(model, fields: fields)
            }
        }
    }
}

func <<(left:DataStore, right:Model) -> Promise<Model> {
    return left.save(right)
}

