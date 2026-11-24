//
//  CacheEntry.swift
//  VLCDemo
//
//  Created by huanghong on 2023/12/27.
//

import Foundation

/// A generic cache entry that stores a value with an associated key and expiration timestamp.
public final class CacheEntry<V> {
    // MARK: Lifecycle

    /// Creates a new cache entry.
    /// - Parameters:
    ///   - key: The unique identifier for the cached value
    ///   - value: The value to be cached
    ///   - expiredTimestamp: The date when the cache entry expires
    public init(key: String, value: V, expiredTimestamp: Date) {
        self.key = key
        self.value = value
        self.expiredTimestamp = expiredTimestamp
    }

    // MARK: Internal

    /// The unique identifier for the cached value
    let key: String
    
    /// The cached value
    let value: V
    
    /// The timestamp when the cache entry expires
    let expiredTimestamp: Date

    /// Checks if the cache entry has expired.
    /// - Parameter date: The date to check against (defaults to current date)
    /// - Returns: `true` if the cache entry has expired, `false` otherwise
    func isCacheExpired(after date: Date = Date()) -> Bool {
        date > expiredTimestamp
    }
}

extension CacheEntry: Codable where V: Codable {
    private enum CodingKeys: String, CodingKey {
        case key, value, expiredTimestamp
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(value, forKey: .value)
        try container.encode(expiredTimestamp, forKey: .expiredTimestamp)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = try container.decode(String.self, forKey: .key)
        let value = try container.decode(V.self, forKey: .value)
        let expiredTimestamp = try container.decode(Date.self, forKey: .expiredTimestamp)
        self.init(key: key, value: value, expiredTimestamp: expiredTimestamp)
    }
}
