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
        .package(url: "https://github.com/NexconnAI-Dev/nexconn-chat-sdk-ios.git", exact: "26.4.2")
    ],
    targets: [
        .binaryTarget(
            name: "NexconnChatUI",
            url: "https://downloads.nexconn.ai/release/chatui/ios/26.4.2/NexconnChatUI_26.4.2.zip",
            checksum: "7cc23db87fc33feff012a0e51585d3cecbd6677c9b4ad0043b5bd302041c4a76"
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
