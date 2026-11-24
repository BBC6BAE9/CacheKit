package io.github.bbc6bae9.cachekit

import java.io.File
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

interface Cache<V : Any> {
    /** Lifetime in seconds, measured from insertion. */
    val expirationInterval: Double
    fun setValue(value: V?, forKey: String)
    fun value(forKey: String): V?
    fun removeValue(forKey: String)
    fun removeAllValues()
}

@Serializable
internal data class CacheEntry<V>(val key: String, val value: V, val expiredTimestamp: Double)

// Foundation's default JSON date encoding counts seconds from 2001-01-01 UTC.
private const val FOUNDATION_EPOCH_SECONDS = 978307200.0

open class InMemoryCache<V : Any> internal constructor(
    final override val expirationInterval: Double,
    private val nowMillis: () -> Long,
) : Cache<V> {
    constructor(expirationInterval: Double) : this(expirationInterval, System::currentTimeMillis)

    private val entries = mutableMapOf<String, CacheEntry<V>>()
    private fun now() = nowMillis() / 1000.0 - FOUNDATION_EPOCH_SECONDS

    @Synchronized
    final override fun setValue(value: V?, forKey: String) {
        if (value == null) entries.remove(forKey)
        else entries[forKey] = CacheEntry(forKey, value, now() + expirationInterval)
    }

    @Synchronized
    final override fun value(forKey: String): V? {
        val entry = entries[forKey] ?: return null
        if (now() <= entry.expiredTimestamp) return entry.value
        entries.remove(forKey)
        return null
    }

    @Synchronized
    final override fun removeValue(forKey: String) { entries.remove(forKey) }

    @Synchronized
    final override fun removeAllValues() { entries.clear() }

    internal fun liveEntries(): List<CacheEntry<V>> {
        val cutoff = now()
        entries.values.removeAll { cutoff > it.expiredTimestamp }
        return entries.values.toList()
    }

    internal fun mergeEntries(restored: List<CacheEntry<V>>) {
        for (entry in restored) entries[entry.key] = entry
    }
}

/** Pass context.cacheDir as directory. Call disk operations on an IO dispatcher. */
class DiskCache<V : Any>(
    directory: File,
    filename: String,
    expirationInterval: Double,
    serializer: KSerializer<V>,
) : InMemoryCache<V>(expirationInterval) {
    init { require(filename.isNotBlank() && File(filename).name == filename) }
    private val file = File(directory, "$filename.cache")
    private val format = Json { ignoreUnknownKeys = true }
    private val entriesSerializer = ListSerializer(CacheEntry.serializer(serializer))

    @Synchronized
    fun saveToDisk() {
        val data = format.encodeToString(entriesSerializer, liveEntries())
        val path = file.toPath().toAbsolutePath()
        val temporary = Files.createTempFile(path.parent, ".cachekit-", ".tmp")
        try {
            temporary.toFile().writeText(data)
            Files.move(temporary, path, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING)
        } finally {
            Files.deleteIfExists(temporary)
        }
    }

    @Synchronized
    fun loadFromDisk() {
        val restored = format.decodeFromString(entriesSerializer, file.readText())
        mergeEntries(restored)
    }
}
