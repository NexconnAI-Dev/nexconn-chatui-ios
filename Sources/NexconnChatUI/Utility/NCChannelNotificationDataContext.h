//
//  NCChannelNotificationDataContext.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUILog.h"
#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

@class NCChannelIdentifier;

NS_ASSUME_NONNULL_BEGIN
#define NCUILog(format, ...) NCLogD((@"[line:%d]" format), __LINE__, ##__VA_ARGS__)

@interface NCChannelNotificationDataContext : NSObject

/// Builds the notification level from the channel list.
/// - Parameter conversations: Channel list.
+ (void)updateNotificationLevelWith:(NSArray<NCBaseChannel *> *)channels;

/// Queries the notification level.
/// - Parameter type: Channel type.
/// - Parameter channelId: Channel ID.
/// - Parameter subChannelId: Sub-channel ID.
/// - Parameter completion: Success callback.
/// - Parameter errorBlock: Failure callback.
+ (void)queryNotificationLevelWith:(NCChannelType)type
                         channelId:(NSString *__nullable)channelId
                      subChannelId:(NSString *__nullable)subChannelId
                        completion:(void (^)(NCChannelNoDisturbLevel level))completion;

/// NCChannelIdentifier variant used by the NCMessage path.
+ (void)queryNotificationLevelWithChannelIdentifier:(NCChannelIdentifier *)channelIdentifier
                                         completion:
                                             (void (^)(NCChannelNoDisturbLevel level))completion;

/// Destroys the context.
+ (void)destroy;

+ (void)clean;
@end

NS_ASSUME_NONNULL_END
