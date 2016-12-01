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

open class MemoryDataStore: DataStore, ListableDataStore, ClearableDataStore {
    open static let sharedInstance = MemoryDataStore()
    
    // of the form [class name: [id: Model]]
    fileprivate var data: NSMutableDictionary = NSMutableDictionary()
    open var delegate:DataStoreDelegate?
    
    fileprivate func keyForClass<T: Model>(_ modelClass: T.Type) -> String {
        return String(describing: modelClass)
    }
    fileprivate func keyForModel(_ model:Model) -> String? {
        return model.identifier
    }
    
    fileprivate func collectionForClass<T: Model>(_ modelClass: T.Type, create:Bool=false) -> NSMutableDictionary? {
        let key = self.keyForClass(modelClass)
        var collection = self.data[key] as? NSMutableDictionary
        if collection == nil && create {
            collection = NSMutableDictionary()
            self.data[key] = collection
        }
        return collection
    }
    
    func generateIdentifier() -> String {
        return UUID().uuidString
    }
    
    // TODO: think more about how to safely create identifiers, when the ID field can be arbitrary type.
    open func create<T:Model>(_ model: T, fields: [FieldType]?) -> Promise<T> {
        return Promise { fulfill, reject in
            let id = self.generateIdentifier()
            model.identifier = id
            self.collectionForClass(type(of: (model as Model)), create: true)![id] = model
            fulfill(model)
        }
    }
    open func update<T:Model>(_ model: T, fields: [FieldType]?) -> Promise<T> {
        return Promise { fulfill, reject in
            fulfill(self.updateImmediately(model))
        }
    }
    open func delete<T:Model>(_ model: T) -> Promise<T> {
        var seenModels = Set<Model>()
        return self.delete(model, seenModels: &seenModels)
    }
    
    @discardableResult open func delete<T:Model>(_ model: T, seenModels: inout Set<Model>) -> Promise<T> {
        return Promise { fulfill, reject in
            if let id=self.keyForModel(model), let collection = self.collectionForClass(type(of: (model as Model))) {
                collection.removeObject(forKey: id)
                model.afterDelete()
                model.cascadeDelete({ self.delete($0, seenModels: &seenModels) }, seenModels: &seenModels)
            }
            // TODO: probably should reject when not deleted
            fulfill(model)
        }
    }
    
    open func deleteAll<T : Model>(_ modelClass: T.Type) -> Promise<Void> {
        let key = self.keyForClass(modelClass)
        self.data.removeObject(forKey: key)
        return Promise<Void>(value: ())
    }
    
    open func deleteAll() -> Promise<Void> {
        self.data.removeAllObjects()
        return Promise<Void>(value: ())
    }
    
    /**
        A synchronous variant of lookup that does not return a promise.
    */
    open func lookupImmediately<T: Model>(_ modelClass:T.Type, identifier:String) -> T? {
        let collection = self.collectionForClass(modelClass)
        return collection?[identifier] as? T
    }

    @discardableResult open func updateImmediately<T: Model>(_ model: T) -> T {
        // store in the collection just to be safe
        if let id = model.identifier {
            // casting model to Model to avoid weird Swift (?) bug (see [1] at top of file)
            self.collectionForClass(type(of: (model as Model)), create: true)![id] = model
        }
        return model
    }
    
    open func lookup<T: Model>(_ modelClass:T.Type, identifier:String) -> Promise<T> {
        return Promise { fulfill, reject in
            if let result = self.lookupImmediately(modelClass, identifier: identifier) {
                fulfill(result)
            } else {
                reject(NSError(domain: DataStoreErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Model not found with id \(identifier)"]))
            }
        }
    }

    open func list<T: Model>(_ modelClass:T.Type) -> Promise<[T]> {
        return Promise { fulfill, reject in
            if let items = self.collectionForClass(modelClass)?.allValues as? [T] {
                fulfill(items)
            } else {
                fulfill([])
            }
        }
    }

}
