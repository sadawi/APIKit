//
//  Routable.swift
//  APIKit
//
//  Created by Sam Williams on 11/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

protocol Routable {
    static var path:String { get }
    var identifier:String? { get }
    var path:String? { get }
}

extension Routable {
    var path:String? {
        get {
            if let id = self.identifier {
                return "\(self.dynamicType.path)/\(id)"
            } else {
                return nil
            }
        }
    }
}