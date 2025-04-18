//
//  Cache.swift
//  VLCDemo
//
//  Created by huanghong on 2023/12/27.
//

import Foundation

/// A protocol that defines a thread-safe caching mechanism with expiration support.
///
/// The `Cache` protocol provides a basic interface for storing and retrieving values
/// with an associated key. It inherits from `Actor` to ensure thread safety.
public protocol Cache: Actor {
    /// The type of value that can be stored in the cache.
    associatedtype V
    
    /// The time interval after which cached values expire.
    var expirationInterval: TimeInterval { get }

    /// Stores a value in the cache for the specified key.
    /// - Parameters:
    ///   - value: The value to store. Pass `nil` to remove the value.
    ///   - key: The key to associate with the value.
    func setValue(_ value: V?, forKey key: String)
    
    /// Retrieves a value from the cache for the specified key.
    /// - Parameter key: The key associated with the value.
    /// - Returns: The value associated with the key, or `nil` if no value exists.
    func value(forKey key: String) -> V?

    /// Removes the value associated with the specified key from the cache.
    /// - Parameter key: The key of the value to remove.
    func removeValue(forKey key: String)
    
    /// Removes all values from the cache.
    func removeAllValues()
}
