// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NexconnChatUI",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "NexconnChatUI",
            targets: ["NexconnChatUIWrapper"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/NexconnAI-Dev/nexconn-chat-sdk-ios.git", exact: "26.4.0")
    ],
    targets: [
        .binaryTarget(
            name: "NexconnChatUI",
            url: "https://downloads.nexconn.ai/release/chatui/ios/26.4.0/NexconnChatUI_26.4.0.zip",
            checksum: "da8ec8da35a79e49da33068760424121600d8bb106835f5877d10c7ad11fc013"
        ),
        .target(
            name: "NexconnChatUIWrapper",
            dependencies: [
                .target(name: "NexconnChatUI"),
                .product(name: "NexconnChat", package: "nexconn-chat-sdk-ios")
            ],
            path: "Sources/NexconnChatUIWrapper"
        )
    ]
)
