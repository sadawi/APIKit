//
//  Routable.swift
//  APIKit
//
//  Created by Sam Williams on 11/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

public protocol Routable {
    static var collectionPath:String? { get }
    var identifier:String? { get }
}

extension Routable {
    
    /**
        Generates a RESTful path component for a single model using its identifier.
    
        Example: "users/42"
    */
    public var path:String? {
        get {
            if let id = self.identifier, let collectionPath = self.dynamicType.collectionPath {
                return "\(collectionPath)/\(id)"
            } else {
                return nil
            }
        }
    }
    
    public static var hasCollectionPath: Bool {
        return self.collectionPath != nil
    }
}