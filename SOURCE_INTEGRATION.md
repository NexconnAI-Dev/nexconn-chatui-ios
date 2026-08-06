# ChatUI Source Integration Guide

This guide is published at the root of the source archive and the public
repository. `Sources/NexconnChatUI` is a self-contained ChatUI source component
that can be copied and maintained independently.

Always copy the complete component directory. Copying individual source files
may omit `Emoji.plist`, theme bundles, localized resources, the privacy
manifest, or the local Podspec.

## Supported Host Projects

The local source Pod supports:

- Objective-C application targets
- Swift application targets
- Mixed Objective-C and Swift application targets

A pure Objective-C target does not need to add a Swift source file or a
bridging header just to consume ChatUI.

The Pod has been validated with CocoaPods' default static library integration,
dynamic frameworks, static frameworks, and modular static libraries. Keep the
linkage configuration already used by the host application. Do not add
`use_frameworks!` only for NexconnChatUI.

## Host App Permissions

The host application must provide user-facing usage descriptions for the
privacy-sensitive features it enables. Add the following keys to the host
application's `Info.plist`:

- `NSCameraUsageDescription` for taking photos and recording video.
- `NSMicrophoneUsageDescription` for recording voice messages and video audio.
- `NSPhotoLibraryUsageDescription` for selecting or reading photos and videos.
- `NSPhotoLibraryAddUsageDescription` for saving photos and videos to the library.

Request the relevant runtime permission before presenting the corresponding
media or voice UI. `PrivacyInfo.xcprivacy` packaged with ChatUI does not replace
these host-application usage descriptions.

## Add the Source Component

Place the complete component directory in the application repository. The
`:path` value in the Podfile is relative to the Podfile location. For example:

```text
CustomerProject/
|-- App/
|   `-- Podfile
`-- Vendor/
    `-- NexconnChatUI/
        |-- NexconnChatUI.podspec
        |-- Config/
        |-- Sections/
        |-- Utility/
        |-- Resource/
        `-- Supporting Files/
```

Add the local dependency to the application target:

```ruby
target "CustomerApp" do
  pod "NexconnChatUI", :path => "../Vendor/NexconnChatUI"
end
```

Run `pod install`, then open the generated `.xcworkspace` instead of the
`.xcodeproj`.

The Podspec depends on the exact matching version of `NexconnChat/Chat`. If the
application also declares `NexconnChat` directly, both dependency versions must
match.

Do not drag `Vendor/NexconnChatUI` into the Xcode project or enable Target
Membership for its source and resource files. CocoaPods must be the only owner
of those files. Manual membership can compile the source twice, copy resources
twice, or add non-build files to the application target.

The local source Pod and the official binary `NexconnChatUI` Pod expose the
same module and must not be installed in the same target.

## Import ChatUI

### Objective-C

For the widest compatibility, import the umbrella header:

```objc
#import <NexconnChatUI/NexconnChatUI.h>
```

If Clang modules are enabled in the host target, module import is also
supported:

```objc
@import NexconnChatUI;
```

A minimal Objective-C compile check is:

```objc
NCChatUI *chatUI = [NCChatUI shared];
NCChannelListViewController *channelList =
    [[NCChannelListViewController alloc] init];
```

Import `NexconnChatSDK` separately, for example with
`@import NexconnChatSDK;`, when directly calling ChatSDK APIs. ChatUI
integration itself does not require a bridging header.

### Swift

Import the module directly:

```swift
import NexconnChatUI
```

Import `NexconnChatSDK` separately when the application directly initializes
or calls ChatSDK APIs.

### Mixed Projects

Use the normal import for each source file:

- Objective-C files use the umbrella header or `@import NexconnChatUI;`.
- Swift files use `import NexconnChatUI`.

Do not expose the ChatUI umbrella header through the application's bridging
header. Each language can consume the CocoaPods module directly.

## Resources

The Podspec packages the required resources automatically. Do not add them to
the application target's Copy Bundle Resources phase manually.

Keep the following paths when customizing the component:

- `Resource/Emoji.plist`
- `Resource/NCChatUIColor.plist`
- `Resource/NCChatUI.bundle`
- `Resource/NCChatUILively.bundle`
- `Resource/*.lproj`
- `Supporting Files/PrivacyInfo.xcprivacy`

If emoji, colors, localization, or theme images are missing at runtime, first
confirm that the complete component directory was copied and that the resource
patterns in `NexconnChatUI.podspec` were not removed.

## Source Customization

Modify source files under `Vendor/NexconnChatUI` and keep that directory in the
application's version control system. Do not edit the generated `Pods/`
directory because `pod install` can overwrite it.

When adding source files, make sure they match `s.source_files` in
`NexconnChatUI.podspec`. When adding or moving resources, update `s.resources`
and verify the resulting application bundle.

After customization, build the actual host configurations used by the
application. For an Objective-C application, validate an Objective-C target;
for a Swift or mixed application, validate those targets as well. At runtime,
verify the IM connection, channel UI, localization, and emoji panel.

## Troubleshooting

`Module 'NexconnChatUI' not found` or `No such module 'NexconnChatUI'`:

- Run `pod install` again and open the generated `.xcworkspace`.
- Confirm the application target is the target that declares the local Pod.
- Confirm the local source Pod is not installed together with the binary
  `NexconnChatUI` Pod.
- In Objective-C targets without module import support, use
  `#import <NexconnChatUI/NexconnChatUI.h>`.

Duplicate symbols or duplicate class implementations:

- Remove manually added ChatUI source files from the application target.
- Remove the official binary `NexconnChatUI` Pod from the same target.
- Keep source and resources managed only by the local Pod.

Missing emoji, localization, or theme resources:

- Confirm the complete `Vendor/NexconnChatUI` directory was copied.
- Confirm `Resource/*` and `Supporting Files/PrivacyInfo.xcprivacy` remain in
  the Podspec resource configuration.
- Do not add a second manual resource-copy path in the application target.
