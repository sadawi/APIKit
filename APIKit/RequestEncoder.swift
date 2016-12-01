//
//  RequestEncoder.swift
//  APIKit
//
//  Created by Sam Williams on 1/21/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//
// http://stackoverflow.com/questions/27794918/sending-array-of-dictionaries-with-alamofire

import Foundation

open class ParameterEncoder {
    open var escapeStrings: Bool = false
    open var includeNullValues: Bool = false
    open var nullString = ""
    
    public init(escapeStrings: Bool = false, includeNullValues:Bool = false) {
        self.escapeStrings = escapeStrings
        self.includeNullValues = includeNullValues
    }
    
    open func encodeParameters(_ object: AnyObject, prefix: String? = nil) -> String {
        if let dictionary = object as? [String: AnyObject] {
            var results:[String] = []
            
            for (key, value) in dictionary {
                if !self.valueIsNull(value) || self.includeNullValues {
                    var prefixString: String
                    if let prefix = prefix {
                        prefixString = "\(prefix)[\(key)]"
                    } else {
                        prefixString = key
                    }

                    results.append(self.encodeParameters(value, prefix: prefixString))
                }
            }
            return results.joined(separator: "&")
        } else if let array = object as? [AnyObject] {
            let results = array.enumerated().map { (index, value) -> String in
                var prefixString: String
                if let prefix = prefix {
                    prefixString = "\(prefix)[\(index)]"
                } else {
                    prefixString = "\(index)"
                }
                return self.encodeParameters(value, prefix: prefixString)
            }
            return results.joined(separator: "&")
        } else {
            let string = self.encodeValue(object)
            if let prefix = prefix {
                return "\(prefix)=\(string)"
            } else {
                return "\(string)"
            }
        }
    }
    
    open func encodeValue(_ value: AnyObject) -> String {
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
    
    open func valueIsNull(_ value: AnyObject?) -> Bool {
        return value == nil || (value as? NSNull == NSNull())
    }
    
    open func encodeNullValue() -> String {
        return self.nullString
    }
    
    open func escape(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
    }
}
