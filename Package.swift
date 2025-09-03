// swift-tools-version: 5.9
// Temporary Package.swift for XCFramework building - contains only source targets

import PackageDescription

let package = Package(
    name: "CacheKit",
    platforms: [
        .macOS(.v11), .iOS(.v13), .tvOS(.v13), .visionOS(.v1)
    ],
    products: [
        // Source code version for building XCFramework
        .library(
            name: "CacheKit",
            targets: ["CacheKit"]
        ),
    ],
    dependencies: [],
    targets: [
        // Source target
        .target(name: "CacheKit"),
        
        // Test target
        .testTarget(
            name: "CacheKitTests",
            dependencies: ["CacheKit"]
        ),
    ]
)
