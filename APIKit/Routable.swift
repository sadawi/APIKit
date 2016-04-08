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
    var path:String? { get }
}

extension Routable {
    public static var hasCollectionPath: Bool {
        return self.collectionPath != nil
    }
}