# 🗺 CacheKit

Cache is a lightweight disk caching tool commonly used to store data returned from network requests.

# Quick Start

1、Init cache

```Swift
import Cache

let cache = DiskCache<[YOUR_CODABLE_MODEL]>(filename:"YOUR_FILE_NAME", expirationInterval: 30 * 24 * 60 * 60)
```

2、Write cache to disk

```swift
cache.setValue(channels, forKey: keyString)
try? await cache.saveToDisk()

```

3、Load cache from disk

```Swift
cache.loadFromDisk()
```

4、Remove cache from disk

```swift
cache.removeValue(forKey: keyString)
```

# Class Diagram

```mermaid
classDiagram
    class Cache~V~ {
        <<protocol>>
        +TimeInterval expirationInterval
        +setValue(V?, forKey: String)
        +value(forKey: String) V?
        +removeValue(forKey: String)
        +removeAllValues()
    }

    class NSCacheType~V~ {
        <<protocol>>
        +NSCache~NSString, CacheEntry~V~~ cache
        +KeysTracker~V~ keysTracker
        +setValue(V?, forKey: String)
        +value(forKey: String) V?
        +removeValue(forKey: String)
        +removeAllValues()
        #entry(forKey: String) CacheEntry~V~?
        #insert(CacheEntry~V~)
    }

    class InMemoryCache~V~ {
        +init(expirationInterval: TimeInterval)
        +TimeInterval expirationInterval
        -NSCache~NSString, CacheEntry~V~~ cache
        -KeysTracker~V~ keysTracker
    }

    class DiskCache~V~ {
        +init(filename: String, expirationInterval: TimeInterval)
        +String filename
        +TimeInterval expirationInterval
        +saveToDisk() throws
        +loadFromDisk() throws
        -NSCache~NSString, CacheEntry~V~~ cache
        -KeysTracker~V~ keysTracker
        -URL saveLocationURL
    }

    class CacheEntry~V~ {
        +init(key: String, value: V, expiredTimestamp: Date)
        +String key
        +V value
        +Date expiredTimestamp
        +isCacheExpired(after: Date) Bool
    }

    class KeysTracker~V~ {
        +Set~String~ keys
        +cache(_:willEvictObject:) void
    }

    class NSCache {
        <<Foundation>>
        +setObject(AnyObject?, forKey: AnyObject)
        +object(forKey: AnyObject) AnyObject?
        +removeObject(forKey: AnyObject)
        +removeAllObjects()
    }

    Cache <|.. NSCacheType
    NSCacheType <|.. InMemoryCache
    NSCacheType <|.. DiskCache
    NSCacheType o-- CacheEntry
    NSCacheType o-- KeysTracker
    NSCacheType o-- NSCache
    KeysTracker --|> NSCacheDelegate
    CacheEntry ..|> Codable
```
