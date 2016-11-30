//
//  CompoundDataStore.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import PromiseKit
import MagneticFields

class CompoundDataStore {
    var dataStores:[DataStore] = []
    
    init(dataStores:[DataStore]) {
        self.dataStores = dataStores
    }
    
    // Override this to customize how each model class is looked up
    func dataStoresForModelClass<T:Model>(_ modelClass:T.Type, operation:Operation) -> [DataStore] {
        return self.dataStores
    }

    func create(_ model: Model, fields: [FieldType]?) -> Promise<Model> {
        return Promise { fulfill, reject in
            
        }
    }
    func update(_ model: Model, fields: [FieldType]?) -> Promise<Model> {
        return Promise { fulfill, reject in
            
        }
    }
    func delete(_ model: Model) -> Promise<Model> {
        return Promise { fulfill, reject in
            
        }
    }
    func lookup<T: Model>(_ modelClass:T.Type, identifier:String) -> Promise<T?> {
        return Promise { fulfill, reject in
            
        }
    }
    func list<T: Model>(_ modelClass:T.Type) -> Promise<[T]> {
        return Promise { fulfill, reject in
            
        }
    }

}
