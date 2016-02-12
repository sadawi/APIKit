//
//  RequestEncoder.swift
//  APIKit
//
//  Created by Sam Williams on 1/21/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//
// http://stackoverflow.com/questions/27794918/sending-array-of-dictionaries-with-alamofire

import Foundation

public class ParameterEncoder {
    public var escapeStrings: Bool = false
    public var includeNullValues: Bool = false
    public var nullString = ""
    
    public init(escapeStrings: Bool = false, includeNullValues:Bool = false) {
        self.escapeStrings = escapeStrings
        self.includeNullValues = includeNullValues
    }
    
    public func encodeParameters(object: AnyObject, prefix: String! = nil) -> String {
        if let dictionary = object as? [String: AnyObject] {
            var results:[String] = []
            
            for (key, value) in dictionary {
                if !self.valueIsNull(value) || self.includeNullValues {
                    results.append(self.encodeParameters(value, prefix: prefix != nil ? "\(prefix)[\(key)]" : key))
                }
            }
            return results.joinWithSeparator("&")
        } else if let array = object as? [AnyObject] {
            let results = array.enumerate().map { (index, value) -> String in
                return self.encodeParameters(value, prefix: prefix != nil ? "\(prefix)[\(index)]" : "\(index)")
            }
            return results.joinWithSeparator("&")
        } else {
            let string = self.encodeValue(object)
            return prefix != nil ? "\(prefix)=\(string)" : "\(string)"
        }
    }
    
    public func encodeValue(value: AnyObject) -> String {
        var string:String
        if self.valueIsNull(value) {
            string = self.encodeNullValue()
        } else {
            string = "\(value)"
        }
        if self.escapeStrings {
            string = self.escape(string)
        }
        return string
    }
    
    public func valueIsNull(value: AnyObject?) -> Bool {
        return value == nil || (value as? NSNull == NSNull())
    }
    
    public func encodeNullValue() -> String {
        return self.nullString
    }
    
    public func escape(string: String) -> String {
        return string.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) ?? ""
    }
}