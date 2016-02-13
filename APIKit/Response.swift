//
//  Response.swift
//  APIKit
//
//  Created by Sam Williams on 11/11/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation


public class Response<DataType>: DictionarySerializable {
    public var data: DataType?
    public var successful:Bool = true
    public var error:ErrorType?

    required public init() {
    }
}