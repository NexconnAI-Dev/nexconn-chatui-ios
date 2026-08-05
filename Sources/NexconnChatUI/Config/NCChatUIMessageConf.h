//
//  NCChatUIMessageConf.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCChatUIMessageConf : NSObject
#pragma mark - Config

#pragma mark Message Notification

/// Whether to disable all local notifications. Default is NO.
///
/// When the app is in the background, local notifications are shown by default. Set this to YES to disable all local notifications.
@property (nonatomic, assign) BOOL disableMessageNotificaiton;

/// Whether to disable all foreground message alert sounds. Default is NO.
///
/// When the app is in the foreground, alert sounds are played by default. Set this to YES to disable all foreground alert sounds.
@property (nonatomic, assign) BOOL disableMessageAlertSound;

/// Whether to enable sending typing status. Default is YES. When enabled, the other party can see a "typing" indicator (currently only supported in direct chat).
@property (nonatomic, assign) BOOL enableTypingStatus;

/// Channel types that have read receipt enabled. Default includes direct and group chat.
///
/// Messages in these channel types will send read receipts when displayed on the channel page. Currently supports direct and group chat.
///
/// OC should pass NSNumber values (e.g. `@[ @(NCChannelTypeDirect) ]`).
/// Swift should pass rawValue (e.g. `[ NCChannelType.direct.rawValue ]`).
@property (nonatomic, copy) NSArray *enabledReadReceiptConversationTypeList;

/// Whether to enable multi-device read status sync. Default is YES.
///
/// When enabled, messages read on other devices will have their unread count cleared on this device. Currently supports direct and group chat.
@property (nonatomic, assign) BOOL enableSyncReadStatus;

/// Whether to enable message mention (@) feature (supports group chat; app needs to implement groupMemberDataSource). Default is YES.
@property (nonatomic, assign) BOOL enableMessageMentioned;

/// Whether to enable message recall. Default is YES.
@property (nonatomic, assign) BOOL enableMessageRecall;

/// Maximum duration for message recall, in seconds. Default is 120s.
@property (nonatomic, assign) NSUInteger maxRecallDuration;

/// Whether to display unregistered message types on the channel page and channel list. Default is YES.
///
/// As the app evolves, new custom message types may be added in future versions that older versions cannot recognize.
/// You can pre-define the display for unregistered messages to improve user experience (e.g., prompt to upgrade).
///
/// Unregistered messages can be customized on the channel page via ``NCChannelViewController/ncUnknownChannelCollectionView:cellForItemAtIndexPath:`` and ``NCChannelViewController/ncUnknownChannelCollectionView:layout:sizeForItemAtIndexPath:``.
/// Unregistered messages can be customized on the channel list by modifying the `unknown_message_cell_tip` string resource.
@property (nonatomic, assign) BOOL showUnkownMessage;

/// Whether to show local notifications for unregistered message types. Default is NO.
///
/// As the app evolves, new custom message types may be added in future versions that older versions cannot recognize.
/// You can pre-define the display for unregistered messages to improve user experience (e.g., prompt to upgrade).
///
/// Unregistered messages can be customized in local notifications by modifying the `unknown_message_notification_tip` string resource.
///
@property (nonatomic, assign) BOOL showUnkownMessageNotificaiton;

/// Maximum duration for voice messages.
///
/// Default is 60 seconds.
/// @warning This property is deprecated. The maximum duration only supports 60-second voice messages.
@property (nonatomic, assign) NSUInteger maxVoiceDuration __deprecated_msg();

/// Whether the app exclusively occupies the audio session.
///
/// Default is NO. After recording ends, `AVAudioSession setActive:NO` is called to
/// restore other background app audio. If set to YES, `setActive:NO` will not be called,
/// so the current app's audio playback will not be interrupted.
@property (nonatomic, assign) BOOL isExclusiveSoundPlayer;

/// Whether the media selector includes video files. Default is NO.
///
/// Videos are not included by default.
@property (nonatomic, assign) BOOL isMediaSelectorContainVideo;

/// Size threshold for auto-downloading GIF messages, in KB.
@property (nonatomic, assign) NSInteger gifAutoDownloadSizeLimit;

/// Whether to enable combined message forwarding. Default is NO. When enabled, messages can be forwarded as combined messages (currently only supported in direct and group chat).
@property (nonatomic, assign) BOOL enableSendCombineMessage;

/// Duration after recall during which a message can be re-edited, in seconds. Default is 300s.
///
/// Re-editing after recall is currently a local-only operation; it will not sync across reinstalls or device changes.
@property (nonatomic, assign) NSUInteger reeditDuration;

/// Whether to support message reference (quote) feature. Default is YES. Long-pressing a message on the channel page supports referencing (currently supports text, file, image messages, and references of references).
@property (nonatomic, assign) BOOL enableMessageReference;

/// Maximum recording duration for short video, in seconds. Default is 10s.
///
/// After integrating the short video feature, use this to set the maximum recording duration. The maximum cannot exceed 2 minutes.
@property (nonatomic, assign) NSUInteger sightRecordMaxDuration;

/// Whether to enable automatic message resend. Default is YES.
///
/// When enabled, the SDK will automatically resend failed messages.
@property (nonatomic, assign) BOOL enableMessageResend;

/// GIF upload size limit, in KB. Equals `NCAppSettings.gifLimitSize`.
@property (nonatomic, assign, readonly) NSUInteger gifLimitSize;

/// Upload video duration limit, in seconds. Equals `NCAppSettings.maxVideoDurationSeconds`.
@property (nonatomic, assign, readonly) NSTimeInterval uploadVideoDurationLimit;

/// Whether to enable message editing. Default is NO.
@property (nonatomic, assign) BOOL enableEditMessage;

/// Whether to attach the current user's info to every outgoing message. Default is NO.
///
/// When enabled, each sent message carries the sender's user info. The receiving side caches
/// and displays the attached info. When disabled, the SDK uses the user info data source to
/// resolve display information.
@property (nonatomic, assign) BOOL enableMessageAttachUserInfo;

/// Whether to automatically download HD voice messages while online. Default is YES.
@property (nonatomic, assign) BOOL automaticDownloadHQVoiceMsgEnable;

/// Color for "edited" text label.
/// Default: 0x7C838E (light), 0xFFFFFF (dark).
/// Use the NCDYCOLOR macro to set colors for light and dark modes.
@property (nonatomic, strong) UIColor *editedTextColor;

@end
