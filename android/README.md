# CacheKit for Android

Kotlin/JVM library for Android API 26+ and JDK 17. Use Gradle 8.13 with JDK 17 to build. From this directory run `gradle test` or `gradle jar`.

To consume from source, check out CacheKit alongside the Android application. Add this to the application's settings.gradle.kts:

```kotlin
includeBuild("../CacheKit/android")
```

Then add this dependency in the application module:

```kotlin
implementation("io.github.bbc6bae9:cachekit:0.1.0")
```

```kotlin
import io.github.bbc6bae9.cachekit.DiskCache
import io.github.bbc6bae9.cachekit.InMemoryCache
import kotlinx.serialization.builtins.serializer

val memory = InMemoryCache<String>(expirationInterval = 60.0)
memory.setValue("ready", forKey = "status")

val disk = DiskCache(context.cacheDir, "channels", 3600.0, String.serializer())
disk.setValue("news", forKey = "last")
// Run blocking file IO on a background dispatcher.
disk.saveToDisk()
```

Create another DiskCache with the same directory, filename and serializer and call
`loadFromDisk()` to restore. Saving writes a snapshot of live entries. Loading merges
entries by key and preserves their original expiration times. Missing files and
decoding errors propagate to the caller. Each cache instance serializes operations.
Use one writer per file. Android may clear the application's cache directory.

Expiration intervals use seconds. A value remains valid at its exact expiry time.
Setting null removes a key. The JSON envelope uses Swift CacheKit's key, value and
expiredTimestamp fields (seconds since 2001-01-01 UTC). For shared files, use matching
value encodings on both platforms. The Kotlin memory store retains entries until removal,
expiry on access/save, or disposal and has no NSCache-style system eviction.
