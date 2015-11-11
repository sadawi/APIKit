//
//  OAuthManager.swift
//  APIKit
//
//  Created by Sam Williams on 11/10/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

class OAuthManager {
    static let sharedInstance = OAuthManager()
    
    var dataStore:DataStore = KeychainStore()
}
