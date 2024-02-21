//
//  Cache.swift
//  VLCDemo
//
//  Created by huanghong on 2023/12/27.
//

import Foundation

protocol Cache: Actor {
    associatedtype V
    var expirationInterval: TimeInterval { get }

    func setValue(_ value: V?, forKey key: String)
    func value(forKey key: String) -> V?

    func removeValue(forKey key: String)
    func removeAllValues()
}
