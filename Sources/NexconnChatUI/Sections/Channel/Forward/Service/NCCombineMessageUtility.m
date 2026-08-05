//
//  NCCombineMessageUtility.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCCombineMessageUtility.h"
#import "NCMessageModel.h"
#import "NCChatUICommonDefine.h"

static NSArray<NSString *> *NCForwardWhiteListBase(BOOL includeReference) {
    NSMutableArray<NSString *> *whiteList = [@[
        NCMessageType.text,
        @"RC:CardMsg",
        NCMessageType.shortVideo,
        NCMessageType.image,
        NCMessageType.file,
        NCMessageType.combine,
        NCMessageType.hdVoice,
        NCMessageType.gif
    ] mutableCopy];

    if (includeReference) {
        [whiteList addObject:NCMessageType.reference];
    } else {
        [whiteList addObject:@"RC:VCSummary"];
    }

    return [whiteList copy];
}

@implementation NCCombineMessageUtility

+ (BOOL)isGroupConversationMessage:(NCCombineMessage *)message {
    return message.channelType == NCChannelTypeGroup;
}

+ (NSArray<NSString *> *)combineNameListFromMessage:(NCCombineMessage *)message {
    return message.nameList;
}

+ (NSArray<NSString *> *)combineSummaryListFromMessage:(NCCombineMessage *)message {
    return message.summaryList;
}

+ (NSString *)getCombineMessagePreviewVCTitle:(NCCombineMessage *)message {
    if (!message) {
        return @"";
    }
    NSString *title = @"";
    BOOL isGroupConversation = [self isGroupConversationMessage:message];
    NSArray<NSString *> *nameList = [self combineNameListFromMessage:message];
    if (isGroupConversation) {
        title = NCUILocalizedString(@"group_chat_history_title");
    } else {
        if (nameList.count > 1) {
            title =
                [NSString stringWithFormat:NCUILocalizedString(@"chat_history_title_x_and_y"),
                                           [nameList firstObject], [nameList lastObject]];
        } else if (nameList.count == 1) {
            title = [NSString stringWithFormat:NCUILocalizedString(@"chat_history_title_x"),
                                               [nameList firstObject]];
        }
    }
    return title;
}

+ (NSString *)getCombineMessageSummaryTitle:(NCCombineMessage *)message {
    if (!message) {
        return @"";
    }
    NSString *title = @"";
    BOOL isGroupConversation = [self isGroupConversationMessage:message];
    NSArray<NSString *> *nameList = [self combineNameListFromMessage:message];
    if (isGroupConversation) {
        title = NCUILocalizedString(@"group_chat_history");
    } else {
        if (nameList.count > 1) {
            title = [NSString stringWithFormat:NCUILocalizedString(@"chat_history_for_x_and_y"),
                                               [nameList firstObject], [nameList lastObject]];
        } else if (nameList.count == 1) {
            title = [NSString stringWithFormat:NCUILocalizedString(@"chat_history_for_x"),
                                               [nameList firstObject]];
        }
    }
    return title;
}

+ (NSString *)getCombineMessageSummaryContent:(NCCombineMessage *)message {
    if (!message) {
        return @"";
    }
    NSArray<NSString *> *summaryList = [self combineSummaryListFromMessage:message];
    if (!summaryList) {
        return @"";
    }
    NSMutableString *summaryContent = [[NSMutableString alloc] init];
    for (int i = 0; i < summaryList.count; i++) {
        NSString *summary = [summaryList objectAtIndex:i];
        [summaryContent appendString:summary];
        if (i < summaryList.count - 1) {
            [summaryContent appendString:@"\n"];
        }
    }
    return [summaryContent copy];
}
// Message types allowed for combined forwarding.
+ (BOOL)allSelectedCombineForwordMessagesAreLegal:(NSArray<NCMessageModel *> *)allSelectedMessages {
    if (!allSelectedMessages) {
        return NO;
    }
    for (NCMessageModel *model in allSelectedMessages) {
        if (!model) {
            return NO;
        }
        // Messages that were not sent successfully cannot be forwarded.
        if (model.sentStatus == NCMessageSentStatusSending || model.sentStatus == NCMessageSentStatusFailed ||
            model.sentStatus == NCMessageSentStatusCanceled) {
            return NO;
        }
        NSArray<NSString *> *whiteList = NCForwardWhiteListBase(NO);
        if (![whiteList containsObject:model.objectName]) {
            return NO;
        }
    }
    return YES;
}
// Message types allowed for individual forwarding.
+ (BOOL)allSelectedOneByOneForwordMessagesAreLegal:(NSArray<NCMessageModel *> *)allSelectedMessages {
    if (!allSelectedMessages) {
        return NO;
    }
    for (NCMessageModel *model in allSelectedMessages) {
        if (!model) {
            return NO;
        }
        // Messages that were not sent successfully cannot be forwarded.
        if (model.sentStatus == NCMessageSentStatusSending || model.sentStatus == NCMessageSentStatusFailed ||
            model.sentStatus == NCMessageSentStatusCanceled) {
            return NO;
        }
        NSArray<NSString *> *whiteList = NCForwardWhiteListBase(YES);
        if (![whiteList containsObject:model.objectName]) {
            return NO;
        }
    }
    return YES;
}

@end
