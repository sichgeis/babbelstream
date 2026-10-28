// swift-tools-version: 6.2
import PackageDescription
import Foundation

let includeMLX = ProcessInfo.processInfo.environment["BABBELSTREAM_MLX"] == "1"

// Separate deployment target keeps remote dictation available on macOS 13.
let package = Package(
    name: "BabbelStreamLocalSpeech",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", revision: "2faffc237b7b78ae80d938c52cf91700d6709bc5", traits: [])
    ] + (includeMLX ? [
        .package(url: "https://github.com/Blaizzy/mlx-audio-swift.git", revision: "fe2c182f4da8115fe2b6b99c9a4d2048fbf9b1e6")
    ] : []),
    targets: [.executableTarget(name: "BabbelStreamLocalSpeech", dependencies: [
        .product(name: "FluidAudio", package: "FluidAudio")
    ] + (includeMLX ? [
        .product(name: "MLXAudioSTT", package: "mlx-audio-swift"),
        .product(name: "MLXAudioCore", package: "mlx-audio-swift")
    ] : []), swiftSettings: includeMLX ? [.define("BABBELSTREAM_MLX")] : [])]
)
