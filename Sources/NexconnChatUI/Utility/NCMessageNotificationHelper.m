//
//  NCMessageNotificationHelper.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageNotificationHelper.h"
#import "NCChannelNotificationDataContext.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

@implementation NCMessageNotificationHelper
/// Checks whether a message may produce a notification.
/// @param message Message to evaluate.
/// @param completion Receives whether the notification should be shown.
+ (void)checkNotifyAbilityWith:(NCMessage *)message completion:(void (^)(BOOL show))completion {
    if(message.disableNotification) {
        if(completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        }
        return;
    }
    [NCChannelNotificationDataContext queryNotificationLevelWithChannelIdentifier:message.channelIdentifier
                                                                  completion:^(NCChannelNoDisturbLevel level) {
        BOOL re = [self shouldPushByLevel:level message:message];
        if(completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(re);
            });
        }
    }];
}

+ (BOOL)shouldPushByLevel:(NCChannelNoDisturbLevel)level message:(NCMessage *)message {
    BOOL ret = YES;
    NCMentionedType type = message.content.mentionedInfo.type;
    BOOL isSystemMessage = message.channelIdentifier.channelType == NCChannelTypeSystem;
    BOOL isPrivate = message.channelIdentifier.channelType == NCChannelTypeDirect;
    BOOL isGroupChat = !isPrivate && !isSystemMessage;
    BOOL isMentionMe = message.content.mentionedInfo.isMentionedMe;
    // The current user is mentioned, but the mention is not @all.
    BOOL isContainMe = isMentionMe && (type != NCMentionedTypeAll);
    switch(level) {
           // Notify for all channel types.
        case NCChannelNoDisturbLevelAllMessage:
            // DefaultLevel applies no additional filtering here; keep the initial YES result.
        case NCChannelNoDisturbLevelDefaultLevel:
            break;
            // Direct and system channels do not notify. Other channel types notify for any mention of the current user.
        case NCChannelNoDisturbLevelMention: {
            if(!isGroupChat) {
                ret = NO ;
            } else {
                ret = isMentionMe;
            }
            break;
        }
            // Direct and system channels do not notify. Other channel types require a non-@all mention of the current user.
        case NCChannelNoDisturbLevelMentionUsers: { // Show when the mention includes the current user.
            if(!isGroupChat) {
                ret = NO;
            } else {
                ret = isContainMe;
            }
            break;
        }
            // Direct and system channels do not notify. Other channel types require an @all mention.
        case NCChannelNoDisturbLevelMentionAll:{ // Show @all mentions.
            if(!isGroupChat) {
                ret = NO;
            } else {
                ret = (type == NCMentionedTypeAll) ;
            }
            break;
        }
            // Suppress all message notifications.
        case NCChannelNoDisturbLevelMuted:
            ret = NO;
            break;
        default:
            break;
    }
    NCUILog(@"channelType: %ld -> show: %@ -> level: %ld", (long)message.channelIdentifier.channelType,
            ret ? @"YES" : @"NO", (long)level);

    return ret;
}
@end
