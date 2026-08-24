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
        .package(url: "https://github.com/NexconnAI-Dev/nexconn-chat-sdk-ios.git", exact: "0.100.2")
    ],
    targets: [
        .binaryTarget(
            name: "NexconnChatUI",
            url: "https://downloads.nexconn.ai/release/chatui/ios/0.100.2/NexconnChatUI_0.100.2.zip",
            checksum: "3439a91040e9f2d4d95ff2f6428c090833c9997d0693f40cdd4d4093da83c5f7"
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
