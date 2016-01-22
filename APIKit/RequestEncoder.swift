//
//  RequestEncoder.swift
//  APIKit
//
//  Created by Sam Williams on 1/21/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//
// http://stackoverflow.com/questions/27794918/sending-array-of-dictionaries-with-alamofire

import Foundation

struct RequestEncoder {
    static func encodeParameters(object: AnyObject, prefix: String! = nil) -> String {
        if let dictionary = object as? [String: AnyObject] {
            let results = dictionary.map { (key, value) -> String in
                return self.encodeParameters(value, prefix: prefix != nil ? "\(prefix)[\(key)]" : key)
            }
            return results.joinWithSeparator("&")
        } else if let array = object as? [AnyObject] {
            let results = array.enumerate().map { (index, value) -> String in
                return self.encodeParameters(value, prefix: prefix != nil ? "\(prefix)[\(index)]" : "\(index)")
            }
            return results.joinWithSeparator("&")
        } else {
            let escapedValue = escape("\(object)")
            return prefix != nil ? "\(prefix)=\(escapedValue)" : "\(escapedValue)"
        }
    }
    
    static func escape(string: String) -> String {
        return string.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) ?? ""
    }
}