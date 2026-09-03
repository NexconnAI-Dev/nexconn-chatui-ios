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
        .package(url: "https://github.com/NexconnAI-Dev/nexconn-chat-sdk-ios.git", exact: "0.100.8")
    ],
    targets: [
        .binaryTarget(
            name: "NexconnChatUI",
            url: "https://downloads.nexconn.ai/release/chatui/ios/0.100.8/NexconnChatUI_0.100.8.zip",
            checksum: "be4fc9ff944b49b4909010cd2043880a3760fbdd987c69eb5fbfadb4a632bccc"
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
