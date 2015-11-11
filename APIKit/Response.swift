//
//  Response.swift
//  APIKit
//
//  Created by Sam Williams on 11/11/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

public class Response<DataType>: DictionarySerializable {
    public var data: DataType?
    
    public required init() {
    }

}