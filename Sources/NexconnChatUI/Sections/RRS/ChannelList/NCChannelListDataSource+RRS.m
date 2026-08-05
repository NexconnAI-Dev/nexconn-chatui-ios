//
//  NCChannelListDataSource+RRS.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelListDataSource+RRS.h"
#import "NCChatUIConfig.h"
#import "NCChannelListCellUpdateInfo.h"
#import "NCMessageModel+RRS.h"
#import "NCChannelModel+RRS.h"
#import "NCRRSDataContext.h"
#import "NCRRSUtil.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

const NSInteger NCReadReceiptParamsMaxCount = 100;

static NSString *NCSubChannelIdFromChannelIdentifier(NCChannelIdentifier *channelIdentifier) {
    if ([channelIdentifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]) {
        return ((NCCommunitySubChannelIdentifier *)channelIdentifier).subChannelId ?: @"";
    }
    return @"";
}

static NCMessageReadReceiptInfo *NCReadReceiptInfoFromResponse(NCMessageReadReceiptResponse *response) {
    if (!response || response.messageId.length == 0) {
        return nil;
    }
    NCChannelIdentifier *channelIdentifier = response.channelIdentifier;
    if (!channelIdentifier || channelIdentifier.channelId.length == 0) {
        return nil;
    }
    NCMessageReadReceiptInfo *info = [[NCMessageReadReceiptInfo alloc] init];
    info.channelIdentifier = channelIdentifier;
    info.messageId = response.messageId;
    info.readCount = response.readCount;
    info.unreadCount = response.unreadCount;
    info.totalCount = response.totalCount;
    return info;
}

@implementation NCChannelListDataSource (RRS)

- (void)rrs_didReceiveMessageReadReceiptResponses:(NSArray<NCMessageReadReceiptResponse *> *)responses {
    [NCRRSDataContext refreshCacheWithResponse:responses];
    for (NCMessageReadReceiptResponse *res in responses) {
        if (res.channelIdentifier.channelType != NCChannelTypeDirect) {
            continue;
        }
        if (![self.displayConversationTypeArray containsObject:@(NCChannelTypeDirect)]) {
            continue;
        }
        if (![NCChatUIConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(res.channelIdentifier.channelType)]) {
            continue;
        }
        NCMessageReadReceiptInfo *info = NCReadReceiptInfoFromResponse(res);
        NCChannelType channelType = res.channelIdentifier.channelType;
        NSString *channelId = res.channelIdentifier.channelId ?: @"";
        NSString *subChannelId = NCSubChannelIdFromChannelIdentifier(res.channelIdentifier);
        for (NCChannelModel *model in self.dataList) {
            if ([model isMatchingChannelType:channelType
                                   channelId:channelId]) {
                NSString *leftSubChannelId = model.subChannelId ?: @"";
                NSString *rightSubChannelId = subChannelId;
                if (![leftSubChannelId isEqualToString:rightSubChannelId]) {
                    continue;
                }
                if ([model lastMessageIsSend]
                    && model.needReceipt
                    && model.readReceiptInfo.readCount == 0) {
                    if (!info) {
                        continue;
                    }
                    model.readReceiptInfo = info;
                    
                    NCChannelListCellUpdateInfo *updateInfo =
                    [[NCChannelListCellUpdateInfo alloc] init];
                    updateInfo.model = model;
                    updateInfo.updateType = NCChannelListCellSentStatusUpdate;
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:NCChatUIChannelListCellUpdateNotification
                     object:updateInfo
                     userInfo:nil];
                }
            }
        }
    }
}

- (void)rrs_refreshCachedAndFetchReceiptInfo:(NSArray <NCChannelModel *>*)conversations {
    if (conversations.count == 0) {
        return;
    }
    [NCRRSDataContext refreshConversationsCachedIfNeeded:conversations];
    [self rrs_fetchReadReceiptInfo:conversations];
}

- (void)rrs_fetchReadReceiptInfo:(NSArray<NCChannelModel *>* )conversations {
    if ([NCEngine getConnectionStatus] == NCConnectionStatusConnected) {
        [self rrs_fetchReadReceiptInfoWithConversations:conversations];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self rrs_fetchReadReceiptInfoWithConversations:conversations];
        });
    }
}

- (void)rrs_fetchReadReceiptInfoWithConversations:(NSArray<NCChannelModel *>* )conversations {
    NSMutableArray *array = [NSMutableArray array];
    for (NCChannelModel *model in conversations) {
        if ([model rrs_shouldFetchConversationReadReceipt]) {// Fetch only eligible receipt data.
            [array addObject:model];
        }
    }
    if (array.count > NCReadReceiptParamsMaxCount) {// Split requests that exceed the batch limit.
        NSArray *result = [self rrs_splitArray:array withSize:NCReadReceiptParamsMaxCount];
        for (int i = 0; i<result.count; i++) {
            NSArray *tmp = result[i];
            [self rrs_fetchReadReceiptInfoInLimit:tmp];
        }
    } else {
        [self rrs_fetchReadReceiptInfoInLimit:array];
    }
}

// Split the array with subarrayWithRange:.
- (NSArray *)rrs_splitArray:(NSArray *)array withSize:(NSInteger)size {
    NSMutableArray *result = [NSMutableArray array];
    NSInteger count = array.count;
    
    for (NSInteger i = 0; i < count; i += size) {
        NSInteger length = MIN(size, count - i);
        NSArray *subArray = [array subarrayWithRange:NSMakeRange(i, length)];
        [result addObject:subArray];
    }
    
    return result;
}

- (void)rrs_fetchReadReceiptInfoInLimit:(NSArray<NCChannelModel *>* )conversations {
    
    NSMutableArray<NCMessageIdentifier *> *array = [NSMutableArray array];
    for (NCChannelModel *model in conversations) {
        if ([model rrs_shouldFetchConversationReadReceipt]) {// Fetch only eligible receipt data.
            if (model.readReceiptInfo.readCount > 0 && model.readReceiptInfo.unreadCount == 0) {
                continue;
            }
            NCMessageIdentifier *identifier = [model rrs_messageIdentifier];
            if (identifier) {
                [array addObject:identifier];
            }
        }
    }
    if (array.count == 0) {
        return;
    }
    
    [NCBaseChannel getMessageReadReceiptInfoByIdentifiers:array
                                               completion:^(NSArray<NCMessageReadReceiptInfo *> * _Nullable infoList,
                                                            NCError * _Nullable error) {
        if (!error) {
            [NCRRSDataContext refreshCacheWithReceiptInfo:infoList];
            [self rrs_postReadReceiptNotification:infoList conversations:conversations];
        }
    }];
}

- (void)rrs_postReadReceiptNotification:(NSArray<NCMessageReadReceiptInfo *> *)infoList
                          conversations:(NSArray<NCChannelModel *>* )conversations {
    for (NCMessageReadReceiptInfo *res in infoList) {
        if (res.readCount == 0) {// Ignore responses with no readers.
            continue;
        }
        NCChannelType channelType = res.channelIdentifier.channelType;
        NSString *channelId = res.channelIdentifier.channelId ?: @"";
        NSString *subChannelId = NCSubChannelIdFromChannelIdentifier(res.channelIdentifier);
        for (NCChannelModel *model in conversations) {// Update requested channels first.
            if ([model isMatchingChannelType:channelType
                                   channelId:channelId]) {
                NSString *leftSubChannelId = model.subChannelId ?: @"";
                NSString *rightSubChannelId = subChannelId;
                if (![leftSubChannelId isEqualToString:rightSubChannelId]) {
                    continue;
                }
                if ([model lastMessageIsSend]) {
                    model.readReceiptInfo = res;
                }
            }
        }
        for (NCChannelModel *model in self.dataList) {
            if ([conversations containsObject:model]) {// Requested channels can notify immediately.
                NCChannelListCellUpdateInfo *updateInfo =
                [[NCChannelListCellUpdateInfo alloc] init];
                updateInfo.model = model;
                updateInfo.updateType = NCChannelListCellSentStatusUpdate;
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:NCChatUIChannelListCellUpdateNotification
                 object:updateInfo
                 userInfo:nil];
                continue;
            }
            if ([model isMatchingChannelType:channelType
                                   channelId:channelId]) {// Handle matching channels outside the request list.
                NSString *leftSubChannelId = model.subChannelId ?: @"";
                NSString *rightSubChannelId = subChannelId;
                if (![leftSubChannelId isEqualToString:rightSubChannelId]) {
                    continue;
                }
                if ([model lastMessageIsSend]) {
                    model.readReceiptInfo = res;
                    NCChannelListCellUpdateInfo *updateInfo =
                    [[NCChannelListCellUpdateInfo alloc] init];
                    updateInfo.model = model;
                    updateInfo.updateType = NCChannelListCellSentStatusUpdate;
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:NCChatUIChannelListCellUpdateNotification
                     object:updateInfo
                     userInfo:nil];
                }
            }
        }
    }
}

@end
