# Getting Started with CacheKit

Create and manage efficient disk-based caching for your Apple platform applications.

@Metadata {
    @PageImage(purpose: card, source: "slothPower", alt: "A diagram showing CacheKit's memory and disk caching architecture.")
}

## Overview

CacheKit is a lightweight, thread-safe disk caching framework designed for Apple platforms. It provides robust data persistence capabilities, commonly used to store network responses, user preferences, and other application data that benefits from fast retrieval and offline availability.

Every cache instance has a configurable ``DiskCache/expirationInterval`` and a ``DiskCache/filename`` for disk storage. You can store any `Codable` data type, from simple strings to complex model objects.

![A diagram showing the caching architecture: in-memory NSCache backed by persistent disk storage.](slothPower.png)

### Create a Cache

To create a basic disk cache for storing codable data, initialize a new instance of the ``DiskCache`` structure with a filename and expiration interval:

```swift
import CacheKit

// Cache that expires after 30 days
let userDataCache = DiskCache<UserProfile>(
    filename: "user_profiles", 
    expirationInterval: 30 * 24 * 60 * 60
)
```

For temporary data that doesn't need persistence, you can use the in-memory cache:

```swift
// In-memory cache for session data
let sessionCache = InMemoryCache<SessionData>(
    expirationInterval: 60 * 60 // 1 hour
)
```

If you're working with different data types, you can create specialized caches for each:

```swift
let imageCache = DiskCache<Data>(filename: "images", expirationInterval: 7 * 24 * 60 * 60)
let configCache = DiskCache<AppConfiguration>(filename: "config", expirationInterval: 24 * 60 * 60)
let networkCache = DiskCache<[APIResponse]>(filename: "api_responses", expirationInterval: 30 * 60)
```

### Store and Retrieve Data

CacheKit provides intuitive methods for storing and retrieving cached data. To store a value, use the ``Cache/setValue(_:forKey:)`` method:

```swift
// Store user profile data
let userProfile = UserProfile(name: "John Doe", email: "john@example.com")
await userDataCache.setValue(userProfile, forKey: "current_user")

// Persist to disk
try await userDataCache.saveToDisk()
```

To retrieve cached data, use the ``Cache/value(forKey:)`` method, which automatically handles expiration checking:

```swift
// Retrieve user profile
if let cachedProfile = await userDataCache.value(forKey: "current_user") {
    print("Welcome back, \(cachedProfile.name)!")
} else {
    print("No cached user data found")
}
```

### Load Persisted Cache

When your application starts, you can restore previously cached data from disk. This is particularly useful for maintaining data across app launches:

```swift
// Load cached data on app startup
do {
    try await userDataCache.loadFromDisk()
    print("Cache loaded successfully")
} catch {
    print("Failed to load cache: \(error)")
}
```

### Manage Cache Lifecycle

CacheKit provides comprehensive cache management capabilities. You can remove specific entries or clear the entire cache:

```swift
// Remove a specific cache entry
await userDataCache.removeValue(forKey: "current_user")
try await userDataCache.saveToDisk()

// Clear all cached data
await userDataCache.removeAllValues()
try await userDataCache.saveToDisk()
```

### Handle Cache Expiration

CacheKit automatically manages cache expiration based on the configured ``Cache/expirationInterval``. Expired entries are automatically removed when accessed, ensuring your cache doesn't grow indefinitely:

```swift
// This cache expires entries after 1 hour
let shortTermCache = DiskCache<TemporaryData>(
    filename: "temp_data",
    expirationInterval: 60 * 60
)

// Store data
await shortTermCache.setValue(temporaryData, forKey: "session_token")

// After 1 hour, this will return nil
let expiredData = await shortTermCache.value(forKey: "session_token")
```

### Best Practices

For optimal performance and reliability, consider these best practices:

- Use descriptive filenames that reflect the cached data type
- Set appropriate expiration intervals based on data freshness requirements  
- Always handle potential throwing operations with proper error handling
- Load cache data early in your application lifecycle
- Regularly save important cache changes to disk