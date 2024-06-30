// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-zenz-coreml",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "swift-zenz-coreml",
            targets: ["swift-zenz-coreml"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "swift-zenz-coreml",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "swift-zenz-coremlTests",
            dependencies: ["swift-zenz-coreml"]),
    ]
)
