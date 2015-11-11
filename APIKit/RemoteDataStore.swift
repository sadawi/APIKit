//
//  RemoteServer.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Alamofire
import PromiseKit

public class RemoteDataStore: DataStore, ListableDataStore {
    public var baseURL:NSURL
    public var delegate:DataStoreDelegate?

    public init(baseURL:NSURL) {
        self.baseURL = baseURL
    }
    
    // MARK: - Helpers
    
    /**
        Parameter message: A localized error message
    
        Returns: An immediately failing promise
    */
    private func errorPromise<T:Model>(message:String) -> Promise<T> {
        return Promise(error: NSError(domain: DataStoreErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
    }

    /**
        Converts a Promise of type Response<AttributeDictionary> to a promise of type Model (or a subclass of Model).
        That is, it takes a Promise that will return an API response containing a raw attribute dictionary, and wraps
        it with logic that extracts the attribute dict and instantiates a model.
    
        - Parameter modelClass: The Model subclass to be instantiated
        - Parameter operation: A Promise that performs some operation and delivers an attribute dictionary representation of a model
        - Returns: A Promise yielding a Model instance
    */
    public func modelOperation<T:Model>(modelClass:T.Type, operation:Promise<Response<AttributeDictionary>>) -> Promise<T>{
        return Promise { fulfill, reject in
            operation.then { (response:Response<AttributeDictionary>) -> () in
                if let value=response.data, model = self.deserializeModel(modelClass, parameters: value) {
                    fulfill(model)
                } else {
                    var error = NSError(domain: DataStoreErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not deserialize model"])
                    self.handleError(&error)
                    reject(error)
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
    
    public func defaultHeaders() -> [String:String] {
        return [:]
    }
    
    public func serializeModel(model:Model) -> AttributeDictionary {
        return model.dictionaryValue
    }
    
    public func deserializeModel<T:Model>(modelClass:T.Type, parameters:AttributeDictionary) -> T? {
        var deserialized = modelClass.fromDictionaryValue(parameters)
        if let id = deserialized?.identifier, canonical = self.delegate?.dataStore(self, canonicalObjectForIdentifier:id) as? T {
            deserialized = canonical
            (deserialized as? Model)?.dictionaryValue = parameters
        }
        return deserialized
    }
    
    public func handleError(inout error:NSError) {
        // Override
    }
    
    /**
        Retrieves the data payload from the Alamofire response and attempts to cast it to the correct type.
    
        Override this to allow for an intermediate "data" key, for example.
    
        Note: T is only specified by type inference from the return value.
    
        - Parameter apiResponse: The JSON response object from an Alamofire request
        - Returns: A Response object with its payload cast to the specified type
    */
    public func constructResponse<T>(apiResponse:Alamofire.Response<AnyObject,NSError>) -> Response<T>? {
        let response = Response<T>()
        response.data = apiResponse.result.value as? T
        return response
    }


    // MARK: - Generic requests
    
    /**
        The core request method, basically a Promise wrapper around an Alamofire.request call
        Parameterized by the T, the expected data payload type (typically either a dictionary or an array of dictionaries)
    
        TODO: At the moment T is only specified by type inference from the return value, which is awkward since it's a promise.
        Consider specifying as a param.
    
        TODO: I might want to yield an intermediate response struct instead of just the bare T instance.  It could contain metadata like
        pagination information, etc.
    
        - Returns: A Promise parameterized by the data payload type of the response
    */
    public func request<T>(method:Alamofire.Method, path:String, parameters:AttributeDictionary?=nil, headers:[String:String]=[:]) -> Promise<Response<T>> {
        let headers = self.defaultHeaders() + headers
        return Promise { fulfill, reject in
            Alamofire.request(method, self.url(path: path), parameters: parameters, encoding: ParameterEncoding.JSON, headers: headers).responseJSON { response in
                switch response.result {
                case .Success:
                    if let value:Response<T> = self.constructResponse(response) {
                        fulfill(value)
                    } else {
                        var error = NSError(domain: DataStoreErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response value"])
                        self.handleError(&error)
                        reject(error)
                    }
                case .Failure(var error):
                    self.handleError(&error)
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
    
    public func list<T: Model>(modelClass:T.Type, parameters:AttributeDictionary?) -> Promise<[T]> {
        return Promise { fulfill, reject in
            self.request(.GET, path: modelClass.path, parameters: parameters).then { (response:Response<[AttributeDictionary]>) -> () in
                // TODO: any of the individual models could fail to deserialize, and we're just silently ignoring them.
                // Not sure what the right behavior should be.
                if let values = response.data {
                    let models = values.map{ self.deserializeModel(modelClass, parameters: $0) }.flatMap{$0}
                    fulfill(models)
                } else {
                    fulfill([])
                }
                }.error { error in
                    reject(error)
            }
        }
    }
}