//
//  MockServer.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//
/**

Notes: 
[1]
    There's a weird bug where doing things with model.dynamicType gives EXC_BAD_ACCESS on the device, but not simulator.
    Other people have seen it: http://ambracode.com/index/show/1013298

    Replacing `model` with `(model as Model)` seems to fix it.
*/

import Foundation
import PromiseKit
import MagneticFields

public class MemoryDataStore: DataStore, ListableDataStore, ClearableDataStore {
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
    public func create<T:Model>(model: T, fields: [FieldType]?) -> Promise<T> {
        return Promise { fulfill, reject in
            let id = self.generateIdentifier()
            model.identifier = id
            self.collectionForClass((model as Model).dynamicType, create: true)![id] = model
            fulfill(model)
        }
    }
    public func update<T:Model>(model: T, fields: [FieldType]?) -> Promise<T> {
        return Promise { fulfill, reject in
            fulfill(self.updateImmediately(model))
        }
    }
    public func delete<T:Model>(model: T) -> Promise<T> {
        var seenModels = Set<Model>()
        return self.delete(model, seenModels: &seenModels)
    }
    
    public func delete<T:Model>(model: T, inout seenModels: Set<Model>) -> Promise<T> {
        return Promise { fulfill, reject in
            if let id=self.keyForModel(model), let collection = self.collectionForClass((model as Model).dynamicType) {
                collection.removeObjectForKey(id)
                model.afterDelete()
                model.cascadeDelete({ self.delete($0, seenModels: &seenModels) }, seenModels: &seenModels)
            }
            // TODO: probably should reject when not deleted
            fulfill(model)
        }
    }
    
    public func deleteAll<T : Model>(modelClass: T.Type) -> Promise<Void> {
        let key = self.keyForClass(modelClass)
        self.data.removeObjectForKey(key)
        return Promise<Void>()
    }
    
    public func deleteAll() -> Promise<Void> {
        self.data.removeAllObjects()
        return Promise<Void>()
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
            // casting model to Model to avoid weird Swift (?) bug (see [1] at top of file)
            self.collectionForClass((model as Model).dynamicType, create: true)![id] = model
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
                fulfill([])
            }
        }
    }

}