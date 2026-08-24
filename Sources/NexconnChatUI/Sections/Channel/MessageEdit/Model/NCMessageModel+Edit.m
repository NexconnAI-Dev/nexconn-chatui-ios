//
//  NCMessageModel+Edit.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCMessageEditUtil.h"
#import "NCMessageModel+Edit.h"

static NCTextMessage *NCEditTextMessageFromContent(NCMessageContent *content) {
    if (![content isMemberOfClass:[NCTextMessage class]]) {
        return nil;
    }
    return (NCTextMessage *)content;
}

static NCReferenceMessage *NCEditReferenceMessageFromContent(NCMessageContent *content) {
    if (![content isMemberOfClass:[NCReferenceMessage class]]) {
        return nil;
    }
    return (NCReferenceMessage *)content;
}

static NCReferenceMessage *NCEditReferenceMessageFromMessage(NCMessage *message) {
    if (![message.content isMemberOfClass:[NCReferenceMessage class]]) {
        return nil;
    }
    return (NCReferenceMessage *)message.content;
}

@implementation NCMessageModel (Edit)

- (BOOL)edit_isMessageEditable {
    if (!NCChatUIConfigCenter.message.enableEditMessage) {
        return NO;
    }
    if (self.channelType != NCChannelTypeDirect && self.channelType != NCChannelTypeGroup) {
        return NO;
    }
    // Only text and reference messages are editable.
    if (![self.content isMemberOfClass:[NCTextMessage class]] &&
        ![self.content isMemberOfClass:[NCReferenceMessage class]]) {
        return NO;
    }

    // A user can edit only messages they sent.
    if (self.messageDirection != NCMessageDirectionSend) {
        return NO;
    }

    // Only successfully sent messages are editable.
    if (self.messageId.length == 0) {
        return NO;
    }

    return [NCMessageEditUtil isEditTimeValid:self.sentTime];
}

- (BOOL)edit_hasReferenceMessage {
    return [self.content isMemberOfClass:[NCReferenceMessage class]];
}

+ (NSString *)edit_refreshableReferenceMessageUIdFromMessage:(NCMessage *)message {
    NCReferenceMessage *referenceMessage = NCEditReferenceMessageFromMessage(message);
    if (!referenceMessage) {
        return nil;
    }
    if (referenceMessage.referMsgStatus != NCReferenceMessageStatusDefault &&
        referenceMessage.referMsgStatus != NCReferenceMessageStatusUpdated) {
        return nil;
    }
    return message.messageId.length > 0 ? message.messageId : nil;
}

- (NCTextMessage *)edit_textMessage {
    return NCEditTextMessageFromContent(self.content);
}

- (NCReferenceMessage *)edit_referenceMessage {
    return NCEditReferenceMessageFromContent(self.content);
}

- (NSString *)edit_editableText {
    NCTextMessage *textMessage = NCEditTextMessageFromContent(self.content);
    if (textMessage) {
        return textMessage.text;
    }
    NCReferenceMessage *referenceMessage = NCEditReferenceMessageFromContent(self.content);
    if (referenceMessage) {
        return referenceMessage.content;
    }
    return nil;
}

- (NSString *)edit_referenceMessageUserId {
    return NCEditReferenceMessageFromContent(self.content).referMsgSenderId;
}

- (NSString *)edit_referenceMessageUId {
    return NCEditReferenceMessageFromContent(self.content).referMsgId;
}

- (NCReferenceMessageStatus)edit_referenceMessageStatus {
    NCReferenceMessage *referenceMessage = NCEditReferenceMessageFromContent(self.content);
    if (!referenceMessage) {
        return NCReferenceMessageStatusDefault;
    }
    return referenceMessage.referMsgStatus;
}

- (void)edit_setReferenceMessageStatus:(NCReferenceMessageStatus)status {
    NCReferenceMessage *referenceMessage = NCEditReferenceMessageFromContent(self.content);
    if (!referenceMessage) {
        return;
    }
    referenceMessage.referMsgStatus = status;
}

- (NSString *)edit_referencedText {
    NCMessageContent *referencedContent = NCEditReferenceMessageFromContent(self.content).referMsg;
    if (![referencedContent isKindOfClass:[NCTextMessage class]]) {
        return nil;
    }
    return ((NCTextMessage *)referencedContent).text;
}

- (NSString *)edit_formattedReferencedMessageContent {
    NCMessageContent *referencedContent = NCEditReferenceMessageFromContent(self.content).referMsg;
    if (!referencedContent) {
        return nil;
    }
    NSString *formattedContent = [NCChatUIUtility formatMessage:referencedContent
                                                      channelId:self.channelId
                                                    channelType:self.channelType
                                                   isAllMessage:YES];
    return formattedContent ?: @"";
}

- (void)edit_updateReferencedMessagePreviewContentFromModel:(NCMessageModel *)model {
    NCReferenceMessage *referenceMessage = NCEditReferenceMessageFromContent(self.content);
    if (!referenceMessage || !model) {
        return;
    }
    NCMessageContent *referencedContent = referenceMessage.referMsg;
    NCTextMessage *textMessage = NCEditTextMessageFromContent(model.content);
    if (textMessage && [referencedContent isKindOfClass:[NCTextMessage class]]) {
        ((NCTextMessage *)referencedContent).text = textMessage.text;
        return;
    }
    NCReferenceMessage *referencedMessage = NCEditReferenceMessageFromContent(model.content);
    if (referencedMessage && [referencedContent isKindOfClass:[NCReferenceMessage class]]) {
        ((NCReferenceMessage *)referencedContent).content = referencedMessage.content;
    }
}

- (void)edit_updateReferencedMessageContentFromModel:(NCMessageModel *)model {
    NCReferenceMessage *referenceMessage = NCEditReferenceMessageFromContent(self.content);
    if (!referenceMessage) {
        return;
    }
    referenceMessage.referMsg = model.content;
}

@end
