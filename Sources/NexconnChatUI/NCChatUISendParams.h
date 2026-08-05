//
//  NCChatUISendParams.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NEXCONNCHATUI_NCCHATUISENDPARAMS_H
#define NEXCONNCHATUI_NCCHATUISENDPARAMS_H

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

@class NCMessageContent;
@class NCMediaMessageContent;
@class NCPushConfig;

NS_ASSUME_NONNULL_BEGIN

/// Parameters for sending a standard message through ChatUI.
@interface NCChatUISendMessageParams : NSObject

/// The channel type of the target channel.
@property (nonatomic, assign) NCChannelType channelType;

/// The target channel ID.
@property (nonatomic, copy) NSString *channelId;

/// The target sub-channel ID, or nil when the target channel does not use sub-channels.
@property (nonatomic, copy, nullable) NSString *subChannelId;

/// The message content to send.
@property (nonatomic, strong) NCMessageContent *content;

/// The push configuration used for this message.
@property (nonatomic, strong, nullable) NCPushConfig *pushConfig;

/// Whether the message requires read receipt support.
@property (nonatomic, assign) BOOL needReceipt;

/// User IDs that should receive this directed message.
@property (nonatomic, copy, nullable) NSArray<NSString *> *directedUserIds;

/// Whether local notification presentation should be disabled for this message.
@property (nonatomic, assign) BOOL disableNotification;

/// Custom key-value metadata attached to this message.
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *metadata;

/// Creates send parameters with the specified message content.
///
/// @param content The message content to send.
- (instancetype)initWithContent:(NCMessageContent *)content;

@end

/// Parameters for sending a media message through ChatUI.
@interface NCChatUISendMediaMessageParams : NSObject

/// The channel type of the target channel.
@property (nonatomic, assign) NCChannelType channelType;

/// The target channel ID.
@property (nonatomic, copy) NSString *channelId;

/// The target sub-channel ID, or nil when the target channel does not use sub-channels.
@property (nonatomic, copy, nullable) NSString *subChannelId;

/// The media message content to send.
@property (nonatomic, strong) NCMediaMessageContent *content;

/// The push configuration used for this message.
@property (nonatomic, strong, nullable) NCPushConfig *pushConfig;

/// Whether the message requires read receipt support.
@property (nonatomic, assign) BOOL needReceipt;

/// User IDs that should receive this directed message.
@property (nonatomic, copy, nullable) NSArray<NSString *> *directedUserIds;

/// Whether local notification presentation should be disabled for this message.
@property (nonatomic, assign) BOOL disableNotification;

/// Custom key-value metadata attached to this message.
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *metadata;

/// Creates send parameters with the specified media message content.
///
/// @param content The media message content to send.
- (instancetype)initWithContent:(NCMediaMessageContent *)content;

@end

NS_ASSUME_NONNULL_END

#endif /* NEXCONNCHATUI_NCCHATUISENDPARAMS_H */
