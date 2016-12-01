//
//  ArchiveDataStore.swift
//  Pods
//
//  Created by Sam Williams on 2/13/16.
//
//

import Foundation
import PromiseKit

enum ArchiveError: Error {
    case noPath
    case unarchiveError
    case archiveError
    case directoryError
}

private let kDefaultGroup = ""

open class ArchiveDataStore: ListableDataStore, ClearableDataStore {
    open static let sharedInstance = ArchiveDataStore()

    
    /**
     Unarchives the default group of instances of a model class.  This will not include any lists of this model class 
     that were saved with a group name.
     */
    open func list<T : Model>(_ modelClass: T.Type) -> Promise<[T]> {
        return self.list(modelClass, group: kDefaultGroup)
    }

    /**
     Unarchives a named group of instances of a model class.
     
     - parameter modelClass: The model class to unarchive.
     - parameter group: An identifier for the group
     */
    open func list<T : Model>(_ modelClass: T.Type, group: String) -> Promise<[T]> {
        let results = self.unarchive(modelClass, suffix: group)
        return Promise(value: results)
    }
    
    fileprivate func accumulateRelatedModels(_ models: [Model], suffix: String) -> [String:[Model]] {
        var registry:[String:[Model]] = [:]
        
        let add = { (model:Model?) -> () in
            guard let model = model else { return }
            
            let key = self.keyForClass(type(of: model)) + suffix
            var existing:[Model]? = registry[key]
            if existing == nil {
                existing = []
                registry[key] = existing!
            }
            existing!.append(model)
            registry[key] = existing!
        }
        
        for model in models {
            add(model)
            
            for relatedModel in model.foreignKeyModels() {
                add(relatedModel)
            }
        }
        
        return registry
    }
    
    /**
     Archives a collection of instances, replacing the previously archived collection.  A group name may be provided, which 
     identifies a named set of instances that can be retrieved separately from the default group.
     
     - parameter modelClass: The class of models to be archived
     - parameter models: The list of models to be archived
     - parameter group: A specific group name identifying this model list.
     - parameter includeRelated: Whether the entire object graph should be archived.
     */
    open func saveList<T: Model>(_ modelClass:T.Type, models: [T], group: String="", includeRelated: Bool = false) -> Promise<Void> {
        guard let _ = self.createdDirectory() else { return Promise(error: ArchiveError.directoryError) }
        
        let registry = self.accumulateRelatedModels(models, suffix: group)
        
        for (key, models) in registry {
            _ = self.archive(models, key: key)
        }
        return Promise<Void>(value: ())
        
    }

    open func deleteAll() -> Promise<Void> {
        let filemanager = FileManager.default
        if let directory = self.directory() {
            do {
                try filemanager.removeItem(atPath: directory)
                return Promise<Void>(value: ())
            } catch let error {
                return Promise(error: error)
            }
        } else {
            return Promise(error: ArchiveError.noPath)
        }
    }
    
    open func deleteAll<T : Model>(_ modelClass: T.Type) -> Promise<Void> {
        return self.deleteAll(modelClass, group: kDefaultGroup)
    }
    
    open func deleteAll<T : Model>(_ modelClass: T.Type, group suffix: String) -> Promise<Void> {
        let key = self.keyForClass(modelClass) + suffix
        
        if let path = self.pathForKey(key) {
            let filemanager = FileManager.default
            do {
                try filemanager.removeItem(atPath: path)
                return Promise<Void>(value: ())
            } catch let error {
                return Promise(error: error)
            }
        } else {
            return Promise(error: ArchiveError.noPath)
        }
    }
    
    /**
     Loads all instances of a class, and recursively unarchives all classes of related (shell) models.
     */
    fileprivate func unarchive<T: Model>(_ modelClass: T.Type, suffix: String, keysToIgnore:NSMutableSet=NSMutableSet()) -> [T] {
        let key = self.keyForClass(modelClass) + suffix
        
        if !keysToIgnore.contains(key) {
            keysToIgnore.add(key)
            
            if let path = self.pathForKey(key) {
                let unarchived = NSKeyedUnarchiver.unarchiveObject(withFile: path)
                if let dictionaries = unarchived as? [AttributeDictionary] {
                    let models = dictionaries.map { modelClass.fromDictionaryValue($0) }.flatMap { $0 }
                    for model in models {
                        for shell in model.shells() {
                            self.unarchive(type(of: shell), suffix: suffix, keysToIgnore: keysToIgnore)
                        }
                    }
                    return models
                }
            }
        }
        
        return []
    }
    
    fileprivate func archive<T: Model>(_ models: [T], key: String) -> Bool {
        if let path = self.pathForKey(key) {
            let dictionaries = models.map { $0.dictionaryValue() }
            if NSKeyedArchiver.archiveRootObject(dictionaries, toFile: path) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    func keyForClass(_ cls: AnyClass) -> String {
        return cls.description()
    }
    
    func directory() -> String? {
        if let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last as NSString? {
            return path.appendingPathComponent("archives")
        } else {
            return nil
        }
    }
    
    func createdDirectory() -> String? {
        guard let path = self.directory() else { return nil }
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            return path
        } catch {
            return nil
        }
    }
    
    func pathForKey(_ key: String) -> String? {
        return (self.directory() as NSString?)?.appendingPathComponent(key)
    }
}
