//
//  CacheImplementation.swift
//  Cache
//
//  Created by huanghong on 2023/12/27.
//

import Foundation

/// A protocol that extends Cache to provide NSCache-specific functionality.
public protocol NSCacheType: Cache {
    /// The underlying NSCache instance.
    var cache: NSCache<NSString, CacheEntry<V>> { get }
    
    /// The key tracker for this cache.
    var keysTracker: KeysTracker<V> { get }
}

/// An in-memory cache implementation using NSCache.
///
/// This cache stores all values in memory and is cleared when the application terminates.
actor InMemoryCache<V>: NSCacheType {
    /// Creates a new in-memory cache.
    /// - Parameter expirationInterval: The time interval after which entries expire.
    init(expirationInterval: TimeInterval) {
        self.expirationInterval = expirationInterval
    }

    /// The time interval after which entries expire.
    let expirationInterval: TimeInterval

    /// The underlying NSCache instance.
    internal let cache: NSCache<NSString, CacheEntry<V>> = .init()
    
    /// The key tracker for this cache.
    internal let keysTracker: KeysTracker<V> = .init()
}

/// A disk-based cache implementation that persists values to the filesystem.
///
/// This cache stores values both in memory and on disk, allowing for persistence
/// between application launches.
public actor DiskCache<V: Codable>: NSCacheType {
    /// Creates a new disk cache.
    /// - Parameters:
    ///   - filename: The name of the file to use for storage.
    ///   - expirationInterval: The time interval after which entries expire.
    public init(filename: String, expirationInterval: TimeInterval) {
        self.filename = filename
        self.expirationInterval = expirationInterval
    }

    /// The filename used for storage.
    let filename: String
    
    /// The time interval after which entries expire.
    public let expirationInterval: TimeInterval

    /// Saves the current cache contents to disk.
    /// - Throws: An error if the save operation fails.
    public func saveToDisk() throws {
        let entries = keysTracker.keys.compactMap(entry)
        let data = try JSONEncoder().encode(entries)
        try data.write(to: saveLocationURL)
    }
    
    /// Loads cache contents from disk.
    /// - Throws: An error if the load operation fails.
    public func loadFromDisk() throws {
        let data = try Data(contentsOf: saveLocationURL)
        let entries = try JSONDecoder().decode([CacheEntry<V>].self, from: data)
        entries.forEach { insert($0) }
    }
    
    /// The underlying NSCache instance.
    public let cache: NSCache<NSString, CacheEntry<V>> = .init()
    
    /// The key tracker for this cache.
    public let keysTracker: KeysTracker<V> = .init()

    /// The URL where the cache file is stored.
    private var saveLocationURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(filename).cache")
    }
}

// Extension methods for NSCacheType
public extension NSCacheType {
    /// Removes a value from the cache.
    /// - Parameter key: The key to remove.
    func removeValue(forKey key: String) {
        keysTracker.keys.remove(key)
        cache.removeObject(forKey: key as NSString)
    }
    
    /// Removes all values from the cache.
    func removeAllValues() {
        keysTracker.keys.removeAll()
        cache.removeAllObjects()
    }
    
    /// Stores a value in the cache.
    /// - Parameters:
    ///   - value: The value to store. If nil, the key will be removed.
    ///   - key: The key to associate with the value.
    func setValue(_ value: V?, forKey key: String) {
        if let value {
            let expiredTimestamp = Date().addingTimeInterval(expirationInterval)
            let cacheEntry = CacheEntry(key: key, value: value, expiredTimestamp: expiredTimestamp)
            insert(cacheEntry)
        } else {
            removeValue(forKey: key)
        }
    }
    
    /// Retrieves a value from the cache.
    /// - Parameter key: The key to look up.
    /// - Returns: The value associated with the key, or nil if no value exists or has expired.
    func value(forKey key: String) -> V? {
        entry(forKey: key)?.value
    }
    
    /// Retrieves a cache entry for the specified key.
    /// - Parameter key: The key to look up.
    /// - Returns: The cache entry, or nil if no entry exists or has expired.
    func entry(forKey key: String) -> CacheEntry<V>? {
        guard let entry = cache.object(forKey: key as NSString) else {
            return nil
        }
        
        guard !entry.isCacheExpired(after: Date()) else {
            removeValue(forKey: key)
            return nil
        }
        
        return entry
    }
    
    /// Inserts a new cache entry.
    /// - Parameter entry: The entry to insert.
    func insert(_ entry: CacheEntry<V>) {
        keysTracker.keys.insert(entry.key)
        cache.setObject(entry, forKey: entry.key as NSString)
    }
}
