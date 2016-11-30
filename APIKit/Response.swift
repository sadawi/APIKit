//
//  Response.swift
//  APIKit
//
//  Created by Sam Williams on 11/11/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation


open class Response<DataType>: DictionarySerializable {
    open var data: DataType?
    open var successful:Bool = true
    open var error:Error?

    required public init() {
    }
}
