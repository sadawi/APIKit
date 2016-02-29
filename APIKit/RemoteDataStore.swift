//
//  RemoteServer.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Alamofire
import PromiseKit
import MagneticFields

public enum RemoteDataStoreError: ErrorType {
    case UnknownError(message: String)
    case DeserializationFailure
    case InvalidResponse
    case NoModelPath(model: Model)
    
    var description: String {
        switch(self) {
        case .DeserializationFailure:
            return "Could not deserialize model"
        case .InvalidResponse:
            return "Invalid response value"
        case .NoModelPath(let model):
            return "No path for model of type \(model.dynamicType)"
        case .UnknownError(let message):
            return message
        }
    }
}

public class RemoteDataStore: DataStore, ListableDataStore {
    public var baseURL:NSURL
    public var delegate:DataStoreDelegate?
    
    public init(baseURL:NSURL) {
        self.baseURL = baseURL
    }
    
    /**
     Creates a closure that deserializes a model and returns a Promise.
     Useful in promise chaining as an argument to .then
     
     - parameter modelClass: The Model subclass to be instantiated
     - returns: A Promise yielding a Model instance
     */
    public func instantiateModel<T:Model>(modelClass:T.Type) -> (Response<AttributeDictionary> -> Promise<T>){
        return { (response:Response<AttributeDictionary>) in
            if let data = response.data, model = self.deserializeModel(modelClass, parameters: data) {
                return Promise(model)
            } else {
                return Promise(error: RemoteDataStoreError.DeserializationFailure)
            }
        }
    }
    
    public func instantiateModels<T:Model>(modelClass:T.Type) -> (Response<[AttributeDictionary]> -> Promise<[T]>) {
        return { (response:Response<[AttributeDictionary]>) in
            // TODO: any of the individual models could fail to deserialize, and we're just silently ignoring them.
            // Not sure what the right behavior should be.
            if let values = response.data {
                let models = values.map { value -> T? in
                    let model:T? = self.deserializeModel(modelClass, parameters: value)
                    return model
                    }.flatMap{$0}
                return Promise(models)
            } else {
                return Promise([])
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
    
    public func serializeModel(model:Model, fields:[FieldType]?=nil) -> AttributeDictionary {
        return model.dictionaryValueWithFields(fields)
    }
    
    public func deserializeModel<T:Model>(modelClass:T.Type, parameters:AttributeDictionary) -> T? {
        // TODO: would rather use value transformer here instead, but T is Model instead of modelClass and it doesn't get deserialized properly
        //        return ModelValueTransformer<T>().importValue(parameters)
        let model = modelClass.fromDictionaryValue(parameters)
        model?.shell = false
        return model
    }
    
    public func handleError(error:ErrorType, model:Model?=nil) {
        // Override
    }
    
    /**
     Retrieves the data payload from the Alamofire response and attempts to cast it to the correct type.
     
     Override this to allow for an intermediate "data" key, for example.
     
     Note: T is only specified by type inference from the return value.
     Note: errors aren't processed from the response.  Subclasses should handle that for a specific API response format.
     
     - parameter apiResponse: The JSON response object from an Alamofire request
     - returns: A Response object with its payload cast to the specified type
     */
    public func constructResponse<T>(apiResponse:Alamofire.Response<AnyObject,NSError>) -> Response<T>? {
        let response = Response<T>()
        response.data = apiResponse.result.value as? T
        return response
    }
    
    
    // MARK: - Generic requests
    
    public func nestedParameterEncoding(method method:Alamofire.Method) -> ParameterEncoding {
        return ParameterEncoding.Custom({ (request:URLRequestConvertible, parameters:[String : AnyObject]?) -> (NSMutableURLRequest, NSError?) in
            let request = request as? NSMutableURLRequest ?? NSMutableURLRequest()
            if let parameters = parameters, url = request.URL {
                if method == .GET {
                    let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
                    components?.query = ParameterEncoder().encodeParameters(parameters)
                    request.URL = components?.URL
                } else {
                    request.HTTPBody = ParameterEncoder().encodeParameters(parameters).dataUsingEncoding(NSUTF8StringEncoding)
                }
            }
            return (request, nil)
        })
    }
    
    public func encodingForMethod(method: Alamofire.Method) -> ParameterEncoding {
        return self.nestedParameterEncoding(method: method)
    }
    
    /**
     A placeholder method in which you can attempt to restore your session (refreshing your oauth token, for example) before each request.
     */
    public func restoreSession() -> Promise<Void> {
        return Promise<Void>()
    }
    
    /**
     The core request method, basically a Promise wrapper around an Alamofire.request call
     Parameterized by the T, the expected data payload type (typically either a dictionary or an array of dictionaries)
     
     TODO: At the moment T is only specified by type inference from the return value, which is awkward since it's a promise.
     Consider specifying as a param.
     
     - returns: A Promise parameterized by the data payload type of the response
     */
    public func request<T>(
        method: Alamofire.Method,
        path: String,
        parameters: AttributeDictionary?=nil,
        headers: [String:String]=[:],
        encoding: ParameterEncoding?=nil,
        model: Model?=nil,
        requireSession: Bool = true
        ) -> Promise<Response<T>> {
            
            let headers = self.defaultHeaders() + headers
            let url = self.url(path: path)
            let encoding = encoding ?? self.encodingForMethod(method)
            
            let action = { () -> Promise<Response<T>> in
                return Promise { fulfill, reject in
                    Alamofire.request(method, url, parameters: parameters, encoding: encoding, headers: headers).responseJSON { response in
                        switch response.result {
                        case .Success:
                            if let value:Response<T> = self.constructResponse(response) {
                                if let error=value.error {
                                    // the request might have succeeded, but we found an error when constructing the Response object
                                    self.handleError(error, model:model)
                                    reject(error)
                                } else {
                                    fulfill(value)
                                }
                            } else {
                                let error = RemoteDataStoreError.InvalidResponse
                                self.handleError(error)
                                reject(error)
                            }
                        case .Failure(let error):
                            self.handleError(error as ErrorType, model:model)
                            reject(error)
                        }
                    }
                }
            }
            
            if requireSession {
                return self.restoreSession().then(action)
            } else {
                return action()
            }
    }
    
    // MARK: - CRUD operations (DataStore protocol methods)

    public func create<T:Model>(model: T, fields: [FieldType]?) -> Promise<T> {
        model.beforeSave()
        let parameters = self.formatPayload(self.serializeModel(model, fields: fields))
        
        // See MemoryDataStore for an explanation [1]
        let modelModel = model as Model
        
        return self.request(.POST, path: modelModel.dynamicType.path, parameters: parameters, model:model).then(self.instantiateModel(modelModel.dynamicType)).then { model in
            model.afterCreate()
            return Promise(model as! T)
        }
    }
    
    public func update<T:Model>(model: T, fields: [FieldType]?) -> Promise<T> {
        model.beforeSave()
        
        let modelModel = model as Model
        
        if let path = modelModel.path {
            let parameters = self.formatPayload(self.serializeModel(model, fields: fields))
            return self.request(.PATCH, path: path, parameters: parameters, model:model).then(self.instantiateModel(modelModel.dynamicType)).then { model in
                // Dancing around to get the type inference to work
                return Promise(model as! T)
            }
        } else {
            return Promise(error: RemoteDataStoreError.NoModelPath(model: model))
        }
    }
    
    public func delete<T:Model>(model: T) -> Promise<T> {
        if let path = (model as Model).path {
            return self.request(.DELETE, path: path).then { (response:Response<T>) -> Promise<T> in
                model.afterDelete()
                return Promise(model)
            }
        } else {
            return Promise(error: RemoteDataStoreError.NoModelPath(model: model))
        }
    }
    
    public func lookup<T: Model>(modelClass:T.Type, identifier:String) -> Promise<T> {
        let model = modelClass.init() as T
        model.identifier = identifier
        if let path = (model as Model).path {
            return self.request(.GET, path: path).then(self.instantiateModel(modelClass))
        } else {
            return Promise(error: RemoteDataStoreError.NoModelPath(model: model))
        }
    }
    
    public func refresh<T:Model>(model:T) -> Promise<T> {
        if let identifier = model.identifier {
            return self.lookup(T.self, identifier: identifier)
        } else {
            return Promise(error: RemoteDataStoreError.NoModelPath(model: model))
        }
    }
    
    public func list<T: Model>(modelClass:T.Type) -> Promise<[T]> {
        return self.list(modelClass, parameters: nil)
    }
    
    /**
     Retrieves a list of models, with customization of the request path and parameters.
     
     - parameter modelClass: The model class to instantiate
     - parameter path: An optional path.  Defaults to modelClass.path
     - parameter parameters: Request parameters to pass along in the request.
     */
    public func list<T: Model>(modelClass:T.Type, path:String?=nil, parameters:[String:AnyObject]?) -> Promise<[T]> {
        return self.request(.GET, path: path ?? modelClass.path, parameters: parameters).then(self.instantiateModels(modelClass))
    }

}