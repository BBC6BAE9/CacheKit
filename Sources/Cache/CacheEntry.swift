//
//  CacheEntry.swift
//  VLCDemo
//
//  Created by huanghong on 2023/12/27.
//

import Foundation

final class CacheEntry<V> {
    // MARK: Lifecycle

    public init(key: String, value: V, expiredTimestamp: Date) {
        self.key = key
        self.value = value
        self.expiredTimestamp = expiredTimestamp
    }

    // MARK: Internal

    let key: String
    let value: V
    let expiredTimestamp: Date

    public func isCacheExpired(after date: Date = .now) -> Bool {
        date > expiredTimestamp
    }
}

extension CacheEntry: Codable where V: Codable {}
