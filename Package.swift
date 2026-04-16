// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Quietline",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Quietline",
            targets: ["Quietline"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Quietline",
            path: "Sources/Quietline"
        )
    ]
)
