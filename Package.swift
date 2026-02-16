// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AISubscriptionUsage",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AISubscriptionUsage", targets: ["AISubscriptionUsage"])
    ],
    targets: [
        .executableTarget(
            name: "AISubscriptionUsage",
            path: "Sources/ClaudeUsage"
        )
    ]
)
