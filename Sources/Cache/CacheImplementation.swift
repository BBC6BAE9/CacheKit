//
//  CacheImplementation.swift
//  VLCDemo
//
//  Created by huanghong on 2023/12/27.
//

import Foundation

private protocol NSCacheType: Cache {
    var cache: NSCache<NSString, CacheEntry<V>> { get }
    var keysTracker: KeysTracker<V> { get }
}

public actor InMemoryCache<V>: NSCacheType {
    // MARK: Lifecycle

    public init(expirationInterval: TimeInterval) {
        self.expirationInterval = expirationInterval
    }

    // MARK: Internal

    let expirationInterval: TimeInterval

    // MARK: Fileprivate

    fileprivate let cache: NSCache<NSString, CacheEntry<V>> = .init()
    fileprivate let keysTracker: KeysTracker<V> = .init()
}

public actor DiskCache<V: Codable>: NSCacheType {
    // MARK: Lifecycle

    public init(filename: String, expirationInterval: TimeInterval) {
        self.filename = filename
        self.expirationInterval = expirationInterval
    }

    // MARK: Internal

    let filename: String
    let expirationInterval: TimeInterval

    public func saveToDisk() throws {
        let entries = keysTracker.keys.compactMap(entry)
        let data = try JSONEncoder().encode(entries)
        try data.write(to: saveLocationURL)
    }
    
    public func loadFromDisk() throws {
        let data = try Data(contentsOf: saveLocationURL)
        let entries = try JSONDecoder().decode([CacheEntry<V>].self, from: data)
        entries.forEach { insert($0) }
    }
    
    // MARK: Fileprivate

    fileprivate let cache: NSCache<NSString, CacheEntry<V>> = .init()
    fileprivate let keysTracker: KeysTracker<V> = .init()

    // MARK: Private

    private var saveLocationURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(filename).cache")
    }
}

extension NSCacheType {
    public func removeValue(forKey key: String) {
        keysTracker.keys.remove(key)
        cache.removeObject(forKey: key as NSString)
    }
    
    public func removeAllValues() {
        keysTracker.keys.removeAll()
        cache.removeAllObjects()
    }
    
    public func setValue(_ value: V?, forKey key: String) {
        if let value {
            let expiredTimestamp = Date().addingTimeInterval(expirationInterval)
            let cacheEntry = CacheEntry(key: key, value: value, expiredTimestamp: expiredTimestamp)
            insert(cacheEntry)
        } else {
            removeValue(forKey: key)
        }
    }
    
    public func value(forKey key: String) -> V? {
        entry(forKey: key)?.value
    }
    
    public func entry(forKey key: String) -> CacheEntry<V>? {
        guard let entry = cache.object(forKey: key as NSString) else {
            return nil
        }
        
        guard !entry.isCacheExpired(after: Date()) else {
            removeValue(forKey: key)
            return nil
        }
        
        return entry
    }
    
    public func insert(_ entry: CacheEntry<V>) {
        keysTracker.keys.insert(entry.key)
        cache.setObject(entry, forKey: entry.key as NSString)
    }
}
