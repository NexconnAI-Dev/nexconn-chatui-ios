//
//  NCChatUIExtensionModule.h
//  NCExtensionKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatSessionInputBarControl.h"
#import "NCEmoticonTabSource.h"
#import "NCChatUIExtensionPluginItemInfo.h"
#import <Foundation/Foundation.h>

@class NCChatUIUserInfo;
@class NCMessage;

/// Extension module protocol
@protocol NCChatUIExtensionModule <NSObject>

/// Create an extension module instance.
+ (instancetype)loadExtensionModule;

@optional
#pragma mark - SDK status notify
/*!
 Initialize the IM SDK

 @param appkey   The app key
 */
- (void)initWithAppKey:(NSString *)appkey;

/*!
 Connect to the IM service

 @param userId   The user ID
 */
- (void)didConnect:(NSString *)userId;

/// Disconnect from the IM service
- (void)didDisconnect;

/// Destroy the extension module
- (void)destroyModule;

/*!
 Callback when the current logged-in user info is updated

 @param userInfo The current logged-in user info
 */
- (void)didCurrentUserInfoUpdated:(NCChatUIUserInfo *)userInfo;

/*!
 Handle a received message

 @param message  The received message
 */
- (void)onMessageReceived:(NCMessage *)message;

/*!
 Handle the alert sound event for a received message

 @param message  The received message

 @return The handling result. YES means the module handles the alert and the SDK will not play a sound. NO means the module does not handle it and the SDK will use default behavior.
 When the app is in the foreground and inside the conversation of the new message, there is no sound or notification; otherwise a sound alert is played. When the app is in the background, a local notification is shown.
 */
- (BOOL)handleAlertForMessageReceived:(NCMessage *)message;

/*!
 Handle the notification event for a received message

 @param message   The received message
 @param fromName  The source name. For private messages it is the sender's name; for group messages it is the group name.
 @param userInfo  LocalNotification userInfo. If the extension module posts a local notification, it must include this userInfo.

 @return The handling result. YES means the module handles the notification and the SDK will not show one. NO means the module does not handle it and the SDK will use default behavior.
 When the app is in the foreground and inside the conversation of the new message, there is no sound or notification; otherwise a sound alert is played. When the app is in the background, a local notification is shown.
 */
- (BOOL)handleNotificationForMessageReceived:(NCMessage *)message
                                        from:(NSString *)fromName
                                    userInfo:(NSDictionary *)userInfo;

#pragma mark - App URL
/*!
 Set the URL scheme for the extension module.

 @param scheme      The URL scheme
 */
- (void)setScheme:(NSString *)scheme;

/*!
 Handle an openUrl request

 @return Whether the request was handled
 */
- (BOOL)onOpenUrl:(NSURL *)url;

#pragma mark - Input Bar
/*!
 Get the plugin board item info list for the channel page.

 @param channelType  The channel type
 @param channelId          The channel ID

 @return The list of plugin board item info.

 When entering the channel page, the SDK registers items in the plugin board area.
 */
- (NSArray<NCChatUIExtensionPluginItemInfo *> *)getPluginBoardItemInfoList:(NCChannelType)channelType
                                                            channelId:(NSString *)channelId;

/*!
 Get the emoticon tab list for the input area

 @param channelType  The channel type
 @param channelId          The channel ID

 @return The list of emoticon tabs to load
 */
- (NSArray<id<NCEmoticonTabSource>> *)getEmoticonTabList:(NCChannelType)channelType
                                                channelId:(NSString *)channelId;

/*!
 Callback when the add button in the emoticon panel is tapped

 @param emojiView       The emoticon panel
 @param addButton       The add button
 @param inputBarControl The input bar containing the emoticon panel
 */
- (void)emoticonTab:(NCEmojiBoardView *)emojiView
  didTouchAddButton:(UIButton *)addButton
         inInputBar:(NCChatSessionInputBarControl *)inputBarControl;

/*!
 Callback when an emoticon pack icon button in the emoticon panel is tapped

 @param emojiView       The emoticon panel
 @param index           The index of the emoticon pack icon
 @param inputBarControl The input bar containing the emoticon panel
 @param block           Whether to block the SDK default tap handling
 */

- (void)emoticonTab:(NCEmojiBoardView *)emojiView
    didTouchEmotionIconIndex:(int)index
                  inInputBar:(NCChatSessionInputBarControl *)inputBarControl
         isBlockDefaultEvent:(void (^)(BOOL isBlockDefaultEvent))block;

/*!
 Callback when the settings button in the emoticon panel is tapped

 @param emojiView       The emoticon panel
 @param settingButton   The settings button
 @param inputBarControl The input bar containing the emoticon panel
 */
- (void)emoticonTab:(NCEmojiBoardView *)emojiView
    didTouchSettingButton:(UIButton *)settingButton
               inInputBar:(NCChatSessionInputBarControl *)inputBarControl;

/*!
 Callback when the input text view content changes

 @param inputTextView   The text input view
 @param inputBarControl The input bar containing the text input view
 */
- (void)inputTextViewDidChange:(UITextView *)inputTextView inInputBar:(NCChatSessionInputBarControl *)inputBarControl;

/*!
 Callback when the input bar status changes

 @param status           The current input bar status
 @param inputBarControl  The input bar
 */

- (void)inputBarStatusDidChange:(KBottomBarStatus)status inInputBar:(NCChatSessionInputBarControl *)inputBarControl;

/*!
 Whether the emoticon add button should be displayed

 @param inputBarControl  The input bar
 */
- (BOOL)isEmoticonAddButtonEnabled:(NCChatSessionInputBarControl *)inputBarControl;

/*!
 Whether the emoticon settings button should be displayed

 @param inputBarControl  The input bar
 */
- (BOOL)isEmoticonSettingButtonEnabled:(NCChatSessionInputBarControl *)inputBarControl;

/// Whether the audio channel is in use
- (BOOL)isAudioHolding;

/// Whether the camera is in use
- (BOOL)isCameraHolding;
@end
