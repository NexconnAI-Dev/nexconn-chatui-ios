//
//  NCChannelListDataSource.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelListDataSource.h"
#import <NexconnChatUI/NCChatUILog.h>
#import "NCChatUI.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCChannelListCellUpdateInfo.h"
#import "NCChatUIConfig.h"
#import "NCChannelNotificationDataContext.h"
#import "NCChannelListDataSource+RRS.h"
#import "NCUserOnlineStatusManager.h"
#import "NCUserOnlineStatusUtil.h"
#import "NCUserInfoCacheManager.h"
#import "NSMutableArray+NCOperation.h"
#import "NSMutableDictionary+NCOperation.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

#define PagingCount 100

@interface NCChannelListDataSource ()<NCMessageHandler, NCChatUIMessageEventObserver, NCUserOnlineStatusManagerDelegate>
@property (nonatomic, strong) dispatch_queue_t updateEventQueue;
@property (nonatomic, assign) NSInteger currentCount;
@property (nonatomic, copy) void(^throttleReloadAction)(void);
@property (nonatomic, strong, nullable) NCChannelsQuery *channelsQuery;
@property (nonatomic, strong) NSMutableSet<NSString *> *conversationKeySet;
@end

@implementation NCChannelListDataSource
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.updateEventQueue = dispatch_queue_create("ai.nexconn.conversation.updateEventQueue", NULL);
        self.currentCount = 0;
        self.conversationKeySet = [[NSMutableSet alloc] init];
        self.dataList = [[NSMutableArray alloc] init];
        self.isConverstaionListAppear = NO;
        self.cellBackgroundColor = NCDynamicColor(@"channel-list_background_color");
        self.topCellBackgroundColor = NCDynamicColor(@"channel_stick_color");
        [self registerNotifications];
        
        [NCUserOnlineStatusManager sharedManager].delegate = self;
    }
    return self;
}

- (void)setDisplayConversationTypeArray:(NSArray *)displayConversationTypeArray {
    _displayConversationTypeArray = [displayConversationTypeArray copy];
    self.channelsQuery = nil;
}

- (void)setDataList:(NSMutableArray *)dataList {
    _dataList = dataList ?: [[NSMutableArray alloc] init];
    [self rebuildConversationKeySet];
}

- (void)loadMoreConversations:(void (^)(NSMutableArray<NCChannelModel *> *modelList))completion {
    __block NSMutableArray *modelList = [[NSMutableArray alloc] init];
    if ([NCEngine getConnectionStatus] == NCConnectionStatusSignOut) {
        if(completion) {
            completion(modelList);
        }
        return;
    }
    
    __weak typeof(self) ws = self;

    BOOL topPriority = YES;
    if ([self.delegate respondsToSelector:@selector(showConversationOnTopPriority)]) {
        topPriority = [self.delegate showConversationOnTopPriority];
    }

    if (!self.channelsQuery) {
        self.channelsQuery = [self createChannelsQueryWithPageSize:PagingCount topPriority:topPriority];
    }
    if (!self.channelsQuery) {
        if (completion) {
            completion(modelList);
        }
        return;
    }
    [self.channelsQuery loadNextPageWithCompletion:^(NSArray<NCBaseChannel *> * _Nullable channels, NCError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(modelList);
                }
            });
            return;
        }

        [ws updateNotificationContextForChannels:channels];
        [ws buildConversationPageFromChannels:channels completion:^(NSMutableArray<NCChannelModel *> *builtModels) {
            if (!ws) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!ws) {
                    return;
                }
                NSMutableArray<NCChannelModel *> *filteredModels = [builtModels mutableCopy];
                if (filteredModels.count > 0 &&
                    ws.delegate &&
                    [ws.delegate respondsToSelector:@selector(dataSource:willReloadTableData:)]) {
                    filteredModels = [ws.delegate dataSource:ws willReloadTableData:filteredModels];
                }

                NSMutableArray<NSIndexPath *> *insertIndexPaths = [NSMutableArray array];
                NSMutableArray<NCChannelModel *> *insertedModels = [NSMutableArray array];
                for (NCChannelModel *model in filteredModels) {
                    if (![ws containsConversationModel:model]) {
                        model.topCellBackgroundColor = ws.topCellBackgroundColor;
                        model.cellBackgroundColor = ws.cellBackgroundColor;
                        [ws.dataList addObject:model];
                        [ws.conversationKeySet addObject:[ws conversationKeyForModel:model]];
                        [insertedModels addObject:model];
                        [insertIndexPaths addObject:[NSIndexPath indexPathForRow:ws.dataList.count - 1
                                                                      inSection:0]];
                    }
                }
                ws.currentCount = ws.dataList.count;

                if (insertIndexPaths.count > 0 &&
                    ws.delegate &&
                    [ws.delegate respondsToSelector:@selector(dataSource:willInsertAtIndexPaths:)]) {
                    [ws.delegate dataSource:ws willInsertAtIndexPaths:insertIndexPaths];
                }

                [ws rrs_refreshCachedAndFetchReceiptInfo:insertedModels];
                [ws fetchUserProfile:insertedModels];
                [ws fetchUserOnlineStatus:insertedModels.copy];
                if (completion) {
                    completion(insertedModels);
                }
            });
        }];
    }];
}

- (BOOL)containsConversationModel:(NCChannelModel *)model {
    NSString *key = [self conversationKeyForModel:model];
    if (key.length == 0) {
        return NO;
    }
    return [self.conversationKeySet containsObject:key];
}

- (NSString *)conversationKeyForModel:(NCChannelModel *)model {
    return [self conversationKeyForChannelType:model.channelType
                                     channelId:model.channelId
                                  subChannelId:model.subChannelId];
}

- (NSString *)conversationKeyForChannelType:(NCChannelType)channelType
                                  channelId:(NSString *)channelId
                               subChannelId:(NSString *)subChannelId {
    if (channelId.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%lu|%@|%@",
                                      (unsigned long)channelType,
                                      channelId,
                                      subChannelId ?: @""];
}

- (void)rebuildConversationKeySet {
    [self.conversationKeySet removeAllObjects];
    for (NCChannelModel *model in self.dataList) {
        NSString *key = [self conversationKeyForModel:model];
        if (key.length > 0) {
            [self.conversationKeySet addObject:key];
        }
    }
}

- (void)forceLoadConversationModelList:(void (^)(NSMutableArray<NCChannelModel *> *modelList))completion {
    dispatch_async(self.updateEventQueue, ^{
        __block NSMutableArray<NCChannelModel *> *modelList = [[NSMutableArray alloc] init];
        NCLogI(@"forceLoadConversationModelList begin, status=%@, currentCount=%@",
               @([NCEngine getConnectionStatus]),
               @(self.currentCount));
        BOOL topPriority = YES;
        if ([self.delegate respondsToSelector:@selector(showConversationOnTopPriority)]) {
            topPriority = [self.delegate showConversationOnTopPriority];
        }
        void (^finishForceLoad)(void) = ^{
            self.currentCount = modelList.count;
            NCLogI(@"forceLoadConversationModelList finish, modelCount=%@",
                   @(modelList.count));
            if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willReloadTableData:)]) {
                modelList = [self.delegate dataSource:self willReloadTableData:modelList];
            }

            [self rrs_refreshCachedAndFetchReceiptInfo:modelList];
            [self fetchUserProfile:modelList];

            dispatch_async(dispatch_get_main_queue(), ^{
                self.dataList = modelList;
                [self fetchUserOnlineStatus:modelList.copy];
                if (completion) {
                    completion(modelList);
                }
            });
        };

        if ([NCEngine getConnectionStatus] == NCConnectionStatusSignOut) {
            finishForceLoad();
            return;
        }

        self.channelsQuery = [self createChannelsQueryWithPageSize:PagingCount topPriority:topPriority];
        if (!self.channelsQuery) {
            finishForceLoad();
            return;
        }

        __weak typeof(self) weakSelf = self;
        __block void (^loadNextPage)(void) = nil;
        loadNextPage = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || !strongSelf.channelsQuery) {
                finishForceLoad();
                return;
            }

            [strongSelf.channelsQuery loadNextPageWithCompletion:^(NSArray<NCBaseChannel *> * _Nullable channels, NCError * _Nullable error) {
                NCLogI(@"forceLoadConversationModelList page callback, error=%@, channelCount=%@",
                       error.code ? @(error.code) : @(0),
                       @(channels.count));
                if (error) {
                    dispatch_async(strongSelf.updateEventQueue, ^{
                        finishForceLoad();
                    });
                    return;
                }

                [strongSelf updateNotificationContextForChannels:channels];
                [strongSelf buildConversationPageFromChannels:channels completion:^(NSMutableArray<NCChannelModel *> *builtModels) {
                    dispatch_async(strongSelf.updateEventQueue, ^{
                        for (NCChannelModel *model in builtModels) {
                            model.topCellBackgroundColor = strongSelf.topCellBackgroundColor;
                            model.cellBackgroundColor = strongSelf.cellBackgroundColor;
                            NCLogI(@"conversation channelId:%@,channelType:%@,unreadMessageCount:%@",
                                   model.channelId,
                                   @(model.channelType),
                                   @(model.unreadMessageCount));
                            [modelList addObject:model];
                        }
                        if (channels.count >= PagingCount) {
                            loadNextPage();
                        } else {
                            finishForceLoad();
                        }
                    });
                }];
            }];
        };
        loadNextPage();
    });
}

- (nullable NCChannelsQuery *)createChannelsQueryWithPageSize:(int32_t)pageSize topPriority:(BOOL)topPriority {
    if (self.displayConversationTypeArray.count == 0) {
        return nil;
    }

    NCChannelsQueryParams *params = [[NCChannelsQueryParams alloc] init];
    params.channelTypes = self.displayConversationTypeArray;
    params.pageSize = pageSize;
    params.topPriority = topPriority;
    return [NCBaseChannel createChannelsQueryWithParams:params];
}

- (BOOL)isSupportedListRefreshChannelType:(NCChannelType)channelType {
    switch (channelType) {
        case NCChannelTypeDirect:
        case NCChannelTypeGroup:
        case NCChannelTypeSystem:
        case NCChannelTypeCommunity:
            return YES;
        case NCChannelTypeOpen:
        default:
            return NO;
    }
}

- (void)buildConversationPageFromChannels:(NSArray<NCBaseChannel *> *)channels
                               completion:(void (^)(NSMutableArray<NCChannelModel *> *modelList))completion {
    if (channels.count == 0) {
        completion([[NSMutableArray alloc] init]);
        return;
    }

    NSMutableArray<NCChannelModel *> *modelList = [[NSMutableArray alloc] initWithCapacity:channels.count];
    for (NCBaseChannel *channel in channels) {
        NCChannelModel *model = [[NCChannelModel alloc] initWithChannel:channel extend:nil];
        if (!model.channelId.length) {
            continue;
        }
        [modelList addObject:model];
    }
    completion(modelList);
}

- (void)updateNotificationContextForChannels:(NSArray<NCBaseChannel *> *)channels {
    if (channels.count == 0) {
        return;
    }
    [NCChannelNotificationDataContext updateNotificationLevelWith:channels];
}

- (void)getChannelByChannelType:(NCChannelType)channelType
                      channelId:(NSString *)channelId
                   subChannelId:(NSString *)subChannelId
                     completion:(void (^)(NCBaseChannel * _Nullable channel))completion {
    if (channelId.length == 0 || ![self isSupportedListRefreshChannelType:channelType]) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    NCChannelIdentifier *identifier = nil;
    if (channelType == NCChannelTypeCommunity && subChannelId.length > 0) {
        identifier = [[NCCommunitySubChannelIdentifier alloc] initWithChannelId:channelId
                                                                   subChannelId:subChannelId];
    } else {
        identifier = [[NCChannelIdentifier alloc] initWithChannelType:channelType
                                                            channelId:channelId];
    }
    [NCBaseChannel getChannels:@[identifier] completion:^(NSArray<NCBaseChannel *> * _Nullable channels, NCError * _Nullable error) {
        if (completion) {
            completion(error == nil ? channels.firstObject : nil);
        }
    }];
}

- (NSUInteger)getFirstModelIndex:(BOOL)isTop sentTime:(long long)sentTime {
    if (isTop || self.dataList.count == 0) {
        return 0;
    } else {
        for (NSUInteger index = 0; index < self.dataList.count; index++) {
            NCChannelModel *model = self.dataList[index];
            if (model.isTop == isTop && sentTime >= model.sentTime) {
                return index;
            }
        }
        return self.dataList.count - 1;
    }
}

- (void)refreshConversationForChannelType:(NCChannelType)channelType
                                channelId:(NSString *)channelId
                             subChannelId:(NSString *)subChannelId {
    [self refreshConversationModelWithChannelType:channelType
                                        channelId:channelId
                                     subChannelId:subChannelId];
}

- (void)syncUnreadStatusForChannelIdentifier:(NCChannelIdentifier *)identifier {
    if (!identifier || ![self isSupportedListRefreshChannelType:identifier.channelType]) {
        return;
    }

    NSString *channelId = identifier.channelId ?: @"";
    NSString *subChannelId = nil;
    if ([identifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]) {
        subChannelId = ((NCCommunitySubChannelIdentifier *)identifier).subChannelId;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        NCChannelModel *matchingModel = nil;
        for (NCChannelModel *model in self.dataList) {
            if ([self model:model
         matchesChannelType:identifier.channelType
                  channelId:channelId
               subChannelId:subChannelId]) {
                matchingModel = model;
                break;
            }
        }
        if (!matchingModel) {
            return;
        }

        [self getChannelByChannelType:identifier.channelType
                            channelId:channelId
                         subChannelId:subChannelId
                           completion:^(NCBaseChannel * _Nullable channel) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (channel) {
                    matchingModel.unreadMessageCount = channel.unreadCount;
                    matchingModel.mentionedCount = (int)channel.mentionedCount;
                    [self refreshConversationModelWithChannelType:matchingModel.channelType
                                                        channelId:matchingModel.channelId
                                                     subChannelId:matchingModel.subChannelId];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(notifyUpdateUnreadMessageCountInDataSource)]) {
                        [self.delegate notifyUpdateUnreadMessageCountInDataSource];
                    }
                    return;
                }

                [self getConversationUnreadCount:matchingModel completion:^(int unreadMessageCount) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        matchingModel.unreadMessageCount = unreadMessageCount;
                        if (unreadMessageCount == 0) {
                            matchingModel.mentionedCount = 0;
                        }
                        [self refreshConversationModelWithChannelType:matchingModel.channelType
                                                            channelId:matchingModel.channelId
                                                         subChannelId:matchingModel.subChannelId];
                        if (self.delegate && [self.delegate respondsToSelector:@selector(notifyUpdateUnreadMessageCountInDataSource)]) {
                            [self.delegate notifyUpdateUnreadMessageCountInDataSource];
                        }
                    });
                }];
            });
        }];
    });
}

- (BOOL)model:(NCChannelModel *)model
matchesChannelType:(NCChannelType)channelType
      channelId:(NSString *)channelId
   subChannelId:(NSString *)subChannelId {
    if (![model isMatchingChannelType:channelType channelId:channelId]) {
        return NO;
    }
    NSString *leftSubChannelId = model.subChannelId ?: @"";
    NSString *rightSubChannelId = subChannelId ?: @"";
    return [leftSubChannelId isEqualToString:rightSubChannelId];
}

- (void)refreshConversationModelWithChannelType:(NCChannelType)channelType
                                      channelId:(NSString *)channelId
                                   subChannelId:(NSString *)subChannelId {
    if (![self isSupportedListRefreshChannelType:channelType]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NCChannelModel *matchingModel = nil;
        for (NCChannelModel *model in self.dataList) {
            if ([self model:model
         matchesChannelType:channelType
                  channelId:channelId
               subChannelId:subChannelId]) {
                matchingModel = model;
                break;
            }
        }

        if (matchingModel) {
            NSUInteger oldIndex = [self.dataList indexOfObject:matchingModel];
            NSUInteger newIndex = [self getFirstModelIndex:matchingModel.isTop sentTime:matchingModel.sentTime];

            if (oldIndex == newIndex) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willReloadAtIndexPaths:)]) {
                    [self.delegate dataSource:self willReloadAtIndexPaths:@[ [NSIndexPath indexPathForRow:newIndex inSection:0]]];
                }
            } else {
                [self.dataList removeObjectAtIndex:oldIndex];
                [self.dataList insertObject:matchingModel atIndex:newIndex];
                [self rebuildConversationKeySet];
                if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willDeleteAtIndexPaths:willInsertAtIndexPaths:)]) {
                    [self.delegate dataSource:self willDeleteAtIndexPaths:@[ [NSIndexPath indexPathForRow:oldIndex inSection:0] ] willInsertAtIndexPaths:@[ [NSIndexPath indexPathForRow:newIndex inSection:0] ]];
                }
            }
        } else {
            [self getChannelByChannelType:channelType
                                channelId:channelId
                             subChannelId:subChannelId
                               completion:^(NCBaseChannel * _Nullable channel) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NCChannelModel *newModel = nil;
                    if (channel) {
                        newModel = [[NCChannelModel alloc] initWithChannel:channel extend:nil];
                    } else {
                        newModel = [[NCChannelModel alloc] init];
                        newModel.channelType = channelType;
                        newModel.channelId = channelId;
                        newModel.subChannelId = subChannelId;
                    }
                    newModel.topCellBackgroundColor = self.topCellBackgroundColor;
                    newModel.cellBackgroundColor = self.cellBackgroundColor;
                    NSUInteger newIndex = [self getFirstModelIndex:newModel.isTop sentTime:newModel.sentTime];
                    [self.dataList insertObject:newModel atIndex:newIndex];
                    [self.conversationKeySet addObject:[self conversationKeyForModel:newModel]];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willInsertAtIndexPaths:)]) {
                        [self.delegate dataSource:self willInsertAtIndexPaths:@[ [NSIndexPath indexPathForRow:newIndex inSection:0] ]];
                    }
                    [self rrs_refreshCachedAndFetchReceiptInfo:@[newModel]];
                });
            }];
        }
    });
}

#pragma mark - Notification
- (void)onMessageSentStatusUpdate:(NSNotification *)notification {
    NSDictionary *statusDic = notification.userInfo;

    if (statusDic) {
        // Update the message status.
        long clientId = [statusDic[@"clientId"] longValue];
        NSString *channelId = statusDic[@"channelId"];
        NSString *subChannelId = statusDic[@"subChannelId"];
        NCMessageSentStatus sentStatus = (NCMessageSentStatus)[statusDic[@"sentStatus"] integerValue];
        NCMessage *statusMessage = [statusDic[@"message"] isKindOfClass:[NCMessage class]] ? statusDic[@"message"] : nil;
        if (clientId == 0 || channelId.length == 0) {
            return;
        }
        dispatch_async(self.updateEventQueue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *arrayDataList = [self.dataList copy];
                for (NCChannelModel *model in arrayDataList) {
                    if ([model isMatchingChannelType:model.channelType
                                           channelId:channelId]) {
                        NSString *leftSubChannelId = model.subChannelId ?: @"";
                        NSString *rightSubChannelId = subChannelId ?: @"";
                        if (![leftSubChannelId isEqualToString:rightSubChannelId]) {
                            continue;
                        }
                        NCChannelListCellUpdateInfo *updateInfo = [[NCChannelListCellUpdateInfo alloc] init];
                        if (model.latestMessageClientId == clientId) {
                            if (sentStatus == NCMessageSentStatusSent && statusMessage) {
                                [model updateWithMessage:statusMessage];
                            } else {
                                model.sentStatus = sentStatus;
                            }
                        }
                        updateInfo.model = model;
                        updateInfo.updateType = NCChannelListCellMessageContentUpdate;
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:NCChatUIChannelListCellUpdateNotification
                         object:updateInfo
                         userInfo:nil];
                        break;
                    }
                }
            });
        });
    }
}

#pragma mark - NCMessageHandler

- (void)onMessageDeleted:(NCMessageDeletedEvent *)event {
    if (event.messages.count == 0 || !self.isConverstaionListAppear) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(refreshConversationTableViewIfNeededInDataSource:)]) {
            [self.delegate refreshConversationTableViewIfNeededInDataSource:self];
        }
    });
}

- (void)registerNotifications {
    [[NCChatUI shared] addMessageEventObserver:self];
    [NCEngine addMessageHandlerWithIdentifier:@"NCChannelListDS" handler:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMessageSentStatusUpdate:)
                                                 name:@"NCUISendingMessageNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUserOnlineStatusChangedNotification:)
                                                 name:NCChatUIUserOnlineStatusChangedNotification
                                               object:nil];
    
}

#pragma mark - helper
- (void(^)(void))getThrottleActionWithTimeInteval:(double)timeInteval action:(void(^)(void))action {
    __block BOOL canAction = NO;
    return ^{
        if (canAction == NO) {
            canAction = YES;
        } else {
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInteval * NSEC_PER_SEC)), self.updateEventQueue, ^{
            canAction = NO;
            action();
        });
    };
}

- (void)getConversationUnreadCount:(NCChannelModel *)model completion:(void (^)(int unreadMessageCount))completion {
    NCChannelIdentifier *identifier = [[NCChannelIdentifier alloc] initWithChannelType:model.channelType
                                                                             channelId:model.channelId ?: @""];
    [NCBaseChannel getChannels:@[identifier] completion:^(NSArray<NCBaseChannel *> * _Nullable channels, NCError * _Nullable error) {
        if (channels.firstObject) {
            completion((int)channels.firstObject.unreadCount);
        } else {
            completion(0);
        }
    }];
}

- (void)deleteConversation:(NCChannelModel *)model completion:(void (^)(BOOL success))completion {
    if (model.channelType <= 0) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    NCChannelIdentifier *identifier = [[NCChannelIdentifier alloc] initWithChannelType:(NCChannelType)model.channelType
                                                                             channelId:model.channelId ?: @""];
    [NCBaseChannel deleteChannels:@[identifier] completion:^(NCError * _Nullable error) {
        if (completion) {
            completion(error == nil);
        }
    }];
}

#pragma mark - getter

- (void (^)(void))throttleReloadAction{
    if (!_throttleReloadAction) {
        __weak typeof(self) weakSelf = self;
        _throttleReloadAction = [self getThrottleActionWithTimeInteval:0.5 action:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.delegate &&
                [strongSelf.delegate respondsToSelector:@selector(refreshConversationTableViewIfNeededInDataSource:)]) {
                [strongSelf.delegate refreshConversationTableViewIfNeededInDataSource:strongSelf];
            }
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(notifyUpdateUnreadMessageCountInDataSource)]) {
                [strongSelf.delegate notifyUpdateUnreadMessageCountInDataSource];
            }
        }];
    }
    return _throttleReloadAction;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NCChatUI shared] removeMessageEventObserver:self];
    [NCEngine removeMessageHandlerForIdentifier:@"NCChannelListDS"];
}

- (void)onMessagesUpdated:(NCMessagesUpdatedEvent *)event {
    if (!self.isConverstaionListAppear) {
        return;
    }
    NSArray<NCMessage *> *messages = event.messages;
    if (messages.count == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(refreshConversationTableViewIfNeededInDataSource:)]) {
            [self.delegate refreshConversationTableViewIfNeededInDataSource:self];
        }
    });
}

- (void)onReceivedMessage:(NCMessage *)message left:(int)left offline:(BOOL)offline {
    (void)message;
    (void)offline;
    dispatch_async(self.updateEventQueue, ^{
        if (self.isConverstaionListAppear) {
            self.throttleReloadAction();
        } else if (left == 0) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(notifyUpdateUnreadMessageCountInDataSource)]) {
                [self.delegate notifyUpdateUnreadMessageCountInDataSource];
            }
        }
    });
}

#pragma mark - Read Receipts
- (void)onMessageReceiptResponse:(NCMessageReceiptResponseEvent *)event {
    if (!self.isConverstaionListAppear) {// Ignore updates while the channel list is hidden.
        return;
    }
    dispatch_async(self.updateEventQueue, ^{
        [self rrs_didReceiveMessageReadReceiptResponses:event.responses];
    });
}

- (void)onUserOnlineStatusChangedNotification:(NSNotification *)notification {
    NSArray<NSString *> *userIds = notification.userInfo[NCChatUIUserOnlineStatusChangedUserIdsKey];
    NSMutableDictionary<NSString *, NCChannelModel *> *userIdToModel = [NSMutableDictionary dictionaryWithCapacity:self.dataList.count];
    for (NCChannelModel *model in self.dataList) {
        if (model.channelId.length > 0 && [model isChannelType:NCChannelTypeDirect]) {
            userIdToModel[model.channelId] = model;
        }
    }
    for (NSString *userId in userIds) {
        NCChannelModel *model = userIdToModel[userId];
        if (model) {
            model.onlineStatus = [[NCUserOnlineStatusManager sharedManager] getCachedOnlineStatus:userId];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NCChatUIConversationCellOnlineStatusUpdateNotification object:nil userInfo:notification.userInfo];
}

#pragma mark - NCUserOnlineStatusManagerDelegate

- (NSArray<NSString *> *)userIdsNeedOnlineStatus:(NCUserOnlineStatusManager *)manager {
    // Collect users whose presence should be displayed.
    NSMutableArray *needShowUserIds = [NSMutableArray array];
    for (NCChannelModel *model in self.dataList) {
        if ([model isChannelType:NCChannelTypeDirect]
            && model.conversationModelType == NC_CONVERSATION_MODEL_TYPE_NORMAL
            && model.channelId) {
            [needShowUserIds addObject:model.channelId];
        }
    }
    return needShowUserIds;
}

- (void)fetchUserOnlineStatus:(NSArray <NCChannelModel *>*)modelList {
    if (![NCUserOnlineStatusUtil shouldDisplayOnlineStatus]) {
        return;
    }
    // Collect direct channels that display presence.
    NSMutableArray *fetchUserIds = [NSMutableArray array];
    for (NCChannelModel *model in modelList) {
        if ([model isChannelType:NCChannelTypeDirect]
            && model.conversationModelType == NC_CONVERSATION_MODEL_TYPE_NORMAL) {
            model.displayOnlineStatus = YES;
            NCSubscribeUserOnlineStatus *status = [NCUserOnlineStatusManager.sharedManager getCachedOnlineStatus:model.channelId];
            if (status) {
                model.onlineStatus = status;
            } else {
                [fetchUserIds addObject:model.channelId];
            }
        }
    }
    // Fetch presence for users without cached status.
    if (fetchUserIds.count > 0) {
        [NCUserOnlineStatusManager.sharedManager fetchOnlineStatus:fetchUserIds];
    }
}

- (void)fetchUserProfile:(NSArray <NCChannelModel *>*)modelList {
    NSMutableArray<NSString *> *userIds = [NSMutableArray arrayWithCapacity:modelList.count];
    NSMutableArray<NSString *> *groupIds = [NSMutableArray arrayWithCapacity:modelList.count];
    NSMutableDictionary<NSString *, NSString*> *groupMember = [NSMutableDictionary dictionary];
    for (NCChannelModel *model in modelList) {
        if ([model isChannelType:NCChannelTypeDirect]) {
            [userIds nc_addObject:model.channelId];
        } else if ([model isChannelType:NCChannelTypeGroup]) {
            [groupIds nc_addObject:model.channelId];
            [groupMember nc_setObject:model.senderUserId forKey:model.channelId];
        }
    }
    if (userIds.count > 0) {
        [NCUserInfoCacheManager.sharedManager preloadUserInfos:userIds];
    }
    if (groupIds.count > 0) {
        [NCUserInfoCacheManager.sharedManager preloadGroupInfos:groupIds];
    }
    
    for (NSString *groupId in [groupMember.allKeys copy]) {
        NSString *member = [groupMember valueForKey:groupId];
        if (member) {
            [NCUserInfoCacheManager.sharedManager preloadGroupMembers:@[member] inGroup:groupId];
        }
    }
    
}
@end
