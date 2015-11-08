//
//  Model.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

class Model {
    var identifier:String?
    
    var persisted:Bool {
        get {
            return self.identifier != nil
        }
    }
}