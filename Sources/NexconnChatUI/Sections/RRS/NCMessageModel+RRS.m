//
//  NCMessageModel+RRS.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIConfig.h"
#import "NCMessageModel+RRS.h"
#import "NCRRSUtil.h"

@implementation NCMessageModel (RRS)
- (BOOL)rrs_shouldRespondReadReceipt {
    if (self.messageId.length == 0) {
        return NO;
    }
    if (!(self.channelType == NCChannelTypeGroup || self.channelType == NCChannelTypeDirect)) {
        return NO;
    }
    if (![NCChatUIConfigCenter.message.enabledReadReceiptConversationTypeList
            containsObject:@(self.channelType)]) {
        return NO;
    }

    if (self.needReceipt && !self.sentReceipt &&
        self.messageDirection == NCMessageDirectionReceive) {
        return YES;
    }
    return NO;
}

- (BOOL)rrs_shouldFetchReadReceipt {
    if (self.messageId.length == 0) {
        return NO;
    }
    if (!(self.channelType == NCChannelTypeGroup || self.channelType == NCChannelTypeDirect)) {
        return NO;
    }
    if (![NCChatUIConfigCenter.message.enabledReadReceiptConversationTypeList
            containsObject:@(self.channelType)]) {
        return NO;
    }
    if (self.needReceipt && self.messageDirection == NCMessageDirectionSend) {
        return YES;
    }

    return NO;
}

@end
