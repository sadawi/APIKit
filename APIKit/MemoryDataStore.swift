//
//  MockServer.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation
import PromiseKit

class MemoryDataStore: DataStore {
    // of the form [class name: [id: Model]]
    private var data: NSMutableDictionary = NSMutableDictionary()
    
    private func keyForClass<T: Model>(modelClass: T.Type) -> String {
        return String(modelClass)
    }
    
    private func collectionForClass<T: Model>(modelClass: T.Type, create:Bool=false) -> NSMutableDictionary {
        let key = self.keyForClass(modelClass)
        var collection = self.data[key] as? NSMutableDictionary
        if collection == nil {
            collection = NSMutableDictionary()
            self.data[key] = collection
        }
        return collection!
    }
    
    func generateIdentifier() -> String {
        return NSUUID().UUIDString
    }
    
    func create(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
            let id = self.generateIdentifier()
            model.identifier = id
            self.collectionForClass(model.dynamicType, create: true)[id] = model
            fulfill(model)
        }
    }
    func update(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
            // no-op since it's already in memory
//            return fulfill()
        }
    }
    func delete(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
            
        }
    }
    func lookup<T:Model>(modelClass:T.Type, identifier:String) -> Promise<T?> {
        return Promise { fulfill, reject in
            let collection = self.collectionForClass(modelClass)
            if let result = collection[identifier] as? T {
                fulfill(result)
            }
        }
    }

    func list<T: Model>(modelClass:T.Type) -> Promise<[T]> {
        return Promise { fulfill, reject in
            if let items = self.collectionForClass(modelClass).allValues as? [T] {
                fulfill(items)
            } else {
                reject(NSError(domain: "Data", code: 0, userInfo: nil)) // TODO: better error
            }
        }
    }

}


//class MockServer: DataStore {
//    private var resources: [String:[[String:Any]]] = [:]
//    private var getRoutes: [String:Any] = [:]
//    
//    var identifierKey = "id"
//    
//    func addResources(name: String, values: [[String:Any]]) {
//        self.resources[name] = values
//        self.route(name, method:"GET") { [weak self] in
//            return self?.resources[name]
//        }
//        for value in values {
//            if let id = value[self.identifierKey] {
//                let path = "\(name)/\(id)"
//                self.route(path, method:"GET", value: value)
//            }
//        }
//    }
//    
////    func getResources(name: String, completion: [[String:Any]] -> () ) {
////        completion(self.resources[name] ?? [])
////    }
//    
//    func route(path:String, method:String, value:Any) {
//        
//    }
//    
//    func get(path:String, completion: Any -> () ) {
//        if let value = self.getRoutes[path] {
//            completion(value)
//        }
//    }
//    
////    func getResource(name: String, id: String, completion: [String:Any]? -> ()) {
////        if let collection = self.resources[name] {
////            completion(collection[id])
////        } else {
////            completion(nil)
////        }
////    }
//}
//
////class MockServerRouter {
////    var mockServer:MockServer
////    
////    init(mockServer:MockServer) {
////        self.mockServer = mockServer
////    }
////}
//
////func /(left:MockServer, right:String) -> MockServerRouter {
////    let router = MockServerRouter(mockServer: left)
////    return router
////}