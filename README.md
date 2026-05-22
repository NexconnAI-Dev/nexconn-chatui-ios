# NexconnChatUI for iOS

NexconnChatUI is the iOS chat UI package for Nexconn Chat. It provides prebuilt chat interface components and depends on the matching version of `NexconnChat`.

## Developer Documentation

For the complete integration guide, including SDK setup, user connection, and Chat UI usage, see:

```text
https://docs.nexconn.ai/chatui-ios
```

## Requirements

- iOS 13.0+
- Swift Package Manager
- Xcode 15 or later is recommended

## Installation

In Xcode, add this repository as a Swift Package dependency:

```text
https://github.com/NexconnAI-Dev/nexconn-chatui-ios.git
```

Then select the package product:

```text
NexconnChatUI
```

Swift Package Manager resolves the required dependencies automatically.

## Import

Import the SDK and Chat UI modules in your app:

```swift
import NexconnChatSDK
import NexconnChatUI
```

## Version Compatibility

`NexconnChatUI` automatically depends on the matching `NexconnChat` version through Swift Package Manager. If your app also declares a direct dependency on `NexconnChat`, use the same release version as `NexconnChatUI`.

## Binary Artifact

This package distributes `NexconnChatUI` as a binary target. The `.xcframework` is not stored directly in this repository. Swift Package Manager downloads the release artifact declared in `Package.swift`.

For local development and CI builds, make sure the build environment can access the Nexconn download domain used by the binary artifact URL.

## Troubleshooting

- Package resolution fails: check that the package URL is correct and that your network can access GitHub.
- Binary artifact download fails: make sure the build environment can access the binary artifact URL declared in `Package.swift`.
- Checksum mismatch: clear the Swift Package Manager cache and resolve packages again. If the issue continues, contact the package maintainer.
- Deployment target error: make sure your app's iOS deployment target is set to iOS 13.0 or later.
