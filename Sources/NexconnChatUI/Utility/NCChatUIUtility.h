//
//  NCChatUIUtility.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>
#import "NCMessageModel.h"

@class NCChannelModel;
@class NCChatUIUserInfo;
@class NCMessage;

/// ChatUI utility class.
@interface NCChatUIUtility : NSObject

/// Convert a channel list timestamp to a display string.
///
/// @param secs    Unix timestamp in seconds.
/// @return A human-readable time string.
///
/// If the time is today, returns "HH:mm".
/// If the time is yesterday, returns the localized "Yesterday" string.
/// If the time is before yesterday or after today, returns "yyyy-MM-dd".
+ (NSString *)convertConversationTime:(long long)secs;

/// Convert a channel page message timestamp to a display string.
///
/// @param secs    Unix timestamp in seconds.
/// @return A human-readable time string.
///
/// If the time is today, returns "HH:mm".
/// If the time is yesterday, returns "Yesterday HH:mm" (localized).
/// If the time is before yesterday or after today, returns "yyyy-MM-dd HH:mm".
+ (NSString *)convertMessageTime:(long long)secs;

/// Get an image from a resource bundle.
///
/// @param name        Image name.
/// @param bundleName  Bundle name containing the image.
/// @return The image.
+ (UIImage *)imageNamed:(NSString *)name ofBundle:(NSString *)bundleName;

/// Get the icon for a file type in channel messages.
/// @param type File type suffix.
/// Returns the custom icon from NCChatUIConf's registerFileSuffixTypes if configured; otherwise returns the default icon from NCChatUI.bundle.
+ (UIImage *)imageWithFileSuffix:(NSString *)type;

/// Calculate the display size for text.
///
/// @param text Text content.
/// @param font Font.
/// @param constrainedSize Maximum container size.
/// @return The calculated text display size.
///
/// For iOS 7 and below, this method defaults to NSLineBreakByTruncatingTail mode.
+ (CGSize)getTextDrawingSize:(NSString *)text font:(UIFont *)font constrainedSize:(CGSize)constrainedSize;

/// Get a digest summary of message content for a specific channel type.
///
/// @param messageContent  Message content.
/// @param channelId  Channel ID.
/// @param channelType  Channel type.
/// @param isAllMessage  Whether to get the full digest. If NO, content longer than 500 characters may be truncated.
/// @return A digest string of the message content.
///
/// Built-in message types have default handling. Custom messages use the NCMessageContent digest capability via conversationDigest.
+ (NSString *)formatMessage:(id)messageContent
                   channelId:(NSString *)channelId
           channelType:(NSInteger)channelType
               isAllMessage:(BOOL)isAllMessage;

/// Get the content digest for message notifications.
///
/// @param message  The message.
/// @return A digest string of the message content.
///
/// Built-in message types have default handling. Custom messages use the NCMessageContent digest capability via conversationDigest.
+ (NSString *)formatLocalNotification:(id)message;

/// NCMessage version of formatLocalNotification.
+ (NSString *)formatLocalNotificationWithNCMessage:(NCMessage *)message;

/// Get a digest summary of message content for a specific channel type.
///
/// @param messageContent  Message content.
/// @param channelId  Channel ID.
/// @param channelType  Channel type.
/// @return A digest string of the message content.
///
/// Built-in message types have default handling.
/// Custom messages use the NCMessageContent digest capability.
/// Unlike formatMessage:channelId:channelType:isAllMessage:, content longer than 500 characters may be truncated.
+ (NSString *)formatMessage:(id)messageContent
                   channelId:(NSString *)channelId
           channelType:(NSInteger)channelType;

/// Get a digest summary of message content.
///
/// @param messageContent  Message content.
/// @return A digest string of the message content.
///
/// Built-in message types have default handling.
/// Custom messages use the NCMessageContent digest capability.
/// Unlike formatMessage:channelId:channelType:isAllMessage:, content longer than 500 characters may be truncated.
+ (NSString *)formatMessage:(id)messageContent;

/// Whether a message should be displayed.
///
/// @param message The message.
/// @return Whether the message should be displayed.
+ (BOOL)isVisibleMessage:(id)message;

/// Whether a message is an unregistered (unknown) message.
///
/// @param clientId The message ID.
/// @param content   The message content.
/// @return Whether the message is unregistered.
+ (BOOL)isUnkownMessage:(long)clientId content:(id)content;

/// Get the local notification dictionary for a message.
///
/// @param message The message entity.
/// @return The local notification dictionary.
+ (NSDictionary *)getNotificationUserInfoDictionary:(id)message;

/// NCMessage version of getNotificationUserInfoDictionary.
+ (NSDictionary *)getNotificationUserInfoDictionaryWithNCMessage:(NCMessage *)message;

/// Get the local notification dictionary for a message.
///
/// @param channelType    Channel type.
/// @param fromUserId          Sender user ID.
/// @param channelId            Target channel ID.
/// @param objectName          Message type name.
/// @return The local notification dictionary.
+ (NSDictionary *)getNotificationUserInfoDictionary:(NSInteger)channelType
                                         fromUserId:(NSString *)fromUserId
                                           channelId:(NSString *)channelId
                                         objectName:(NSString *)objectName;

/// Get the icon image name for a file type in file messages.
///
/// @param fileType    File type.
/// @return The image name.
+ (NSString *)getFileTypeIcon:(NSString *)fileType;

/// Get a human-readable file size string, in KB.
///
/// @param byteSize    File size in bytes.
/// @return A human-readable file size string.
+ (NSString *)getReadableStringForFileSize:(long long)byteSize;

/// Get the default placeholder avatar for a channel.
///
/// @param model The channel data model.
/// @return The default placeholder avatar.
+ (UIImage *)defaultConversationHeaderImage:(NCChannelModel *)model;

/// Get the unread mentioned message count for a channel model.
///
/// @param model The channel data model.
+ (void)getConversationUnreadMentionedCount:(NCChannelModel *)model result:(void(^)(int num))result;

/// Sync the multi-device read status for a channel.
///
/// @param conversation The channel model.
///
/// Filters and syncs based on the configured enabledReadReceiptConversationTypeList.
+ (void)syncConversationReadStatusIfEnabled:(NCChannelModel *)conversation;

/// Whether messages sent to the given channel type should request read receipts.
///
/// Reflects the configured enabledReadReceiptConversationTypeList switch so that
/// the send/forward entries share one policy instead of hardcoding channel types.
///
/// @param channelType The target channel type.
/// @return YES if read receipts are enabled for this channel type.
+ (BOOL)shouldNeedReadReceiptForChannelType:(NCChannelType)channelType;

/// Get the pinyin initial letter for a Chinese character.
///
/// @param hanZi The Chinese character string.
/// @return The pinyin initial letter(s).
+ (NSString *)getPinYinUpperFirstLetters:(NSString *)hanZi;

/// Open a URL in SFSafariViewController or WebViewController.
///
/// @param url             The URL.
/// @param viewController  The view controller to present from.
+ (void)openURLInSafariViewOrWebView:(NSString *)url base:(UIViewController *)viewController;

/// Check if a URL starts with http or https; if not, prepend "http://".
///
/// @param url The URL.
/// @return The URL with http or https prefix.
+ (NSString *)checkOrAppendHttpForUrl:(NSString *)url;

/// Get the key window.
///
/// @return The key UIWindow.
+ (UIWindow *)getKeyWindow;

/// Get the window that contains the view.
///
/// @param view The view used to resolve the current window.
/// @return The current UIWindow.
+ (UIWindow *)getWindowForView:(UIView *)view;

/// Whether the application is currently in background state.
+ (BOOL)isApplicationInBackground;

/// Get the safe area insets of the AppDelegate window.
///
/// @return The safe area insets.
+ (UIEdgeInsets)getWindowSafeAreaInsets;

/// Get safe area insets from the window that contains the view.
///
/// @param view The view used to resolve the current window.
/// @return The safe area insets.
+ (UIEdgeInsets)getWindowSafeAreaInsetsForView:(UIView *)view;

/// Get status bar height from the window scene that contains the view.
///
/// @param view The view used to resolve the current window scene.
/// @return The status bar height.
+ (CGFloat)getStatusBarHeightForView:(UIView *)view;

/// Get interface orientation from the window scene that contains the view.
///
/// @param view The view used to resolve the current window scene.
/// @return The current interface orientation.
+ (UIInterfaceOrientation)getInterfaceOrientationForView:(UIView *)view;

/// Fix the image orientation for iOS system images.
///
/// @param image The image to fix.
/// @return The orientation-corrected image.
+ (UIImage *)fixOrientation:(UIImage *)image;

/// Whether the current device is an iPad.
+ (BOOL)currentDeviceIsIPad;

/// Generate a dynamic color for dark mode support.
///
/// @param lightColor  Light mode color.
/// @param darkColor   Dark mode color.
/// @return The dynamic color.
+ (UIColor *)generateDynamicColor:(UIColor *)lightColor darkColor:(UIColor *)darkColor;

/// Whether an image has been loaded based on the image URL of an image message.
+ (BOOL)hasLoadedImage:(NSString *)imageUrl;

/// Get the downloaded image data for an image message URL.
///
/// @param imageUrl  The image URL from the image message.
/// @return The image data.
+ (NSData *)getImageDataForURLString:(NSString *)imageUrl;

/// Get a color value from the NCColor.plist file.
///
/// @param key The key for the color value.
/// @param colorStr The original color hex string.
/// @return The resolved color.
+ (UIColor *)color:(NSString *)key originalColor:(NSString *)colorStr;

/// Show a progress HUD on a view.
///
/// @param view The view.
/// @param text The hint text.
/// @param animated Whether to animate.
+ (BOOL)showProgressViewFor:(UIView *)view text:(NSString *)text animated:(BOOL)animated;

/// Hide the progress HUD from a view.
///
/// @param view The view.
/// @param animated Whether to animate.
+ (BOOL)hideProgressViewFor:(UIView *)view animated:(BOOL)animated;

/// Get the left navigation bar button items.
///
/// @param image  The button image.
/// @param title  The button title (can be nil).
/// @return An array of left bar button items.
/// When using RTL layout, the image is flipped internally; no developer handling needed.
+ (NSArray <UIBarButtonItem *> *)getLeftNavigationItems:(UIImage *)image title:(NSString *)title target:(id)target action:(SEL)action;

/// Whether RTL layout is required.
///
/// Returns YES when the system version is above 9.0 and the system or app layout is UISemanticContentAttributeForceRightToLeft; otherwise returns NO.
+ (BOOL)isRTL;

/// Whether another module is currently using the audio channel.
///
/// Primarily checks ChatUI submodules and IMLib submodules.
+ (BOOL)isAudioHolding;

/// Whether another module is currently using the camera.
///
/// Primarily checks ChatUI submodules and IMLib submodules.
+ (BOOL)isCameraHolding;

/// Get the display name for a user.
///
/// Returns the alias if available; otherwise returns the name.
+ (NSString *)getDisplayName:(NCChatUIUserInfo *)userInfo;


/// Get a localized string.
/// @param key The localization key.
/// @param table The localization table name.
+ (NSString *)localizedString:(NSString *)key table:(NSString *)table;

/// Find a file by name (searches root directory first, then framework).
/// @param name The file name.
+ (NSString *)filePathForName:(NSString *)name;

/// Find a bundle by name (searches root directory first, then framework).
/// @param bundleName The bundle name.
+ (NSString *)bundlePathWithName:(NSString *)bundleName;

/// Whether the current appearance is dark mode.
+ (BOOL)isDarkMode;

@end
