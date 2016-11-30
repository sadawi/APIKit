//
//  DataStoreDelegate.swift
//  APIKit
//
//  Created by Sam Williams on 11/9/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

public protocol DataStoreDelegate {
    func dataStore(_ dataStore:DataStore, didInstantiateModel model:Model)
    func dataStore(_ dataStore:DataStore, canonicalObjectForIdentifier identifier:String, modelClass:AnyClass) -> Model?
}
