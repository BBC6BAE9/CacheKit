//
//  CacheEntry.swift
//  VLCDemo
//
//  Created by huanghong on 2023/12/27.
//

import Foundation

public final class CacheEntry<V> {
    // MARK: Lifecycle

    init(key: String, value: V, expiredTimestamp: Date) {
        self.key = key
        self.value = value
        self.expiredTimestamp = expiredTimestamp
    }

    // MARK: Internal

    let key: String
    let value: V
    let expiredTimestamp: Date

    func isCacheExpired(after date: Date = Date()) -> Bool {
        date > expiredTimestamp
    }
    
}

extension CacheEntry: Codable where V: Codable {}
