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
        Creates a closure that deserializes a model and returns a Promise.
        Useful in promise chaining as an argument to .then
    
        - Parameter modelClass: The Model subclass to be instantiated
        - Returns: A Promise yielding a Model instance
    */
    public func instantiateModel<T:Model>(modelClass:T.Type) -> (Response<AttributeDictionary> -> Promise<T>){
        return { (response:Response<AttributeDictionary>) in
            if let data = response.data, model = self.deserializeModel(modelClass, parameters: data) {
                return Promise(model)
            } else {
                return self.errorPromise("Could not deserialize model")
            }
        }
    }
    
//    public func handleModelError<T:Model>(modelClass:T.Type) -> 
    
    // MARK: - Helper methods that subclasses might want to override
    
    private func url(path path:String) -> NSURL {
        return self.baseURL.URLByAppendingPathComponent(path)
    }
    
    public func defaultHeaders() -> [String:String] {
        return [:]
    }
    
    public func formatPayload(payload:AttributeDictionary) -> AttributeDictionary {
        return payload
    }
    
    public func serializeModel(model:Model) -> AttributeDictionary {
        return model.dictionaryValue
    }
    
    public func deserializeModel<T:Model>(modelClass:T.Type, parameters:AttributeDictionary) -> T? {
        // TODO: I guess it would be more efficient to lookup the canonical object before instantiating at all.
        // But that requires identifier key knowledge that lives in the model class at the moment.
        
        var deserialized = modelClass.fromDictionaryValue(parameters)
        if let id = deserialized?.identifier {
            // If we have a canonical object for this id, swap it in
            if let canonical = self.delegate?.dataStore(self, canonicalObjectForIdentifier:id, modelClass:modelClass) as? T {
                print("reusing existing model with id \(canonical.identifier)")
                deserialized = canonical
                (deserialized as? Model)?.dictionaryValue = parameters
            } else if let deserialized = deserialized {
                self.delegate?.dataStore(self, didInstantiateModel: deserialized)
            }
        }
        return deserialized
    }
    
    public func handleError(inout error:NSError, model:Model?=nil) {
        // Override
    }
    
    /**
        Retrieves the data payload from the Alamofire response and attempts to cast it to the correct type.
    
        Override this to allow for an intermediate "data" key, for example.
    
        Note: T is only specified by type inference from the return value.
        Note: errors aren't processed from the response.  Subclasses should handle that for a specific API response format.
    
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
    
        - Returns: A Promise parameterized by the data payload type of the response
    */
    public func request<T>(method:Alamofire.Method, path:String, parameters:AttributeDictionary?=nil, headers:[String:String]=[:], model:Model?=nil) -> Promise<Response<T>> {
        let headers = self.defaultHeaders() + headers
        let url = self.url(path: path)
//        let parameters = parameters as? [String:AnyObject]
        return Promise { fulfill, reject in
            Alamofire.request(method, url, parameters: parameters, encoding: ParameterEncoding.URL, headers: headers).responseJSON { response in
//                print("RESPONSE: ", response.result.value)
                switch response.result {
                case .Success:
                    if let value:Response<T> = self.constructResponse(response) {
                        if var error=value.error {
                            // the request might have succeeded, but we found an error when constructing the Response object
                            self.handleError(&error, model:model)
                            reject(error)
                        } else {
                            fulfill(value)
                        }
                    } else {
                        var error = NSError(domain: DataStoreErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response value"])
                        self.handleError(&error)
                        reject(error)
                    }
                case .Failure(var error):
                    self.handleError(&error, model:model)
                    reject(error)
                }
            }
        }
    }
    
    // MARK: - CRUD operations (DataStore protocol methods)

    public func create(model: Model) -> Promise<Model> {
        model.prepareForSave()
        let parameters = self.formatPayload(self.serializeModel(model))
        return self.request(.POST, path: model.dynamicType.path, parameters: parameters, model:model).then(self.instantiateModel(model.dynamicType))
    }
    
    public func update(model: Model) -> Promise<Model> {
        model.prepareForSave()
        if let path = model.path {
            let parameters = self.formatPayload(self.serializeModel(model))
            return self.request(.PATCH, path: path, parameters: parameters, model:model).then(self.instantiateModel(model.dynamicType))
        } else {
            return self.errorPromise("No path for model")
        }
    }
    
    public func delete(model: Model) -> Promise<Model> {
        if let path = model.path {
            return self.request(.DELETE, path: path).then(self.instantiateModel(model.dynamicType))
        } else {
            return self.errorPromise("No path for model")
        }
    }
    
    public func lookup<T: Model>(modelClass:T.Type, identifier:String) -> Promise<T> {
        let model = modelClass.init() as T
        model.identifier = identifier
        if let path = (model as Model).path {
            return self.request(.GET, path: path).then(self.instantiateModel(modelClass))
        } else {
            return self.errorPromise("No path for model")
        }
    }

    public func list<T: Model>(modelClass:T.Type) -> Promise<[T]> {
        return self.list(modelClass, parameters: nil)
    }
    
    public func list<T: Model>(modelClass:T.Type, parameters:[String:AnyObject]?) -> Promise<[T]> {
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