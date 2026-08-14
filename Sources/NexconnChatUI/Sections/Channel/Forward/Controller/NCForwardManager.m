//
//  NCForwardManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCForwardManager.h"
#import "NCUserInfoCacheManager.h"
#import "NCFileUtility.h"
#import "NCMessageModel.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUI.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCChatUIGroup.h"
#import "NCChatUIUserInfo.h"

static NSInteger const NCForwardCombineSummaryLimit = 4;
static NSTimeInterval const NCForwardFetchMessageTimeout = 1.0;

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
                if (completedBlock) {
                    completedBlock(NO);
                }
            });
            return;
        }
        if (isCombine) {
            [weakSelf sendCombienMessage:messageList
                      selectConversation:conversationList
                               isCombine:isCombine
                 forwardConversationType:forwardConversationType
                              completed:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completedBlock) {
                        completedBlock(success);
                    }
                });
            }];
            return;
        }
        [weakSelf sendMessageOneByone:messageList selectConversation:conversationList isCombine:isCombine];
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
   forwardConversationType:(NCChannelType)forwardConversationType
                  completed:(void (^)(BOOL success))completedBlock {
    (void)isCombine;
    if (messageList.count == 0) {
        if (completedBlock) {
            completedBlock(NO);
        }
        return;
    }
    // Build the combined message.
    NSMutableArray *nameList = [[NSMutableArray alloc] init];
    NSMutableArray *summaryList = [[NSMutableArray alloc] init];
    NSMutableArray<NCMessage *> *messages = [NSMutableArray array];
    for (int i = 0; i < messageList.count; i++) {
        NCMessageModel *messageModel = [messageList objectAtIndex:i];
        if (messageModel.clientId <= 0) {
            if (completedBlock) {
                completedBlock(NO);
            }
            return;
        }
        NCGetMessageByIdParams *messageParams =
            [[NCGetMessageByIdParams alloc] initWithMessageClientId:messageModel.clientId];
        __block NCMessage *message = nil;
        __block NCError *fetchError = nil;
        dispatch_semaphore_t waitMessage = dispatch_semaphore_create(0);
        [NCBaseChannel getMessageByIdWithParams:messageParams
                                     completion:^(NCMessage * _Nullable ncMessage, NCError * _Nullable error) {
            message = ncMessage;
            fetchError = error;
            dispatch_semaphore_signal(waitMessage);
        }];
        // 底层异常不回调时不能永久占用合并转发串行队列，超时后报告失败。
        dispatch_time_t timeout =
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NCForwardFetchMessageTimeout * NSEC_PER_SEC));
        if (dispatch_semaphore_wait(waitMessage, timeout) != 0) {
            if (completedBlock) {
                completedBlock(NO);
            }
            return;
        }
        if (!message || fetchError) {
            if (completedBlock) {
                completedBlock(NO);
            }
            return;
        }
        [self cacheMediaLocalPathForMessageModel:messageModel];
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
        if (completedBlock) {
            completedBlock(NO);
        }
        return;
    }
    NCCombineMessage *combineMessage = [[NCCombineMessage alloc] initWithSummaryList:summaryList
                                                                             nameList:nameList
                                                                          channelType:forwardConversationType
                                                                             messages:messages];
    __block NSInteger pendingSendCount = conversationList.count;
    __block BOOL sendSucceeded = YES;
    for (NCBaseChannel *conversation in conversationList) {
        [self sendCombineV2Message:combineMessage toConversation:conversation completed:^(BOOL success) {
            if (!success) {
                sendSucceeded = NO;
            }
            pendingSendCount -= 1;
            if (pendingSendCount == 0 && completedBlock) {
                completedBlock(sendSucceeded);
            }
        }];
    }
}

- (void)cacheMediaLocalPathForMessageModel:(NCMessageModel *)messageModel {
    if (![messageModel.content isKindOfClass:[NCMediaMessageContent class]]) {
        return;
    }
    NCMediaMessageContent *mediaContent = (NCMediaMessageContent *)messageModel.content;
    if (mediaContent.remoteUrl.length == 0 ||
        mediaContent.localPath.length == 0 ||
        ![NCFileUtility isFileExist:mediaContent.localPath]) {
        return;
    }
    [NCFileUtility setFileLocalPath:mediaContent.localPath forRemoteURL:mediaContent.remoteUrl];
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

- (void)sendCombineV2Message:(NCCombineMessage *)content
              toConversation:(NCBaseChannel *)conversation
                  completed:(void (^)(BOOL success))completedBlock {
    if (!content || !conversation.channelId.length) {
        if (completedBlock) {
            completedBlock(NO);
        }
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
        if (completedBlock) {
            completedBlock(error == nil);
        }
    } cancel:^(NCMessage *cancelMessage) {
        (void)cancelMessage;
        if (completedBlock) {
            completedBlock(NO);
        }
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
        params.needReceipt = [NCChatUIUtility shouldNeedReadReceiptForChannelType:type];
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
        params.needReceipt = [NCChatUIUtility shouldNeedReadReceiptForChannelType:type];
        [[NCChatUI shared] sendMessageWithParams:params completion:^(NCMessage * _Nullable message, NCError * _Nullable error){
            (void)message;
            (void)error;
        }];
    }
    [NSThread sleepForTimeInterval:0.4];
}

@end
