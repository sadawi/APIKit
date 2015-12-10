//
//  ModelField.swift
//  APIKit
//
//  Created by Sam Williams on 12/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation
import MagneticFields

public class ModelField<T: Model>: Field<T> {
    public override init(value:T?=nil, name:String?=nil, priority:Int=0, key:String?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
    }
    
    public override func defaultValueTransformer() -> ValueTransformer<T> {
        return ModelValueTransformer<T>()
    }
}

// Not sure about the right hierarchy here.
public class ModelArrayField<T: Model>: ArrayField<T> {
    public override init(value:[T]?=nil, name:String?=nil, priority:Int=0, key:String?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
    }
    
    public override func defaultValueTransformer() -> ValueTransformer<T> {
        return ModelValueTransformer<T>()
    }
}
