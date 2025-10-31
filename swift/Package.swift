// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SensitiveString",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "SensitiveString",
            targets: ["SensitiveString"]),
    ],
    targets: [
        .target(name: "SensitiveString"),
        .testTarget(
            name: "SensitiveStringTests",
            dependencies: ["SensitiveString"]),
    ]
)

