// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "upto",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "UptoCore",
            path: "Sources/UptoCore"
        ),
        .executableTarget(
            name: "upto",
            dependencies: ["UptoCore"],
            path: "Sources/upto",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "uptoTests",
            dependencies: ["UptoCore"],
            path: "Tests/uptoTests"
        ),
    ]
)
