//
//  NCForwardManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCForwardManager.h"
#import "NCUserInfoCacheManager.h"
#import "NCMessageModel.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUI.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCChatUIGroup.h"
#import "NCChatUIUserInfo.h"

static NSInteger const NCForwardCombineSummaryLimit = 4;

@interface NCForwardManager ()

@property (nonatomic, strong) dispatch_queue_t forwardQueue;
@end

@implementation NCForwardManager
#pragma mark - Public Methods
+ (NCForwardManager *)sharedInstance {
    static NCForwardManager *instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _forwardQueue = dispatch_queue_create("ai.nexconn.forwardQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
- (void)doForwardMessageList:(NSArray<NCMessageModel *> *)messageList
            conversationList:(NSArray<NCBaseChannel *> *)conversationList
                   isCombine:(BOOL)isCombine
     forwardConversationType:(NCChannelType)forwardConversationType
                   completed:(void (^)(BOOL success))completedBlock {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.forwardQueue, ^{
        if (!messageList || conversationList.count <= 0 || !forwardConversationType) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completedBlock(NO);
            });
        }
        if (isCombine) {
            [weakSelf sendCombienMessage:messageList
                      selectConversation:conversationList
                               isCombine:isCombine
                 forwardConversationType:forwardConversationType];
        } else {
            [weakSelf sendMessageOneByone:messageList selectConversation:conversationList isCombine:isCombine];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completedBlock) {
                completedBlock(YES);
            }
        });
    });
}

#pragma mark - Private Methods

- (void)sendMessageOneByone:(NSArray<NCMessageModel *> *)messageList
         selectConversation:(NSArray<NCBaseChannel *> *)conversationList
                  isCombine:(BOOL)isCombine {
    for (NCMessageModel *message in messageList) {
        id messageContent = message.content;
        if (![messageContent isKindOfClass:[NCMessageContent class]]) {
            continue;
        }
        NCMessageContent *forwardContent = (NCMessageContent *)messageContent;
        forwardContent.mentionedInfo = nil;
        forwardContent.senderUserInfo = nil;
        for (NCBaseChannel *conversation in conversationList) {
            NSString *subChannelId = nil;
            if ([conversation isKindOfClass:[NCCommunitySubChannel class]]) {
                subChannelId = ((NCCommunitySubChannel *)conversation).subChannelId;
            }
            [self forwardWithConversationType:conversation.channelType
                                     channelId:conversation.channelId
                                 subChannelId:subChannelId
                                      content:forwardContent
                                    isCombine:isCombine];
        }
    }
}

- (void)sendCombienMessage:(NSArray<NCMessageModel *> *)messageList
        selectConversation:(NSArray<NCBaseChannel *> *)conversationList
                 isCombine:(BOOL)isCombine
   forwardConversationType:(NCChannelType)forwardConversationType {
    (void)isCombine;
    if (messageList.count == 0) {
        return;
    }
    // Build the combined message.
    NSMutableArray *nameList = [[NSMutableArray alloc] init];
    NSMutableArray *summaryList = [[NSMutableArray alloc] init];
    NSMutableArray<NCMessage *> *messages = [NSMutableArray array];
    for (int i = 0; i < messageList.count; i++) {
        NCMessageModel *messageModel = [messageList objectAtIndex:i];
        if (messageModel.clientId <= 0) {
            continue;
        }
        NCGetMessageByIdParams *messageParams =
            [[NCGetMessageByIdParams alloc] initWithMessageClientId:messageModel.clientId];
        __block NCMessage *message = nil;
        dispatch_semaphore_t waitMessage = dispatch_semaphore_create(0);
        [NCBaseChannel getMessageByIdWithParams:messageParams
                                     completion:^(NCMessage * _Nullable ncMessage, NCError * _Nullable error) {
            (void)error;
            message = ncMessage;
            dispatch_semaphore_signal(waitMessage);
        }];
        dispatch_semaphore_wait(waitMessage, DISPATCH_TIME_FOREVER);
        if (!message) {
            continue;
        }
        [messages addObject:message];
        NSString *senderName;
        // Build the sender name list.
        if (forwardConversationType == NCChannelTypeGroup) {
            senderName = [self combineForwardSenderNameForMessageModel:messageModel
                                               forwardConversationType:forwardConversationType];
            NCChatUIGroup *groupInfo =
                [[NCUserInfoCacheManager sharedManager] getGroupInfoFromCacheOnly:messageModel.channelId];
            NSString *groupName = groupInfo.groupName ?: [NSString stringWithFormat:@"group<%@>", messageModel.channelId];
            if (![nameList containsObject:groupName]) {
                [nameList addObject:groupName];
            }
        } else {
            senderName = [self combineForwardSenderNameForMessageModel:messageModel
                                               forwardConversationType:forwardConversationType];
            if (![nameList containsObject:senderName]) {
                [nameList addObject:senderName];
            }
        }
        // Build the message summaries.
        if (i < NCForwardCombineSummaryLimit) {
            [summaryList addObject:[self packageSummaryList:messageModel senderUserName:senderName]];
        }
    }
    if (messages.count == 0) {
        return;
    }
    NCCombineMessage *combineMessage = [[NCCombineMessage alloc] initWithSummaryList:summaryList
                                                                             nameList:nameList
                                                                          channelType:forwardConversationType
                                                                             messages:messages];
    for (NCBaseChannel *conversation in conversationList) {
        [self sendCombineV2Message:combineMessage toConversation:conversation];
    }
}

- (NSString *)combineForwardSenderNameForMessageModel:(NCMessageModel *)messageModel
                              forwardConversationType:(NCChannelType)forwardConversationType {
    NCChatUIUserInfo *userInfo = [self combineForwardManagedUserInfoForMessageModel:messageModel
                                                             forwardConversationType:forwardConversationType];
    if (userInfo.name.length > 0) {
        return userInfo.name;
    }
    return userInfo.userId ?: @"";
}

- (NCChatUIUserInfo *)combineForwardManagedUserInfoForMessageModel:(NCMessageModel *)messageModel
                                           forwardConversationType:(NCChannelType)forwardConversationType {
    if (!messageModel) {
        return nil;
    }
    if (forwardConversationType == NCChannelTypeGroup) {
        return [self managedGroupUserInfoForUserId:messageModel.senderUserId groupId:messageModel.channelId];
    }
    return [self managedUserInfoForUserId:messageModel.senderUserId];
}

- (NCChatUIUserInfo *)managedUserInfoForUserId:(NSString *)userId {
    if (userId.length == 0) {
        return nil;
    }
    NCChatUIUserInfo *userInfo = [[NCUserInfoCacheManager sharedManager] getUserInfo:userId];
    if (!userInfo) {
        userInfo = [NCChatUIUserInfo new];
        userInfo.userId = userId;
    }
    return userInfo;
}

- (NCChatUIUserInfo *)managedGroupUserInfoForUserId:(NSString *)userId groupId:(NSString *)groupId {
    if (userId.length == 0 || groupId.length == 0) {
        return nil;
    }
    NCChatUIUserInfo *memberInfo = [[NCUserInfoCacheManager sharedManager] getUserInfo:userId inGroupId:groupId];
    NCChatUIUserInfo *userInfo = [self managedUserInfoForUserId:userId];
    if (memberInfo) {
        memberInfo.alias = userInfo.alias.length > 0 ? userInfo.alias : memberInfo.alias;
        return memberInfo;
    }
    return userInfo;
}

- (NSString *)packageSummaryList:(NCMessageModel *)messageModel senderUserName:(NSString *)senderUserName {
    NSMutableString *summaryContent =
        [[NSMutableString alloc] initWithFormat:@"%@%@",
                                                 senderUserName ?: @"",
                                                 NCUILocalizedString(@"message_sender_separator")];
    NSString *digest = [NCChatUIUtility formatMessage:messageModel.content
                                          channelId:messageModel.channelId
                                  channelType:messageModel.channelType];
    if (digest.length > 0) {
        digest = [digest stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
        digest = [digest stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        digest = [digest stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
        [summaryContent appendString:digest];
    }
    return summaryContent;
}

- (void)sendCombineV2Message:(NCCombineMessage *)content toConversation:(NCBaseChannel *)conversation {
    if (!content || !conversation.channelId.length) {
        return;
    }
    NCChatUISendMediaMessageParams *params = [[NCChatUISendMediaMessageParams alloc] initWithContent:content];
    params.channelType = conversation.channelType;
    params.channelId = conversation.channelId;
    [[NCChatUI shared] sendMediaMessageWithParams:params
                                             progress:^(int progress, NCMessage *progressMessage) {
        (void)progress;
        (void)progressMessage;
    } completion:^(NCMessage * _Nullable message, NCError * _Nullable error) {
        (void)message;
        (void)error;
    } cancel:^(NCMessage *cancelMessage) {
        (void)cancelMessage;
    }];
    [NSThread sleepForTimeInterval:0.4];
}

- (void)forwardWithConversationType:(NCChannelType)type
                           channelId:(NSString *)channelId
                        subChannelId:(NSString *)subChannelId
                            content:(NCMessageContent *)content
                          isCombine:(BOOL)isCombine {
    NSString *safeTargetId = channelId ?: @"";
    NSString *safeSubChannelId = subChannelId ?: @"";
    if (isCombine) {
        if (![content isKindOfClass:[NCMediaMessageContent class]]) {
            [NSThread sleepForTimeInterval:0.4];
            return;
        }
        NCChatUISendMediaMessageParams *params =
            [[NCChatUISendMediaMessageParams alloc] initWithContent:(NCMediaMessageContent *)content];
        params.channelType = type;
        params.channelId = safeTargetId;
        params.subChannelId = safeSubChannelId;
        params.needReceipt = type == NCChannelTypeDirect || type == NCChannelTypeGroup;
        [[NCChatUI shared] sendMediaMessageWithParams:params
                              progress:^(int progress, NCMessage *progressMessage) {
            (void)progress;
            (void)progressMessage;
        }
                            completion:^(NCMessage * _Nullable message, NCError * _Nullable error) {
            (void)message;
            (void)error;
        }
                                cancel:^(NCMessage *cancelMessage){
            (void)cancelMessage;
        }];
    } else {
        NCChatUISendMessageParams *params = [[NCChatUISendMessageParams alloc] initWithContent:content];
        params.channelType = type;
        params.channelId = safeTargetId;
        params.subChannelId = safeSubChannelId;
        params.needReceipt = type == NCChannelTypeDirect || type == NCChannelTypeGroup;
        [[NCChatUI shared] sendMessageWithParams:params completion:^(NCMessage * _Nullable message, NCError * _Nullable error){
            (void)message;
            (void)error;
        }];
    }
    [NSThread sleepForTimeInterval:0.4];
}

@end
