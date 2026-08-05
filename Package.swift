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
        .package(url: "https://github.com/NexconnAI-Dev/nexconn-chat-sdk-ios.git", exact: "26.3.0")
    ],
    targets: [
        .binaryTarget(
            name: "NexconnChatUI",
            url: "https://downloads.nexconn.ai/release/chatui/ios/26.3.0/NexconnChatUI_26.3.0.zip",
            checksum: "9047caec826ccb0df436f47305bae7c295a84266a04fd6e548d2304cfadcba89"
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
