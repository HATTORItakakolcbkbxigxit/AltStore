//
//  AsyncManaged.swift
//  AltStore
//
//  Created by Riley Testut on 10/5/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

import Foundation
import CoreData

@propertyWrapper @dynamicMemberLookup
public struct AsyncManaged<ManagedObject>
{
    public var wrappedValue: ManagedObject {
        didSet {
            self.managedObjectContext = self.managedObject?.managedObjectContext
        }
    }
    
    public var projectedValue: AsyncManaged<ManagedObject> {
        return self
    }
    
    private var managedObjectContext: NSManagedObjectContext?
    private var managedObject: NSManagedObject? {
        return self.wrappedValue as? NSManagedObject
    }
    
    public init(wrappedValue: ManagedObject)
    {
        self.wrappedValue = wrappedValue
        self.managedObjectContext = self.managedObject?.managedObjectContext
    }
}

// Async
extension AsyncManaged
{
    // Multiple values
    public func get<T>(_ closure: @escaping (ManagedObject) -> T) async -> T
    {
        if let context = self.managedObjectContext
        {
            //TODO: Is this safe?
            return try! await context.performAsync {
                closure(self.wrappedValue)
            }
        }
        else
        {
            return closure(self.wrappedValue)
        }
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<ManagedObject, T>) -> T {
        get async {
            guard let context = self.managedObjectContext else {
                return self.wrappedValue[keyPath: keyPath]
            }
            
            //TODO: Safe??
            return try! await context.performAsync {
                return self.wrappedValue[keyPath: keyPath]
            }
        }
    }

    // Optionals
    public subscript<Wrapped, T>(dynamicMember keyPath: KeyPath<Wrapped, T>) -> T? where ManagedObject == Optional<Wrapped> {
        get async {
            guard let context = self.managedObjectContext else {
                return self.wrappedValue?[keyPath: keyPath]
            }
            
            //TODO: Safe??
            return try! await context.performAsync {
                return self.wrappedValue?[keyPath: keyPath]
            }
        }
    }
}
