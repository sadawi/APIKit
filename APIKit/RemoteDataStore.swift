//
//  RemoteServer.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Alamofire
import PromiseKit

class APIResponse {
    
}

class RemoteDataStore {
    var baseURL:NSURL
    
    init(baseURL:NSURL) {
        self.baseURL = baseURL
    }
    
    private func url(path path:String) -> NSURL {
        return self.baseURL.URLByAppendingPathComponent(path)
    }
    
    private func headers() -> [String:String] {
        return [:]
    }
    
    func request(method:Alamofire.Method, path:String, parameters:[String:AnyObject]=[:]) -> Promise<APIResponse> {
        return Promise { fulfill, reject in
            Alamofire.request(method, self.url(path: path), parameters: parameters, encoding: ParameterEncoding.JSON, headers: self.headers()).responseJSON { response in
                switch response.result {
                case .Success(let value):
                    print(value)
//                    if let value = value as? [String:AnyObject],  apiResponse = APIResponse.fromDictionaryValue(value) {
//                        fulfill(apiResponse)
//                    } else {
//                        reject(NSError(domain: NexTravelErrorDmoain, code: 0, userInfo: nil)) // TODO: better error
//                    }
                case .Failure(let error):
                    reject(error)
                }
            }
        }
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
    func lookup<T: Model>(modelClass:T, identifier:String) -> Promise<T> {
        return Promise { fulfill, reject in
            
        }
    }
    func list<T: Model>(modelClass:T) -> Promise<[T]> {
        return Promise { fulfill, reject in
            
        }
    }
}