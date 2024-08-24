// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ios-auto-translate-sdk",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ios-auto-translate-sdk",
            targets: ["ios-auto-translate-sdk"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ios-auto-translate-sdk"),
        .testTarget(
            name: "ios-auto-translate-sdkTests",
            dependencies: ["ios-auto-translate-sdk"]),
    ]
)