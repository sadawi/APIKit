//
//  Routable.swift
//  APIKit
//
//  Created by Sam Williams on 11/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

public protocol Routable {
    static var path:String { get }
    var identifier:String? { get }
    var path:String? { get }
}

extension Routable {
    
    /**
        Generates a RESTful path component for a single model using its identifier.
    
        Example: "users/42"
    */
    public var path:String? {
        get {
            if let id = self.identifier {
                return "\(self.dynamicType.path)/\(id)"
            } else {
                return nil
            }
        }
    }
}