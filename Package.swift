// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "AudioPrism",
    platforms: [.macOS(.v11), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "AudioPrism",
            targets: ["AudioPrism"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AudioPrism",
            dependencies: []),
        .target(
            name: "Fixtures",
            dependencies: [],
            resources: [.copy("audio.m4a")]),
        .testTarget(
            name: "AudioPrismTests",
            dependencies: ["AudioPrism", "Fixtures"]),
        .executableTarget(
            name: "AudioPrismDemo",
            dependencies: ["AudioPrism", "Fixtures"])
    ]
)
