//
//  NCChannelModel+RRS.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelModel+RRS.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

@implementation NCChannelModel (RRS)
- (BOOL)rrs_couldFetchConversationReadReceipt {
    if (![self isChannelType:NCChannelTypeDirect]) {
        return NO;
    }
    if (![self hasLatestMessage]) {
        return NO;
    }
    if (![self lastMessageIsSend]) {
        return NO;
    }
    if (!self.needReceipt) {
        return NO;
    }
    return YES;
}

- (BOOL)rrs_shouldFetchConversationReadReceipt {
    if (![self rrs_couldFetchConversationReadReceipt]) {
        return NO;
    }
    return YES;
}

- (NCMessageIdentifier *)rrs_messageIdentifier {
    if (self.channelId.length == 0 || ![self hasLatestMessage] || self.latestMessageId.length == 0) {
        return nil;
    }
    NCChannelIdentifier *channelIdentifier = nil;
    NSString *subChannelId = self.subChannelId ?: @"";
    if (subChannelId.length > 0) {
        channelIdentifier = [[NCCommunitySubChannelIdentifier alloc] initWithChannelId:self.channelId
                                                                           subChannelId:subChannelId];
    } else {
        channelIdentifier = [[NCChannelIdentifier alloc] initWithChannelType:self.channelType
                                                                   channelId:self.channelId];
    }
    if (!channelIdentifier) {
        return nil;
    }
    return [[NCMessageIdentifier alloc] initWithChannelIdentifier:channelIdentifier
                                                         messageId:self.latestMessageId];
}
@end
