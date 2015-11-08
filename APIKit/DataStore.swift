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

protocol DataStore {
    func create(model:Model) -> Promise<Model>
    func update(model:Model) -> Promise<Model>
    func delete(model:Model) -> Promise<Model>
    func lookup<T: Model>(modelClass:T.Type, identifier:String) -> Promise<T?>
    func list<T: Model>(modelClass:T.Type) -> Promise<[T]>
}

extension DataStore {
    func save(model:Model) -> Promise<Model> {
        if model.persisted {
            return self.update(model)
        } else {
            return self.create(model)
        }
    }
}

func <<(left:DataStore, right:Model) {
    left.save(right)
}