//
//  File.swift
//  Pods
//
//  Created by Sam Williams on 11/25/15.
//
//

import Foundation

public enum FieldState {
    case NotLoaded
    case Loading
    case Loaded
    case Error(NSError)
}

public protocol FieldType {
    
}

public protocol FieldObserver:AnyObject {
    func fieldValueChanged(field:FieldType)
}

public class Field<T:Equatable>: FieldType, FieldObserver {
    public var value:T? {
        didSet {
            if oldValue != self.value {
                self.valueChanged()
            }
        }
    }
    public var state:FieldState = .NotLoaded
    public var name:String?
    public var allowedValues:[T] = []
    
    private var observers:NSMutableSet = NSMutableSet()
    private var blockObservers:[(Field<T> -> Void)] = []
    
    public init(value:T?=nil, name:String?=nil, allowedValues:[T]?=nil) {
        self.value = value
        self.name = name
        if let allowedValues = allowedValues {
            self.allowedValues = allowedValues
        }
    }
    
    func valueChanged() {
        for observer in self.observers {
            if let observer = observer as? FieldObserver {
                observer.fieldValueChanged(self)
            }
        }
        for action in self.blockObservers {
            action(self)
        }
    }
    
    public func addObserver(observer:FieldObserver) {
        self.observers.addObject(observer)
    }
    
    public func observe(action:(Field<T> -> Void)) {
        self.blockObservers.append(action)
    }
    
    public func removeObserver(observer:FieldObserver) {
        self.observers.removeObject(observer)
    }
    
    public func fieldValueChanged(field:FieldType) {
        if let observedField = field as? Field<T> {
            self.value = observedField.value
        }
    }
}


infix operator <-- { associativity left precedence 95 }
infix operator --> { associativity left precedence 95 }
infix operator <--> { associativity left precedence 95 }

public func <--<T>(left:Field<T>, right:T?) {
    left.value = right
}

public func <--<T>(left:Field<T>, right:Field<T>) {
    right.addObserver(left)
    left.value = right.value
}

public func --><T>(right:T?, left:Field<T>) {
    left.value = right
}

public func --><T>(left:Field<T>, right:Field<T>) {
    left.addObserver(right)
}

public func <--><T>(left: Field<T>, right: Field<T>) {
    left.addObserver(right)
    right.addObserver(left)
}