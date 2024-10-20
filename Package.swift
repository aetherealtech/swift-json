// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSON",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "JSON",
            targets: ["JSON"]
        ),
        .library(
            name: "JSONMatching",
            targets: ["JSONMatching"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/aetherealtech/swift-assertions", from: .init(0, 1, 0)),
        .package(url: "https://github.com/aetherealtech/swift-core-extensions", from: .init(0, 1, 0)),
    ],
    targets: [
        .target(
            name: "JSON",
            dependencies: [
                .product(name: "CollectionExtensions", package: "swift-core-extensions"),
            ]
        ),
        .target(
            name: "JSONMatching",
            dependencies: [
                "JSON",
                .product(name: "Assertions", package: "swift-assertions"),
                .product(name: "CollectionExtensions", package: "swift-core-extensions"),
                .product(name: "NumericExtensions", package: "swift-core-extensions"),
            ]
        ),
        .testTarget(
            name: "JSONTests",
            dependencies: [
                "JSON",
                .product(name: "Assertions", package: "swift-assertions"),
            ]
        ),
        .testTarget(
            name: "JSONMatchingTests",
            dependencies: [
                "JSONMatching",
                .product(name: "Assertions", package: "swift-assertions"),
            ]
        ),
    ]
)
