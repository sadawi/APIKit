//
//  RemoteServer.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Alamofire
import PromiseKit

public class RemoteDataStore: DataStore {
    var baseURL:NSURL
    
    init(baseURL:NSURL) {
        self.baseURL = baseURL
    }
    
    // MARK: - private helpers
    
    private func errorPromise<T:Model>(message:String) -> Promise<T> {
        return Promise(error: NSError(domain: DataStoreErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
    }
    
    private func modelOperation<T:Model>(modelClass:T.Type, operation:Promise<[String:AnyObject]>) -> Promise<T>{
        return Promise { fulfill, reject in
            operation.then { (value:[String:AnyObject]) -> () in
                if let model = self.deserializeModel(modelClass, parameters: value) {
                    fulfill(model)
                } else {
                    reject(NSError(domain: DataStoreErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not deserialize model"]))
                }
                }.error { error in
                    reject(error)
            }
        }
    }
    
    // MARK: - Helper methods that subclasses might want to override
    
    private func url(path path:String) -> NSURL {
        return self.baseURL.URLByAppendingPathComponent(path)
    }
    
    private func defaultHeaders() -> [String:String] {
        return [:]
    }
    
    private func serializeModel(model:Model) -> [String:AnyObject] {
        return model.dictionaryValue
    }
    
    private func deserializeModel<T:Model>(modelClass:T.Type, parameters:[String:AnyObject]) -> T? {
        return modelClass.fromDictionaryValue(parameters)
    }
    
    // Retrieves the data payload from the Alamofire response and attempts to cast it to the correct type
    // Override this to allow for an intermediate "data" key, for example
    private func extractValueFromResponse<T>(response:Response<AnyObject,NSError>) -> T? {
        return response.result.value as? T
    }


    // MARK: - Generic requests
    
    // The core request method, basically a Promise wrapper around an Alamofire.request call
    // Parameterized by the T, the expected data payload type (typically either a dictionary or an array of dictionaries)
    func request<T>(method:Alamofire.Method, path:String, parameters:[String:AnyObject]?=nil, headers:[String:String]=[:]) -> Promise<T> {
        let headers = self.defaultHeaders() + headers
        return Promise { fulfill, reject in
            Alamofire.request(method, self.url(path: path), parameters: parameters, encoding: ParameterEncoding.JSON, headers: headers).responseJSON { response in
                switch response.result {
                case .Success:
                    if let value:T = self.extractValueFromResponse(response) {
                        fulfill(value)
                    } else {
                        reject(NSError(domain: DataStoreErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response value"]))
                    }
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    // MARK: - CRUD operations

    public func create(model: Model) -> Promise<Model> {
        let parameters = self.serializeModel(model)
        return self.modelOperation(model.dynamicType, operation: self.request(.POST, path: model.dynamicType.path, parameters: parameters))
    }
    
    public func update(model: Model) -> Promise<Model> {
        if let path = model.path {
            let parameters = self.serializeModel(model)
            return self.modelOperation(model.dynamicType, operation: self.request(.PUT, path: path, parameters: parameters))
        } else {
            return self.errorPromise("No path for model")
        }
    }
    
    public func delete(model: Model) -> Promise<Model> {
        if let path = model.path {
            return self.modelOperation(model.dynamicType, operation: self.request(.DELETE, path: path))
        } else {
            return self.errorPromise("No path for model")
        }
    }
    
    public func lookup<T: Model>(modelClass:T.Type, identifier:String) -> Promise<T> {
        let model = modelClass.init() as Model
        model.identifier = identifier
        if let path = model.path {
            return self.modelOperation(modelClass, operation: self.request(.GET, path: path))
        } else {
            return self.errorPromise("No path for model")
        }
    }

    public func list<T: Model>(modelClass:T.Type) -> Promise<[T]> {
        return self.list(modelClass, parameters: nil)
    }
    
    public func list<T: Model>(modelClass:T.Type, parameters:[String:AnyObject]?) -> Promise<[T]> {
        return Promise { fulfill, reject in
            self.request(.GET, path: modelClass.path, parameters: parameters).then { (values:[[String:AnyObject]]) -> () in
                // TODO: any of the individual models could fail to deserialize, and we're just silently ignoring them.
                // Not sure what the right behavior should be.
                let models = values.map{ self.deserializeModel(modelClass, parameters: $0) }.flatMap{$0}
                fulfill(models)
                }.error { error in
                    reject(error)
            }
        }
    }
}