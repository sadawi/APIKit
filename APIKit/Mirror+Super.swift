//
//  Mirror+Super.swift
//  Pods
//
//  Created by Sam Williams on 12/9/15.
//
//

import Foundation

extension Mirror {
    func eachChild(_ iterator: ( (Child) -> Void )) {
        if let mirror = self.superclassMirror {
            mirror.eachChild(iterator)
        }
        
        for child in self.children {
            iterator(child)
        }
    }
}
