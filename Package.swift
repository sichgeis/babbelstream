// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BabbelStream",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BabbelStream", targets: ["BabbelStreamApp"]),
        .executable(name: "BabbelStreamChecks", targets: ["BabbelStreamChecks"]),
        .library(name: "BabbelStreamCore", targets: ["BabbelStreamCore"])
    ],
    targets: [
        .executableTarget(
            name: "BabbelStreamApp",
            dependencies: ["BabbelStreamApplication"],
            path: "Sources/BabbelStreamLauncher"
        ),
        .executableTarget(
            name: "BabbelStreamChecks",
            dependencies: ["BabbelStreamCore", "BabbelStreamApplication"]
        ),
        .target(
            name: "BabbelStreamApplication",
            dependencies: ["BabbelStreamCore"],
            path: "Sources/BabbelStreamApp"
        ),
        .target(name: "BabbelStreamCore")
    ]
)
