//
//  OAuth.swift
//  NexTravel
//
//  Created by Sam Williams on 11/6/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import UIKit

public class OAuth: Model {
    public var accessToken:String?
    public var refreshToken:String?
    public var expirationDate:NSDate?
    
    public var expiresIn: NSTimeInterval? {
        set {
            if let value = newValue {
                self.expirationDate = NSDate(timeIntervalSinceNow: value)
            } else {
                self.expirationDate = nil
            }
        }
        get {
            return self.expirationDate?.timeIntervalSinceNow
        }
    }
    public var tokenType: String?
    public var scope: String?

    public var isValid: Bool {
        get {
            if let expiration = self.expiresIn {
                return expiration > 0
            } else {
                return true
            }
        }
    }
    
    override public var dictionaryValue:AttributeDictionary {
        get {
            var result = super.dictionaryValue
            result["accessToken"]       = self.accessToken
            result["refreshToken"]      = self.refreshToken
            result["expirationDate"]    = self.expirationDate
            result["tokenType"]         = self.tokenType
            result["scope"]             = self.scope
            return result
        }
        set {
            super.dictionaryValue = newValue
            
            if let accessToken = newValue["accessToken"] as? String {
                self.accessToken = accessToken
            }

            if let refreshToken = newValue["refreshToken"] as? String {
                self.refreshToken = refreshToken
            }
            
            if let expiresIn = newValue["expiresIn"] as? NSTimeInterval {
                self.expiresIn = expiresIn
            }
            
            if let tokenType = newValue["tokenType"] as? String {
                self.tokenType = tokenType
            }
            
            if let scope = newValue["scope"] as? String {
                self.scope = scope
            }
        }
    }
    
}
