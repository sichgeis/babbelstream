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
            dependencies: ["BabbelStreamCore"]
        ),
        .executableTarget(
            name: "BabbelStreamChecks",
            dependencies: ["BabbelStreamCore"]
        ),
        .target(name: "BabbelStreamCore")
    ]
)
