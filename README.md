# Official iOS Chat UI SDK for [Nexconn Chat](https://www.nexconn.ai/product/chat)

The official iOS Chat UI SDK for Nexconn Chat, a service for building chat
applications. NexconnChatUI provides ready-to-use UIKit screens and components
for channel lists, conversations, messages, profiles, groups, and media.

## Quick Links

- [Register](https://console.nexconn.ai/agile/register?utm_source=ConsolegithubChatUIiOS)
  to get a Nexconn App Key.
- [Documentation](https://docs.nexconn.ai/chatui-ios)
- [Demo app](https://www.nexconn.ai/demos/chat)
- [Chat UI](https://www.nexconn.ai/product/chat#ui-showcase)

## Use Cases

With our component library, you can build a variety of chat use cases, including:

- Livestream chat like Twitch or YouTube.
- Team-style chat like Slack.
- Messaging-style chat like WhatsApp or Facebook Messenger.
- Customer support chat like Drift or Intercom.

The iOS ChatUI layer provides ready-to-use channel lists, conversation screens,
message components, and customization points for these experiences.

## iOS Chat Tutorial

Start with the [Nexconn Chat documentation](https://docs.nexconn.ai/chatui-ios).
It covers SDK initialization, App Key and token handling, connection setup,
channel navigation, message workflows, and ChatUI configuration.

The application must obtain user tokens from a trusted server. Do not embed a
production token in the application binary or commit it to source control.

## Core Features

Together with the matching `NexconnChatSDK` and platform services, the
component library provides the following capabilities:

**User Management**
Manage user profiles and friend relationships in one place, with support for
blocking and banning users to help maintain a healthy community.

**User Presence**
Track online, offline, and custom user statuses in real time for more precise
communication.

**Message Read Receipts**
Synchronize message read status across devices so senders can see when a
message has been read.

**Rich Message Types**
Support text, emoji, images, voice, video, files, and custom messages out of
the box.

**Message Operations**
Support sending, deleting, editing, replying to, forwarding, querying, and
searching message history.

**Real-time Webhooks**
Receive real-time message, user, and group events to capture user activity and
drive application workflows.

**Broadcast Announcements**
Reach all application users, online users, tagged users, or selected users with
precisely targeted announcements.

**Moderation & Safety**
Review message content and identify risks in real time to help protect the chat
environment.

The iOS UI layer additionally includes:

- Ready-to-use channel list and conversation view controllers for UIKit.
- Direct, group, open, system, and community channel types exposed by
  `NexconnChatSDK`.
- Message cells, input controls, profiles, friend lists, group management, and
  public view-controller callbacks.
- Built-in emoji, localization, theme resources, dark-mode support, and online
  status indicators.

## Installation

### Swift Package Manager

In Xcode, add this repository as a package dependency:

```text
https://github.com/NexconnAI-Dev/nexconn-chatui-ios.git
```

Select the `NexconnChatUI` product. Swift Package Manager resolves the matching
`NexconnChat` dependency automatically.

The package product uses the official precompiled
`NexconnChatUI.xcframework` declared by `Package.swift`. It does not compile
the published files under `Sources/NexconnChatUI/`.

The official binary CocoaPods distribution is published separately from this
repository. The local Pod usage below is only for integrating the copied ChatUI
source component.

### Source Integration

Every release tag includes the corresponding ChatUI source snapshot. To keep
the source in the main application repository, copy the complete
`Sources/NexconnChatUI` directory from the selected tag, including its local
Podspec and resources, then add:

```ruby
pod 'NexconnChatUI', :path => '../Vendor/NexconnChatUI'
```

Read `SOURCE_INTEGRATION.md` at the repository root for Objective-C, Swift, and
mixed-language host projects. Do not install the local source Pod and the
official binary `NexconnChatUI` Pod in the same target. Do not drag the copied
source directory into the Xcode project; CocoaPods should manage its source and
resources. Use the same release version for any direct `NexconnChat` dependency.

## Quick Start

The following Objective-C example initializes ChatUI, connects the current user,
and presents a channel list after the connection succeeds:

```objc
#import <NexconnChatUI/NexconnChatUI.h>

- (void)startChatUI {
    NCInitParams *initParams =
        [[NCInitParams alloc] initWithAppKey:@"YOUR_APP_KEY"];
    [[NCChatUI shared] initializeWithParams:initParams];

    NCConnectParams *connectParams =
        [[NCConnectParams alloc] initWithToken:@"TOKEN_FROM_YOUR_SERVER"];
    [[NCChatUI shared]
        connectWithParams:connectParams
        databaseOpenedHandler:nil
        completionHandler:^(NSString *userId, NCError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error != nil) {
                    NSLog(@"Nexconn Chat connection failed: %@", error);
                    return;
                }

                NCChannelListViewController *channelList =
                    [[NCChannelListViewController alloc]
                        initWithDisplayConversationTypes:@[
                            @(NCChannelTypeDirect),
                            @(NCChannelTypeGroup)
                        ]];
                [self.navigationController pushViewController:channelList
                                                       animated:YES];
            });
        }];
}
```

For a single conversation, create `NCChannelViewController` with the target
channel type and channel ID:

```objc
NCChannelViewController *conversation =
    [[NCChannelViewController alloc]
        initWithChannelType:NCChannelTypeDirect
                  channelId:peerUserId];
[self.navigationController pushViewController:conversation animated:YES];
```

Swift applications import the same modules directly:

```swift
import NexconnChatSDK
import NexconnChatUI
```

## Usage

1. Initialize `NCChatUI` once during the application lifecycle with a valid App
   Key.
2. Connect with a user token before presenting ChatUI view controllers.
3. Present `NCChannelListViewController` or `NCChannelViewController` from a
   navigation controller or another host screen.
4. Disconnect through `NCChatUI` when the user logs out. The SDK handles normal
   foreground/background and network reconnection automatically.
5. Keep `NexconnChatUI` and the matching `NexconnChat` dependency on the same
   release version.

## Customization

Global UI, message, and font settings are available through
`NCChatUIConfig.defaultConfig()`:

```objc
NCChatUIConfig *config = [NCChatUIConfig defaultConfig];
config.ui.enableDarkMode = YES;
config.ui.preferredLanguage = @"en";
config.message.enableMessageRecall = YES;
```

For deeper customization, subclass or extend the public view controllers and
callbacks, customize message cells, provide message policy/interceptor delegates,
or switch themes through `NCChatUIThemeManager`.

When maintaining source in the host project, modify the copied component under
`Vendor/NexconnChatUI` and keep its `NexconnChatUI.podspec` resource patterns in
sync with any added source or resource files.

## Internationalization

The built-in UI languages are Simplified Chinese, English, and Arabic. The
default language follows the system language. Set an explicit language through
`NCChatUIConfig.defaultConfig().ui.preferredLanguage` when needed.

To add another language, add a matching `.lproj` directory containing
`NCChatUI.strings` to the source component and keep that resource included by
the local Podspec. Traditional Chinese is not built in; add a `zh-Hant.lproj`
translation in a source integration when required.

## Documentation

See the complete [Nexconn ChatUI documentation](https://docs.nexconn.ai/chatui-ios)
for SDK setup, API details, configuration, media handling, push notifications,
and integration guidance.

For source-based integration and resource troubleshooting, see
`SOURCE_INTEGRATION.md` in the release tag.

## Contributions and Support

The published source is intended for inspection, debugging, and product-specific
customization. Modified forks are not covered by the same support scope as the
official binary distribution.

Direct source contributions are not currently accepted. Report defects and
proposed improvements through the official Nexconn support channel.

## License

- The precompiled `NexconnChatUI.xcframework` and the official binary package
  are governed by `LICENSE`.
- Nexconn-owned ChatUI source under `Sources/NexconnChatUI/` is licensed under
  `OPEN_SOURCE_LICENSE.md`.
- Third-party source remains subject to the notices and licenses recorded in
  `THIRD_PARTY_NOTICES.md`.
