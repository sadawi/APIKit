//
//  CompoundDataStore.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import PromiseKit

class CompoundDataStore {
    var dataStores:[DataStore] = []
    
    init(dataStores:[DataStore]) {
        self.dataStores = dataStores
    }
    
    // Override this to customize how each model class is looked up
    func dataStoresForModelClass<T:Model>(modelClass:T.Type, operation:Operation) -> [DataStore] {
        return self.dataStores
    }
    
    func create(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
            
        }
    }
    func update(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
            
        }
    }
    func delete(model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
            
        }
    }
    func lookup<T: Model>(modelClass:T.Type, identifier:String) -> Promise<T?> {
        return Promise { fulfill, reject in
            
        }
    }
    func list<T: Model>(modelClass:T.Type) -> Promise<[T]> {
        return Promise { fulfill, reject in
            
        }
    }

}
