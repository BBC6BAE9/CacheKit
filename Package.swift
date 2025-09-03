// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CacheKit",
    platforms: [
        .macOS(.v11), .iOS(.v13), .tvOS(.v13), .visionOS(.v1)
    ],
    products: [
        // Source code version (default)
        .library(
            name: "CacheKit",
            type: .dynamic,
            targets: ["CacheKit"]
        ),
        // Binary version (precompiled XCFramework)
        .library(
            name: "CacheKitBinary",
            targets: ["CacheKitBinary"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", branch: "main"),
    ],
    targets: [
        // Source target
        .target(name: "CacheKit"),
        
        // Binary target
        .binaryTarget(
            name: "CacheKitBinary",
            url: "https://github.com/BBC6BAE9/cachekit/releases/download/0.0.4/CacheKit.xcframework.zip",
            checksum: "3307a446acdd7ebbcb316344fb20b2341390213ebacc6200b7443179fada16a8"
        ),
        
        // Test target
        .testTarget(
            name: "CacheKitTests",
            dependencies: ["CacheKit"]
        ),
    ]
)
