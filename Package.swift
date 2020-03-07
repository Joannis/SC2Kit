// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SC2Kit",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SC2Kit",
            targets: ["SC2Kit"]),
        .executable(
            name: "ExampleBot",
            targets: ["ExampleBot"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
        // WebSocket client library built on SwiftNIO
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.0.0-rc.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SC2Kit",
            dependencies: ["SwiftProtobuf", "WebSocketKit"]),
        .target(name: "ExampleBot", dependencies: ["SC2Kit"]),
        .testTarget(
            name: "SC2KitTests",
            dependencies: ["SC2Kit"]),
    ]
)
