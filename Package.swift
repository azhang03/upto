// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "upto",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "upto",
            path: "Sources/upto"
        ),
        .testTarget(
            name: "uptoTests",
            dependencies: ["upto"],
            path: "Tests/uptoTests"
        ),
    ]
)
