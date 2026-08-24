//
//  NCChannelModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

@implementation NCChannelModel

- (instancetype)initWithChannel:(NCBaseChannel *)channel extend:(id)extend {
    NCChannelModelType modelType = NC_CONVERSATION_MODEL_TYPE_NORMAL;
    return [self init:modelType conversation:channel extend:extend];
}

- (instancetype)init:(NCChannelModelType)conversationModelType
        conversation:(NCBaseChannel *)channel
              extend:(id)extend {
    self = [super init];
    if (self) {
        self.extend = extend;
        self.conversationModelType = conversationModelType;
        self.channelId = channel.channelId ?: @"";
        if ([channel isKindOfClass:[NCCommunitySubChannel class]]) {
            NSString *subChannelId = ((NCCommunitySubChannel *)channel).subChannelId;
            self.subChannelId = subChannelId.length > 0 ? subChannelId : nil;
        } else {
            self.subChannelId = nil;
        }
        self.unreadMessageCount = channel.unreadCount;
        self.isTop = channel.isPinned;
        self.channelType = channel.channelType;
        self.noDisturbLevel = channel.noDisturbLevel;
        self.operationTime = channel.operationTime;
        self.sentTime = channel.latestMessage.sentTime;
        self.draft = channel.draft;
        self.editedMessageDraft = channel.editedMessageDraft;
        self.mentionedCount = (int)channel.mentionedCount;
        self.conversationTitle = channel.channelId;
        self.dataManagementInfo = channel.dataManagementInfo;

        NCMessage *latestMessage = channel.latestMessage;
        if (latestMessage) {
            self.objectName = latestMessage.messageType;
            self.senderUserId = latestMessage.senderUserId;
            self.latestMessage = latestMessage.content;
            self.latestMessageClientId = (long)latestMessage.clientId;
            self.latestMessageDirection = latestMessage.direction;
            self.sentStatus = latestMessage.sentStatus;
            self.receivedStatusInfo = latestMessage.receivedStatusInfo;
            self.latestMessageId = latestMessage.messageId;
            self.sentTime = latestMessage.sentTime;
            self.receivedTime = latestMessage.sentTime;
            self.needReceipt = latestMessage.needReceipt;
        }
    }
    return self;
}

- (void)updateWithMessage:(NCMessage *)message {
    if (!message) {
        return;
    }
    self.channelId = message.channelIdentifier.channelId ?: @"";
    if ([message.channelIdentifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]) {
        NSString *subChannelId =
            ((NCCommunitySubChannelIdentifier *)message.channelIdentifier).subChannelId;
        self.subChannelId = subChannelId.length > 0 ? subChannelId : nil;
    } else {
        self.subChannelId = nil;
    }
    self.receivedTime = message.sentTime;
    self.sentTime = message.sentTime;
    self.operationTime = message.sentTime;
    self.objectName = message.messageType;
    self.senderUserId = message.senderUserId;
    self.latestMessageClientId = (long)message.clientId;
    self.latestMessage = message.content;
    self.latestMessageId = message.messageId;
    self.needReceipt = message.needReceipt;

    self.channelType = message.channelIdentifier.channelType;
    self.sentStatus = message.sentStatus;
    self.receivedStatusInfo = message.receivedStatusInfo;
    self.latestMessageDirection = message.direction;

    if (message.direction == NCMessageDirectionReceive && !message.receivedStatusInfo.isRead &&
        !message.receivedStatusInfo.isListened) {
        if (message.isCounted) {
            self.unreadMessageCount += 1;
        }
        if (message.isPersisted && message.content.mentionedInfo.isMentionedMe) {
            self.mentionedCount += 1;
        }
    }
}

- (BOOL)hasLatestMessage {
    return self.latestMessage != nil || self.latestMessageClientId > 0 ||
           self.latestMessageId.length > 0;
}

- (BOOL)lastMessageIsSend {
    return [self hasLatestMessage] && self.latestMessageDirection == NCMessageDirectionSend;
}

- (BOOL)lastMessageIsReceive {
    return [self hasLatestMessage] && self.latestMessageDirection == NCMessageDirectionReceive;
}

- (BOOL)lastMessageIsSending {
    return [self hasLatestMessage] && self.sentStatus == NCMessageSentStatusSending;
}

- (BOOL)lastMessageIsFailed {
    return [self hasLatestMessage] && self.sentStatus == NCMessageSentStatusFailed;
}

- (BOOL)lastMessageIsListened {
    return [self hasLatestMessage] && self.receivedStatusInfo.isListened;
}

- (BOOL)conversationIsMuted {
    return self.noDisturbLevel == NCChannelNoDisturbLevelMuted;
}

- (BOOL)isChannelType:(NCChannelType)channelType {
    return self.channelType == channelType;
}

- (BOOL)isMatchingChannelType:(NCChannelType)channelType channelId:(NSString *)channelId {
    if (self.channelType != channelType) {
        return NO;
    }
    return [self.channelId isEqualToString:channelId];
}

- (BOOL)hasUnreadMentioned {
    return self.mentionedCount > 0;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    NCChannelModel *model = (NCChannelModel *)object;
    return [self isMatchingChannelType:model.channelType channelId:model.channelId];
}

- (void)setDraft:(NSString *)draft {
    if (draft.length) {
        __autoreleasing NSError *error = nil;
        NSData *draftData = [draft dataUsingEncoding:NSUTF8StringEncoding];
        if (!draftData) {
            _draft = draft;
        } else {
            NSDictionary *draftDict = [NSJSONSerialization JSONObjectWithData:draftData
                                                                      options:kNilOptions
                                                                        error:&error];
            if (error) {
                _draft = draft;
            } else if ([draftDict isKindOfClass:[NSDictionary class]] &&
                       [draftDict.allKeys containsObject:@"draftContent"]) {
                _draft = [draftDict objectForKey:@"draftContent"];
            }
        }
    } else {
        _draft = draft;
    }
}

@end
