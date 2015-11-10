//
//  DataStoreDelegate.swift
//  APIKit
//
//  Created by Sam Williams on 11/9/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

public protocol DataStoreDelegate {
    func dataStore(dataStore:DataStore, didInstantiateModel model:Model)
    func dataStore(dataStore:DataStore, canonicalObjectForIdentifier identifier:String) -> Model?
}