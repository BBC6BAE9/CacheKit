package io.github.bbc6bae9.cachekit

import java.io.File
import java.io.FileNotFoundException
import java.util.concurrent.Executors
import kotlinx.serialization.SerializationException
import kotlinx.serialization.builtins.serializer
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class CacheTest {
    @get:Rule val folder = TemporaryFolder()
    private fun disk(ttl: Double = 3600.0) = DiskCache(folder.root, "sample", ttl, String.serializer())

    @Test fun expiryIsStrictAndReadsDoNotExtendIt() {
        var clock = 0L
        val cache = InMemoryCache<String>(1.0) { clock }
        cache.setValue("first", "key")
        clock = 1000
        assertEquals("first", cache.value("key"))
        clock++
        assertNull(cache.value("key"))
    }

    @Test fun diskChangesAreExplicitAndLoadMerges() {
        val writer = disk()
        writer.setValue("old", "key")
        writer.saveToDisk()
        writer.setValue("new", "key")
        val reader = disk()
        reader.setValue("local", "other")
        reader.loadFromDisk()
        assertEquals("old", reader.value("key"))
        assertEquals("local", reader.value("other"))
        writer.setValue(null, "key")
        writer.saveToDisk()
        reader.removeAllValues()
        reader.loadFromDisk()
        assertNull(reader.value("key"))
        assertNull(reader.value("other"))
    }

    @Test fun expiredEntriesAreExcludedFromDisk() {
        val cache = disk(-10.0)
        cache.setValue("gone", "key")
        cache.saveToDisk()
        assertEquals("[]", File(folder.root, "sample.cache").readText())
    }

    @Test fun readsFoundationDatesAndReportsInvalidFilesWithoutPartialRestore() {
        val cache = disk()
        assertThrows(FileNotFoundException::class.java) { cache.loadFromDisk() }
        val file = File(folder.root, "sample.cache")
        file.writeText("""[{"key":"first","value":"fixture","expiredTimestamp":8000000000}]""")
        cache.loadFromDisk()
        assertEquals("fixture", cache.value("first"))
        file.writeText("""[{"key":"first","value":"bad","expiredTimestamp":0},{}]""")
        assertThrows(SerializationException::class.java) { cache.loadFromDisk() }
        assertEquals("fixture", cache.value("first"))
    }

    @Test fun concurrentUpdatesSurviveReload() {
        val cache = disk()
        val pool = Executors.newFixedThreadPool(4)
        try {
            val tasks = (1..100).map { i -> pool.submit { cache.setValue("v", i.toString()); cache.saveToDisk() } }
            tasks.forEach { it.get() }
        } finally { pool.shutdown() }
        val reader = disk()
        reader.loadFromDisk()
        for (i in 1..100) assertEquals("v", reader.value(i.toString()))
    }
}
