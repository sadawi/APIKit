//
//  MockServer.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation
import PromiseKit

public class MemoryDataStore: DataStore, ListableDataStore {
    public static let sharedInstance = MemoryDataStore()
    
    // of the form [class name: [id: Model]]
    private var data: NSMutableDictionary = NSMutableDictionary()
    public var delegate:DataStoreDelegate?
    
    private func keyForClass<T: Model>(modelClass: T.Type) -> String {
        return String(modelClass)
    }
    private func keyForModel(model:Model) -> String? {
        return model.identifier
    }
    
    private func collectionForClass<T: Model>(modelClass: T.Type, create:Bool=false) -> NSMutableDictionary? {
        let key = self.keyForClass(modelClass)
        var collection = self.data[key] as? NSMutableDictionary
        if collection == nil && create {
            collection = NSMutableDictionary()
            self.data[key] = collection
        }
        return collection
    }
    
    func generateIdentifier() -> String {
        return NSUUID().UUIDString
    }
    
    // TODO: think more about how to safely create identifiers, when the ID field can be arbitrary type.
    public func create(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
            let id = self.generateIdentifier()
            model.identifier = id
            self.collectionForClass(model.dynamicType, create: true)![id] = model
            fulfill(model)
        }
    }
    public func update(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
            fulfill(self.updateImmediately(model))
        }
    }
    public func delete(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
            if let id=self.keyForModel(model), let collection = self.collectionForClass(model.dynamicType) {
                collection.removeObjectForKey(id)
            }
            // TODO: probably should reject when not deleted
            fulfill(model)
        }
    }
    
    /**
        A synchronous variant of lookup that does not return a promise.
    */
    public func lookupImmediately<T: Model>(modelClass:T.Type, identifier:String) -> T? {
        let collection = self.collectionForClass(modelClass)
        return collection?[identifier] as? T
    }

    public func updateImmediately<T: Model>(model: T) -> T {
        // store in the collection just to be safe
        if let id = model.identifier {
            self.collectionForClass(model.dynamicType, create: true)![id] = model
        }
        return model
    }
    
    public func lookup<T: Model>(modelClass:T.Type, identifier:String) -> Promise<T> {
        return Promise { fulfill, reject in
            if let result = self.lookupImmediately(modelClass, identifier: identifier) {
                fulfill(result)
            } else {
                reject(NSError(domain: DataStoreErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Model not found with id \(identifier)"]))
            }
        }
    }

    public func list<T: Model>(modelClass:T.Type) -> Promise<[T]> {
        return Promise { fulfill, reject in
            if let items = self.collectionForClass(modelClass)?.allValues as? [T] {
                fulfill(items)
            } else {
                reject(NSError(domain: DataStoreErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Error retrieving collection"]))
            }
        }
    }

}