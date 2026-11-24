import XCTest
import CacheKit

final class CacheKitTests: XCTestCase {
    func testCachesValueByKey() async {
        let cache = InMemoryCache<String>(expirationInterval: 60)
        await cache.setValue("ready", forKey: "status")
        let value = await cache.value(forKey: "status")
        XCTAssertEqual(value, "ready")
    }
}
