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

static NSString *NCReadReceiptKey(NCChannelType channelType,
                                  NSString *channelId,
                                  NSString *subChannelId,
                                  NSString *messageId) {
    if (channelId.length == 0 || messageId.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%ld%@%@%@%@%@%@",
                                      (long)channelType,
                                      @"\x1F",
                                      channelId ?: @"",
                                      @"\x1F",
                                      subChannelId ?: @"",
                                      @"\x1F",
                                      messageId ?: @""];
}

static NSString *NCReadReceiptKeyForInfo(NCMessageReadReceiptInfo *info) {
    if (!info.channelIdentifier) {
        return nil;
    }
    return NCReadReceiptKey(info.channelIdentifier.channelType,
                            info.channelIdentifier.channelId,
                            NCSubChannelIdFromChannelIdentifier(info.channelIdentifier),
                            info.messageId);
}

static NSString *NCReadReceiptKeyForModel(NCChannelModel *model) {
    if (!model) {
        return nil;
    }
    return NCReadReceiptKey(model.channelType,
                            model.channelId,
                            model.subChannelId ?: @"",
                            model.latestMessageId);
}

@interface NCChannelListDataSource (RRSPrivate)
- (void)rrs_applyReadReceiptInfoList:(NSArray<NCMessageReadReceiptInfo *> *)infoList
                       conversations:(NSArray<NCChannelModel *> *)conversations
                  skipsZeroReadCount:(BOOL)skipsZeroReadCount
                  requiresNeedReceipt:(BOOL)requiresNeedReceipt
            updatesOnlyZeroReadCount:(BOOL)updatesOnlyZeroReadCount;
- (void)rrs_reloadReadReceiptAffectedIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
                                         models:(NSArray<NCChannelModel *> *)models;
@end

@implementation NCChannelListDataSource (RRS)

- (void)rrs_didReceiveMessageReadReceiptResponses:(NSArray<NCMessageReadReceiptResponse *> *)responses {
    [NCRRSDataContext refreshCacheWithResponse:responses];
    NSMutableArray<NCMessageReadReceiptInfo *> *infoList = [NSMutableArray array];
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
        if (info) {
            [infoList addObject:info];
        }
    }
    [self rrs_applyReadReceiptInfoList:infoList
                         conversations:nil
                    skipsZeroReadCount:NO
                    requiresNeedReceipt:YES
              updatesOnlyZeroReadCount:YES];
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
    [self rrs_applyReadReceiptInfoList:infoList
                         conversations:conversations
                    skipsZeroReadCount:YES
                    requiresNeedReceipt:NO
              updatesOnlyZeroReadCount:NO];
}

- (void)rrs_applyReadReceiptInfoList:(NSArray<NCMessageReadReceiptInfo *> *)infoList
                       conversations:(NSArray<NCChannelModel *> *)conversations
                  skipsZeroReadCount:(BOOL)skipsZeroReadCount
                  requiresNeedReceipt:(BOOL)requiresNeedReceipt
            updatesOnlyZeroReadCount:(BOOL)updatesOnlyZeroReadCount {
    if (infoList.count == 0) {
        return;
    }
    NSMutableDictionary<NSString *, NCMessageReadReceiptInfo *> *receiptInfoByKey = [NSMutableDictionary dictionary];
    for (NCMessageReadReceiptInfo *info in infoList) {
        if (skipsZeroReadCount && info.readCount == 0) {// 已读为0 , 不处理
            continue;
        }
        NSString *key = NCReadReceiptKeyForInfo(info);
        if (key.length > 0) {
            receiptInfoByKey[key] = info;
        }
    }
    if (receiptInfoByKey.count == 0) {
        return;
    }

    for (NCChannelModel *model in conversations) {// 先刷请求数据
        NSString *key = NCReadReceiptKeyForModel(model);
        NCMessageReadReceiptInfo *info = key.length > 0 ? receiptInfoByKey[key] : nil;
        if (info && [model lastMessageIsSend]) {
            model.readReceiptInfo = info;
        }
    }

    NSMutableArray<NSIndexPath *> *affectedIndexPaths = [NSMutableArray array];
    NSMutableArray<NCChannelModel *> *affectedModels = [NSMutableArray array];
    NSMutableSet<NSString *> *affectedRows = [NSMutableSet set];
    [self.dataList enumerateObjectsUsingBlock:^(NCChannelModel *model, NSUInteger idx, BOOL *stop) {
        (void)stop;
        NSString *key = NCReadReceiptKeyForModel(model);
        NCMessageReadReceiptInfo *info = key.length > 0 ? receiptInfoByKey[key] : nil;
        if (!info || ![model lastMessageIsSend]) {
            return;
        }
        if (requiresNeedReceipt && !model.needReceipt) {
            return;
        }
        if (updatesOnlyZeroReadCount && model.readReceiptInfo.readCount != 0) {
            return;
        }
        model.readReceiptInfo = info;
        NSString *rowKey = [NSString stringWithFormat:@"%lu", (unsigned long)idx];
        if ([affectedRows containsObject:rowKey]) {
            return;
        }
        [affectedRows addObject:rowKey];
        [affectedIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)idx inSection:0]];
        [affectedModels addObject:model];
    }];

    [self rrs_reloadReadReceiptAffectedIndexPaths:affectedIndexPaths models:affectedModels];
}

- (void)rrs_reloadReadReceiptAffectedIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
                                         models:(NSArray<NCChannelModel *> *)models {
    if (indexPaths.count == 0) {
        return;
    }
    // 回执处理可能运行在后台线程（updateEventQueue 或读回执请求回调），
    // 而 delegate 会直接刷新 UITableView，必须切回主线程执行，避免后台线程操作 UIKit 崩溃。
    if (![NSThread isMainThread]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf rrs_reloadReadReceiptAffectedIndexPaths:indexPaths models:models];
        });
        return;
    }
    if ([self.delegate respondsToSelector:@selector(dataSource:willReloadAtIndexPaths:)]) {
        [self.delegate dataSource:self willReloadAtIndexPaths:indexPaths];
        return;
    }
    for (NCChannelModel *model in models) {
        NCChannelListCellUpdateInfo *updateInfo = [[NCChannelListCellUpdateInfo alloc] init];
        updateInfo.model = model;
        updateInfo.updateType = NCChannelListCellSentStatusUpdate;
        [[NSNotificationCenter defaultCenter] postNotificationName:NCChatUIChannelListCellUpdateNotification
                                                            object:updateInfo
                                                          userInfo:nil];
    }
}

@end
