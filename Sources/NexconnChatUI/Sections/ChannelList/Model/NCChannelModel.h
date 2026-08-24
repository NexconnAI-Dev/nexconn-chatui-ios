//
//  NCChannelModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>

@class NCMessageContent;
@class NCMessage;
@class NCMessageReceivedStatusInfo;

/// Display type of the channel cell data model.
typedef NS_ENUM(NSUInteger, NCChannelModelType) {
    /// Default display.
    NC_CONVERSATION_MODEL_TYPE_NORMAL = 1,
    /// User-customized channel display.
    NC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION = 2
};

NS_ASSUME_NONNULL_BEGIN

/// Data model class for the channel cell.
@interface NCChannelModel : NSObject

/// Display type of the channel cell data model.
@property (nonatomic, assign) NCChannelModelType conversationModelType;

/// User-defined extension data.
@property (nonatomic, strong, nullable) id extend;

/// Channel ID.
@property (nonatomic, copy) NSString *channelId;

/// Sub-channel ID.
@property (nonatomic, copy, nullable) NSString *subChannelId;

/// Channel title.
@property (nonatomic, copy, nullable) NSString *conversationTitle;

/// Unread message count in the channel.
@property (nonatomic, assign) NSInteger unreadMessageCount;

/// Whether the channel is pinned.
@property (nonatomic, assign) BOOL isTop;

/// Background color for pinned cells.
@property (nonatomic, strong, nullable) UIColor *topCellBackgroundColor;

/// Background color for non-pinned cells.
@property (nonatomic, strong, nullable) UIColor *cellBackgroundColor;

/// Received time of the last message in the channel (Unix timestamp, milliseconds).
@property (nonatomic, assign) long long receivedTime;

/// Sent time of the last message in the channel (Unix timestamp, milliseconds).
@property (nonatomic, assign) long long sentTime;

/// Operation time of the channel (Unix timestamp, milliseconds), used as the timestamp for
/// paginated channel list queries. Initial value equals sentTime; operations like pinning will
/// update this timestamp.
@property (nonatomic, assign) long long operationTime;

/// Draft text in the channel.
@property (nonatomic, copy, nullable) NSString *draft;

/// Edited message draft in the channel.
@property (nonatomic, strong, nullable) NCEditedMessageDraft *editedMessageDraft;

/// Type name of the last message in the channel.
@property (nonatomic, copy, nullable) NSString *objectName;

/// Sender user ID of the last message in the channel.
@property (nonatomic, copy, nullable) NSString *senderUserId;

/// Client ID of the last message in the channel.
@property (nonatomic, assign) long latestMessageClientId;

/// Content of the last message in the channel.
@property (nonatomic, strong, nullable) NCMessageContent *latestMessage;

/// Direction of the latest message.
@property (nonatomic, assign) NCMessageDirection latestMessageDirection;

/// Sent status of the latest message.
@property (nonatomic, assign) NCMessageSentStatus sentStatus;

/// Received status of the latest message.
@property (nonatomic, strong, nullable) NCMessageReceivedStatusInfo *receivedStatusInfo;

/// Channel type.
@property (nonatomic, assign) NCChannelType channelType;

/// Do-not-disturb level.
@property (nonatomic, assign) NCChannelNoDisturbLevel noDisturbLevel;

/// JSON dictionary of the last message in the channel.
@property (nonatomic, strong, nullable) NSDictionary *jsonDict;

/// Whether the channel has unread mentioned messages (@you).
@property (nonatomic, assign, readonly) BOOL hasUnreadMentioned;

/// Number of unread mentioned (@) messages in the channel.
@property (nonatomic, assign) int mentionedCount;

/// Timestamp of the first unread message in the channel (Unix timestamp, milliseconds).
///
/// Only supported for ultra group channels.
@property (nonatomic, assign) long long firstUnreadMsgSendTime;

/// Message ID of the last message.
@property (nonatomic, copy, nullable) NSString *latestMessageId;

/// Read receipt operation flag.
@property (nonatomic, assign) BOOL needReceipt;

/// Read receipt info.
@property (nonatomic, strong) NCMessageReadReceiptInfo *readReceiptInfo;

/// Whether to display user online status.
@property (nonatomic, assign) BOOL displayOnlineStatus;

/// User online status.
/// @note Only displayed for direct chat channels; other channel types do not show online status.
@property (nonatomic, strong) NCSubscribeUserOnlineStatus *onlineStatus;

/// Data management info, including channel name and avatar.
///
/// Only supported for direct, group, and system channels.
@property (nonatomic, strong, nullable) NCDataManagementInfo *dataManagementInfo;

/// Initialize a channel display data model.
///
/// @param channel               The channel object.
/// @param extend                User-defined extension data.
/// @return The channel cell data model instance.
- (instancetype)initWithChannel:(NCBaseChannel *)channel extend:(nullable id)extend;

/// Update the data model with the latest message.
///
/// @param message The latest message in this channel.
- (void)updateWithMessage:(NCMessage *)message;

/// Whether a latest message currently exists.
- (BOOL)hasLatestMessage;

/// Whether the latest message is in the send direction.
- (BOOL)lastMessageIsSend;

/// Whether the latest message is in the receive direction.
- (BOOL)lastMessageIsReceive;

/// Whether the latest message is currently being sent.
- (BOOL)lastMessageIsSending;

/// Whether the latest message failed to send.
- (BOOL)lastMessageIsFailed;

/// Whether the latest message has been listened to (for voice messages).
- (BOOL)lastMessageIsListened;

/// Whether the channel is muted (do-not-disturb).
- (BOOL)conversationIsMuted;

/// Whether the channel matches the specified channel type.
- (BOOL)isChannelType:(NCChannelType)channelType;

/// Whether the channel matches the given channel type and channel ID.
///
/// @param channelType Channel type.
/// @param channelId    Channel ID.
/// @return Whether the channel and data model match.
- (BOOL)isMatchingChannelType:(NCChannelType)channelType channelId:(NSString *)channelId;
@end
NS_ASSUME_NONNULL_END
