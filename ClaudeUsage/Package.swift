// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeUsage",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ClaudeUsage", targets: ["ClaudeUsage"])
    ],
    targets: [
        .executableTarget(
            name: "ClaudeUsage",
            path: "Sources/ClaudeUsage"
        )
    ]
)
