// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-zenz-coreml",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .macCatalyst(.v16),
        .tvOS(.v13),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "swift-zenz-coreml",
            targets: ["swift-zenz-coreml"]),
    ],
    dependencies: [
        .package(url: "https://github.com/huggingface/swift-transformers", branch: "0.1.8"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "swift-zenz-coreml",
            dependencies: [
                .product(name: "Transformers", package: "swift-transformers")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "swift-zenz-coremlTests",
            dependencies: ["swift-zenz-coreml"]),
    ]
)
