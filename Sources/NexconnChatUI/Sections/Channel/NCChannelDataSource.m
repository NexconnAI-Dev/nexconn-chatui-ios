//
//  NCChannelDataSource.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelDataSource.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCMessageModel.h"
#import "NCChannelViewController.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCChannelVCUtil.h"
#import "NCChannelCollectionViewHeader.h"
#import "NCChannelViewLayout.h"
#import "NCOldMessageNotificationMessage.h"
#import "NCChatUI.h"
#import "NCChatUIErrorCode.h"
#import "NCChatUICommonDefine.h"
#import "NCMessageCell.h"
#import "NCChannelViewController+internal.h"
#import "NCAlertView.h"
#import "NCStreamMessageCell.h"
#import "NCChannelDataSource+Edit.h"
#import "NCChannelViewController+Edit.h"
#import "NCChannelDataSource+RRS.h"
#import "NCMenuController.h"
#import "NCRRSUtil.h"

#define COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT 30
#define COLLECTION_VIEW_CELL_MAX_COUNT 3000
#define COLLECTION_VIEW_CELL_REMOVE_COUNT 200

typedef NS_ENUM(NSUInteger, NCChannelHistoryMessageOrder) {
    NCChannelHistoryMessageOrderAsc,
    NCChannelHistoryMessageOrderDesc,
};

static NSString *NCConversationMessageHandlerIdentifier(NCChannelViewController *chatVC) {
    return [NSString stringWithFormat:@"ai.nexconn.chatui.datasource.message.%ld.%@.%@",
                                      (long)chatVC.channelType, chatVC.channelId ?: @"",
                                      chatVC.subChannelId ?: @""];
}

@interface NCChannelDataSource (EditPrivate)

/// Fetches the latest referenced message content and edit state.
- (void)edit_refreshReferenceMessage:(NSArray<NCMessage *> *)messages
                            complete:(void (^)(NSArray<NCMessage *> *messages))complete;
- (void)edit_cleanupAllReferenceRefreshContexts;

@end

@interface NCChannelDataSource (DeletedMessagePrivate)

- (void)p_updateDeletedReferenceMessagesWithMessage:(nullable NCMessage *)message;

@end

@interface NCChannelViewController (NCMessageFilterPrivate)
- (NCMessage *)willAppendAndDisplayMessage:(NCMessage *)message;
- (void)updateForMessageSendSuccess:(NCMessage *)message;
@end

@class NCChannelDataSource;

@interface NCChannelDataSource () <NCMessageHandler, NCChatUIMessageEventObserver>

@property (nonatomic, weak) NCChannelViewController *chatVC;
@property (nonatomic, strong) NSOperationQueue *appendMessageQueue;

@property (nonatomic, assign) BOOL isLoadingHistoryMessage; // Whether history is being loaded.

@property (nonatomic, assign)
    BOOL isShowingLastestMessage; // Whether the newest message is visible.

@property (nonatomic, assign)
    BOOL allMessagesAreLoaded; /// YES when all messages are loaded; NO when more remain.
@property (nonatomic, assign) BOOL isIndicatorLoading;

@property (nonatomic, assign) long long recordTime;
@property (nonatomic, assign)
    long long showUnreadViewMessageId; // Message ID used by the unread jump control.

// Collection view layout for the channel page.
@property (nonatomic, strong) NCChannelViewLayout *customFlowLayout;
@property (nonatomic, strong) NCMessage
    *firstUnreadMessage; // Captured on entry because loading messages changes unread state.
@property (nonatomic, copy) void (^throttleReloadAction)(void);

// Whether unread controls should be checked after tapping a mention jump button.
@property (nonatomic, assign) BOOL hideUnreadBtnForMentioned;
@property (nonatomic, copy) NSString *ncMessageHandlerIdentifier;
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *receivedMessageDedupKeys;
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *modifiedMessageDedupKeys;
@property (nonatomic, strong) NSMutableArray<NCMessagesQuery *> *activeMessagesQueries;
@property (nonatomic, strong)
    NSMutableArray<NCLocalMessagesByTimeQuery *> *activeLocalMessagesQueries;
@property (nonatomic, strong) NSMutableSet *referenceRefreshContexts;
@property (nonatomic, assign) BOOL didCleanupForChannelRelease;

- (void)cleanupForChannelViewControllerRelease;

@end

@implementation NCChannelDataSource
- (instancetype)init:(NCChannelViewController *)chatVC {
    self = [super init];
    if (self) {
        self.cachedReloadMessages = [NSMutableArray new];
        self.chatVC = chatVC;
        self.allMessagesAreLoaded = NO;
        self.isShowingLastestMessage = YES;
        self.customFlowLayout = [[NCChannelViewLayout alloc] init];
        self.isIndicatorLoading = NO;
        self.unreadNewMsgArr = [NSMutableArray new];

        self.appendMessageQueue = [NSOperationQueue new];
        self.appendMessageQueue.maxConcurrentOperationCount = 1;
        self.appendMessageQueue.name = @"ai.nexconn.appendMessageQueue";
        self.unreadMentionedMessages = [[NSMutableArray alloc] init];
        self.receivedMessageDedupKeys = [[NSMutableOrderedSet alloc] init];
        self.modifiedMessageDedupKeys = [[NSMutableOrderedSet alloc] init];
        self.activeMessagesQueries = [[NSMutableArray alloc] init];
        self.activeLocalMessagesQueries = [[NSMutableArray alloc] init];
        self.referenceRefreshContexts = [[NSMutableSet alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(streamMessageCellDidUpdate:)
                                                     name:NCStreamMessageCellUpdateEndNotification
                                                   object:nil];
        self.ncMessageHandlerIdentifier = NCConversationMessageHandlerIdentifier(chatVC);
        [NCEngine addMessageHandlerWithIdentifier:self.ncMessageHandlerIdentifier handler:self];
        [[NCChatUI shared] addMessageEventObserver:self];
    }
    return self;
}

- (void)cleanupForChannelViewControllerRelease {
    @synchronized(self) {
        if (self.didCleanupForChannelRelease) {
            return;
        }
        self.didCleanupForChannelRelease = YES;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self cancelAppendMessageQueue];
    self.throttleReloadAction = nil;
    self.loadDelegate = nil;
    [self.cachedReloadMessages removeAllObjects];
    [self.unreadNewMsgArr removeAllObjects];
    [self.unreadMentionedMessages removeAllObjects];
    [self edit_cleanupAllReferenceRefreshContexts];
    self.firstUnreadMessage = nil;

    @synchronized(self) {
        [self.activeMessagesQueries removeAllObjects];
        [self.activeLocalMessagesQueries removeAllObjects];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.ncMessageHandlerIdentifier.length > 0) {
        [NCEngine removeMessageHandlerForIdentifier:self.ncMessageHandlerIdentifier];
    }
    [[NCChatUI shared] removeMessageEventObserver:self];
}

- (void)dealloc {
    [self cleanupForChannelViewControllerRelease];
}

#pragma mark - 消息数据源处理
- (void)getInitialMessage:(NCBaseChannel *)channel {
    [self loadLatestHistoryMessage];
    self.chatVC.unReadMessage = (int)channel.unreadCount;
    if (self.chatVC.unReadMessage) {
        [channel getFirstUnreadMessageWithCompletion:^(NCMessage *_Nullable message,
                                                       NCError *_Nullable error) {
          (void)error;
          dispatch_async(dispatch_get_main_queue(), ^{
            self.firstUnreadMessage = message;
          });
        }];
    }
    if (self.chatVC.channelType == NCChannelTypeGroup) {
        if (NCChatUIConfigCenter.message.enableMessageMentioned) {
            self.chatVC.chatSessionInputBarControl.isMentionedEnabled = YES;
            self.chatVC.editInputBarControl.isMentionedEnabled = YES;
            if (channel.mentionedMeCount > 0) {
                [channel getUnreadMentionedMessagesWithCompletion:^(
                             NSArray<NCMessage *> *_Nullable messages, NCError *_Nullable error) {
                  (void)error;
                  dispatch_async(dispatch_get_main_queue(), ^{
                    self.unreadMentionedMessages = messages.mutableCopy ?: [NSMutableArray array];
                  });
                }];
            }
        }
    }
}

// Loads a page of message history through NCMessagesQuery.
- (void)loadNCMessagesWithPageSize:(NSInteger)pageSize
                              time:(long long)time
                             order:(NCChannelHistoryMessageOrder)order
                        completion:(void (^)(NSArray<NCMessage *> *messages, BOOL isRemaining,
                                             NCChatUIErrorCode code))completion
                          fallback:(void (^)(void))fallback {
    NCChannelIdentifier *channelIdentifier = self.chatVC.currentChannelIdentifier;
    if (!channelIdentifier) {
        if (fallback) {
            fallback();
        }
        return;
    }
    NCMessagesQueryParams *params =
        [[NCMessagesQueryParams alloc] initWithChannelIdentifier:channelIdentifier];
    params.pageSize = pageSize;
    params.startTime = time;
    params.isAscending = (order == NCChannelHistoryMessageOrderAsc);
    NCMessagesQuery *messagesQuery = [NCBaseChannel createMessagesQueryWithParams:params];
    @synchronized(self) {
        [self.activeMessagesQueries addObject:messagesQuery];
    }
    __weak typeof(self) weakSelf = self;
    [messagesQuery loadNextPageWithCompletion:^(NSArray<NCMessage *> *_Nullable messages,
                                                NCError *_Nullable error) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf) {
          @synchronized(strongSelf) {
              [strongSelf.activeMessagesQueries removeObject:messagesQuery];
          }
      }
      NCChatUIErrorCode code = error ? (NCChatUIErrorCode)error.code : NCChatUIErrorCodeSuccess;
      if (completion) {
          completion(messages ?: @[], messagesQuery.hasNextPage, code);
      }
    }];
}

// Loads the initial local page through NCLocalMessagesByTimeQuery.
- (void)loadLocalNCMessagesWithPageSize:(NSInteger)pageSize
                               sentTime:(long long)sentTime
                                  order:(NCChannelHistoryMessageOrder)order
                             completion:(void (^)(NSArray<NCMessage *> *messages,
                                                  NCChatUIErrorCode code))completion
                               fallback:(void (^)(void))fallback {
    NCChannelIdentifier *channelIdentifier = self.chatVC.currentChannelIdentifier;
    if (!channelIdentifier) {
        if (fallback) {
            fallback();
        }
        return;
    }
    NCLocalMessagesByTimeQueryParams *params = [[NCLocalMessagesByTimeQueryParams alloc] init];
    params.channelIdentifier = channelIdentifier;
    params.pageSize = pageSize;
    params.sentTime = sentTime;
    params.isAscending = (order == NCChannelHistoryMessageOrderAsc);
    NCLocalMessagesByTimeQuery *messagesQuery =
        [NCBaseChannel createLocalMessagesByTimeQueryWithParams:params];
    @synchronized(self) {
        [self.activeLocalMessagesQueries addObject:messagesQuery];
    }
    __weak typeof(self) weakSelf = self;
    [messagesQuery loadNextPageWithCompletion:^(NSArray<NCMessage *> *_Nullable messages,
                                                NCError *_Nullable error) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf) {
          @synchronized(strongSelf) {
              [strongSelf.activeLocalMessagesQueries removeObject:messagesQuery];
          }
      }
      NCChatUIErrorCode code = error ? (NCChatUIErrorCode)error.code : NCChatUIErrorCodeSuccess;
      if (completion) {
          completion(messages ?: @[], code);
      }
    }];
}

- (void)appendAndDisplayMessage:(NCMessage *)message {
    if (!message) {
        return;
    }
    __weak typeof(self) ws = self;
    [self.appendMessageQueue addOperationWithBlock:^{
      __strong typeof(ws) strongSelf = ws;
      if (!strongSelf) {
          return;
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(ws) strongSelf = ws;
        if (!strongSelf) {
            return;
        }
        @autoreleasepool {
            NCChannelViewController *chatVC = strongSelf.chatVC;
            NCMessageModel *model = [NCMessageModel modelWithNCMessage:message];
            [chatVC.util figureOutLatestModel:model];
            if ([strongSelf appendMessageModel:model]) {
                [strongSelf.cachedReloadMessages addObject:model];
                strongSelf.throttleReloadAction();
            }
        }
      });
      [NSThread sleepForTimeInterval:0.01];
    }];
}

- (void (^)(void))getThrottleActionWithTimeInteval:(double)timeInteval
                                            action:(void (^)(void))action {
    __block BOOL canAction = NO;
    __weak typeof(self) weakSelf = self;
    return ^{
      if (weakSelf.chatVC.sendMsgAndNeedScrollToBottom) {
          canAction = NO;
          dispatch_main_async_safe(^{
            action();
          });
          return;
      } else if (canAction == NO) {
          canAction = YES;
      } else {
          return;
      }
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInteval * NSEC_PER_SEC)),
                     dispatch_get_main_queue(), ^{
                       if (!canAction) {
                           return;
                       }
                       canAction = NO;
                       action();
                     });
    };
}

- (void (^)(void))throttleReloadAction {
    if (!_throttleReloadAction) {
        __weak typeof(self) ws = self;
        _throttleReloadAction = [self
            getThrottleActionWithTimeInteval:0.3
                                      action:^{
                                        __strong typeof(ws) strongSelf = ws;
                                        if (!strongSelf ||
                                            strongSelf.cachedReloadMessages.count <= 0) {
                                            return;
                                        }
                                        NCChannelViewController *chatVC = strongSelf.chatVC;
                                        NSUInteger dataRepositorycount =
                                            strongSelf.chatVC.channelDataRepository.count;
                                        [chatVC.channelDataRepository
                                            addObjectsFromArray:strongSelf.cachedReloadMessages];

                                        // v5
                                        NSMutableArray *itemToFetchReceipt = [NSMutableArray array];
                                        [itemToFetchReceipt
                                            addObjectsFromArray:strongSelf.cachedReloadMessages];
                                        [strongSelf rrs_fetchReadReceiptInfo:itemToFetchReceipt];

                                        NSInteger itemsCount =
                                            [chatVC.messageCollectionView numberOfItemsInSection:0];
                                        NSInteger differenceValue =
                                            chatVC.channelDataRepository.count - itemsCount;

                                        // 符合insert条件才执行
                                        if (itemsCount > 0 &&
                                            strongSelf.cachedReloadMessages.count ==
                                                differenceValue) {
                                            NSMutableArray *reloadIndexPaths = [NSMutableArray new];
                                            for (int i = 0;
                                                 i < strongSelf.cachedReloadMessages.count; i++) {
                                                NSIndexPath *indexPath = [NSIndexPath
                                                    indexPathForItem:(dataRepositorycount + i)
                                                           inSection:0];
                                                [reloadIndexPaths addObject:indexPath];
                                            }
                                            [chatVC.messageCollectionView
                                                insertItemsAtIndexPaths:reloadIndexPaths];
                                        } else {
                                            [chatVC.messageCollectionView reloadData];
                                        }

                                        [strongSelf.cachedReloadMessages removeAllObjects];

                                        if (chatVC.sendMsgAndNeedScrollToBottom ||
                                            [strongSelf isAtTheBottomOfTableView]) {
                                            [chatVC scrollToBottomAnimated:YES];
                                            chatVC.sendMsgAndNeedScrollToBottom = NO;
                                        } else {
                                            [chatVC updateUnreadMsgCountLabel];
                                        }
                                      }];
    }
    return _throttleReloadAction;
}

- (BOOL)appendMessageModel:(NCMessageModel *)model {
    long newId = model.clientId;
    /*
     fix:PAASIOSDEV-392
     */
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.chatVC.channelDataRepository];
    if (self.cachedReloadMessages.count) {
        [array addObjectsFromArray:self.cachedReloadMessages];
    }
    for (NCMessageModel *__item in array) {

        /*
         * An ID of -1 bypasses duplicate detection and inserts the model directly.
         * This is used for transient informational messages.
         */
        if (newId == -1) {
            break;
        }
        if (newId == __item.clientId) {
            return NO;
        }
    }

    BOOL isUnknown = [NCChatUIUtility isUnkownMessage:model.clientId content:model.content];
    if (isUnknown && !NCChatUIConfigCenter.message
                          .showUnkownMessage) { // Unknown messages are hidden by configuration.
        return NO;
    }
    if (newId != -1 && !model.isPersisted) { // Non-persisted messages are not displayed.
        return NO;
    }

    model = [self setModelIsDisplayNickName:model];
    return YES;
}

- (BOOL)pushOldMessageModel:(NCMessageModel *)model {

    BOOL isUnknown = [NCChatUIUtility isUnkownMessage:model.clientId content:model.content];
    if (isUnknown && !NCChatUIConfigCenter.message
                          .showUnkownMessage) { // Unknown messages are hidden by configuration.
        return NO;
    }
    if (!model.isPersisted) {
        return NO;
    }

    long ne_wId = model.clientId;
    for (NCMessageModel *__item in self.chatVC.channelDataRepository) {

        if (ne_wId == __item.clientId && ne_wId != -1) {
            return NO;
        }
    }
    model = [self setModelIsDisplayNickName:model];
    if ([self appendMessageModel:model]) {
        [self.chatVC.channelDataRepository insertObject:model atIndex:0];
    }
    return YES;
}

- (void)loadLatestHistoryMessage {
    if (self.chatVC.locatedMessageSentTime > 0) {
        [self loadHistorylocatedMessageV2];
    } else {
        [self loadHistoryMessageBeforeTimeV2:0];
        // PAASIOSDEV-77: Avoid repeated input refreshes while history is loading after the user
        // taps New Messages.
        self.isLoadingHistoryMessage = NO;
    }
}

- (void)loadMoreHistoryMessage {
    self.recordTime = 0;
    if (self.chatVC.channelDataRepository.count > 0) {
        for (NCMessageModel *model in self.chatVC.channelDataRepository) {
            if (![model.objectName isEqualToString:NCOldMessageNotificationMessageTypeIdentifier]) {
                self.recordTime = model.sentTime;
                break;
            }
        }
    }
    [self loadHistoryMessageBeforeTimeV2:self.recordTime];
}

- (void)loadMoreHistoryMessageIfNeed {
    if (!self.isIndicatorLoading && !self.allMessagesAreLoaded) {
        self.isIndicatorLoading = YES;
        [self loadMoreHistoryMessage];
    }
}

- (void)loadMoreNewerMessage {
    NCMessageModel *model = self.chatVC.channelDataRepository.lastObject;
    [self loadHistoryMessageAfterTimeV2:model.sentTime];
}

/// Returns the number of messages added to channelDataRepository.
- (void)appendLastestMessageToDataSourceWithCompletion:(void (^)(NSInteger count))completion {
    __weak typeof(self) weakSelf = self;
    [self loadNCMessagesWithPageSize:self.chatVC.defaultMessageCount
        time:0
        order:NCChannelHistoryMessageOrderAsc
        completion:^(NSArray<NCMessage *> *messages, BOOL isRemaining, NCChatUIErrorCode code) {
          (void)isRemaining;
          __strong typeof(weakSelf) strongSelf = weakSelf;
          if (!strongSelf) {
              return;
          }
          dispatch_async(dispatch_get_main_queue(), ^{
            if (code != NCChatUIErrorCodeSuccess || !messages ||
                messages.count < strongSelf.chatVC.defaultMessageCount) {
                strongSelf.isLoadingHistoryMessage = NO;
            }
            NSInteger count = 0;
            NSMutableArray *itemToFetchReceipt = [NSMutableArray array];
            for (NCMessage *message in messages) {
                NCMessage *checkedMessage = [strongSelf.chatVC willAppendAndDisplayMessage:message];
                if (checkedMessage) {
                    NCMessageModel *model = [NCMessageModel modelWithNCMessage:checkedMessage];
                    [strongSelf.chatVC.util figureOutLatestModel:model];
                    [strongSelf.chatVC.channelDataRepository addObject:model];
                    [itemToFetchReceipt addObject:model];
                    count++;
                }
            }
            [strongSelf rrs_fetchReadReceiptInfo:itemToFetchReceipt];
            strongSelf.isIndicatorLoading = NO;
            if (completion) {
                completion(count);
            }
          });
        }
        fallback:^{
          __strong typeof(weakSelf) strongSelf = weakSelf;
          if (!strongSelf) {
              return;
          }
          dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.isLoadingHistoryMessage = NO;
            strongSelf.isIndicatorLoading = NO;
            if (completion) {
                completion(0);
            }
          });
        }];
}
- (void)handleMessagesAfterLoadMore:(NSArray<NCMessage *> *)messages {
    [self handleMessagesAfterLoadMore:messages checkUnreadMessage:YES];
}
- (void)handleMessagesAfterLoadMore:(NSArray<NCMessage *> *)messages
                 checkUnreadMessage:(BOOL)check {
    NSMutableArray *indexPathes =
        [[NSMutableArray alloc] initWithCapacity:self.chatVC.defaultMessageCount];
    int indexPathCount = 0;
    NSMutableArray *itemToFetchReceipt = [NSMutableArray array];

    for (int i = 0; i < messages.count; i++) {
        NCMessage *message = [messages objectAtIndex:i];
        NCMessageModel *model = [NCMessageModel modelWithNCMessage:message];
        // The message data source is in reverse order.

        if ([self pushOldMessageModel:model]) {
            [itemToFetchReceipt addObject:model];
            [indexPathes addObject:[NSIndexPath indexPathForItem:indexPathCount++ inSection:0]];
        }
        if (self.firstUnreadMessage && model.clientId == self.firstUnreadMessage.clientId &&
            self.chatVC.enableUnreadMessageIcon && !self.chatVC.unReadButton.selected &&
            self.chatVC.unReadMessage > self.chatVC.defaultMessageCount) {
            // Guard an empty data source when a channel contains only unregistered custom messages.
            if (self.chatVC.channelDataRepository.count > 0) {
                NCMessageModel *oldModel = [self generateOldMessageModel];
                oldModel.clientId = model.clientId;
                [self.chatVC.channelDataRepository insertObject:oldModel atIndex:0];
                [itemToFetchReceipt addObject:oldModel];
                [indexPathes addObject:[NSIndexPath indexPathForItem:indexPathCount++ inSection:0]];
            }
            if (check) {
                [self.chatVC.unReadButton removeFromSuperview];
                self.chatVC.unReadButton = nil;
                self.chatVC.unReadMessage = 0;
            }
        }
    }
    [self rrs_fetchReadReceiptInfo:itemToFetchReceipt];

    if (self.chatVC.channelDataRepository.count <= 0) {
        return;
    }

    if (indexPathes.count <= 0) {
        return;
    }

    NSInteger boundaryIndex = indexPathes.count;
    CGFloat boundaryHeightBefore = 0;
    BOOL boundaryDisplayTimeBefore = NO;
    BOOL hasBoundary = (boundaryIndex < self.chatVC.channelDataRepository.count);
    if (hasBoundary) {
        NCMessageModel *boundaryModel =
            [self.chatVC.channelDataRepository objectAtIndex:boundaryIndex];
        boundaryHeightBefore = boundaryModel.cellSize.height;
        boundaryDisplayTimeBefore = boundaryModel.isDisplayMessageTime;
    }
    [self.chatVC.util figureOutConversationDataRepositoryFromIndex:0 toIndex:indexPathes.count - 1];

    // 下拉加载历史后，边界消息（加载前的顶部消息）的时间显示状态可能翻转，
    // 但它是在屏未复用的 cell，performBatchUpdates 只插入新项不会重新配置它，
    // 导致 cell 缓存的时间显示状态陈旧、残留时间戳并使高度错位。这里记录是否翻转，
    // 稍后在批量更新完成回调中显式刷新它。
    BOOL boundaryDisplayTimeChanged = NO;
    if (hasBoundary && boundaryIndex < self.chatVC.channelDataRepository.count) {
        NCMessageModel *boundaryModel =
            [self.chatVC.channelDataRepository objectAtIndex:boundaryIndex];
        boundaryDisplayTimeChanged =
            (boundaryModel.isDisplayMessageTime != boundaryDisplayTimeBefore);
    }

    CGFloat increasedHeight = 0;
    for (NSIndexPath *indexPath in indexPathes) {
        CGSize itemSize = [self.chatVC collectionView:self.chatVC.messageCollectionView
                                               layout:self.customFlowLayout
                               sizeForItemAtIndexPath:indexPath];
        increasedHeight += itemSize.height;
    }
    if (boundaryHeightBefore > 0 && boundaryIndex < self.chatVC.channelDataRepository.count) {
        NCMessageModel *boundaryModel =
            [self.chatVC.channelDataRepository objectAtIndex:boundaryIndex];
        if (boundaryModel.cellSize.height > 0) {
            increasedHeight += boundaryModel.cellSize.height - boundaryHeightBefore;
        }
    }

    CGSize contentSize = self.chatVC.messageCollectionView.contentSize;
    contentSize.height += increasedHeight;
    if (self.allMessagesAreLoaded) {
        contentSize.height -= COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT;
    }
    self.customFlowLayout.collectionViewNewContentSize = contentSize;

    [UIView setAnimationsEnabled:NO];
    @try {
        if (self.chatVC.channelDataRepository.count == 1 ||
            [self.chatVC.messageCollectionView numberOfItemsInSection:0] ==
                self.chatVC.channelDataRepository.count) {
            [self.chatVC.messageCollectionView reloadData];
        } else {
            if (check) { // A mention jump refreshes again in scrollToSpecifiedPosition:, so skip
                         // this update when check is NO.
                // On iOS 15, insertion without reload can leave a reused cell stale.
                [self.chatVC.messageCollectionView
                    performBatchUpdates:^{
                      [self.chatVC.messageCollectionView insertItemsAtIndexPaths:indexPathes];
                    }
                    completion:^(BOOL finished) {
                      // 边界 cell 的时间显示状态翻转后，同步刷新在屏的它，避免时间戳与内容重叠。
                      if (boundaryDisplayTimeChanged &&
                          boundaryIndex < self.chatVC.channelDataRepository.count) {
                          NCMessageModel *boundaryModel =
                              [self.chatVC.channelDataRepository objectAtIndex:boundaryIndex];
                          NSIndexPath *boundaryIndexPath =
                              [NSIndexPath indexPathForItem:boundaryIndex inSection:0];
                          NCMessageCell *boundaryCell =
                              (NCMessageCell *)[self.chatVC.messageCollectionView
                                  cellForItemAtIndexPath:boundaryIndexPath];
                          if ([boundaryCell respondsToSelector:@selector(setDataModel:)]) {
                              [boundaryCell setDataModel:boundaryModel];
                          }
                      }
                    }];
            }
        }
        [UIView setAnimationsEnabled:YES];
        [self.chatVC.collectionViewHeader stopAnimating];
        self.isIndicatorLoading = NO;
        if (self.allMessagesAreLoaded) {
            UICollectionViewLayout *layout = self.chatVC.messageCollectionView.collectionViewLayout;
            [self.chatVC.messageCollectionView.collectionViewLayout invalidateLayout];
            [self.chatVC.messageCollectionView setCollectionViewLayout:layout];
        }
    } @catch (NSException *except) {
        NCLogD(@"----handleMessagesAfterLoadMore %@", except.description);
    }
}

#pragma mark - loadMessageV2

- (void)loadHistorylocatedMessageV2 {
    __weak typeof(self) weakSelf = self;
    [self
        getHistoryMessageV2:self.chatVC.locatedMessageSentTime + 1
                      order:NCChannelHistoryMessageOrderDesc
                   loadType:self.chatVC.loadMessageType
                   complete:^(NSArray<NCMessage *> *oldMsgs, BOOL isRemaining,
                              NCChannelLoadMessageType type, BOOL isDoubleCallback) {
                     long long time = self.chatVC.locatedMessageSentTime - 1;
                     if (oldMsgs.count > 0) {
                         NCMessage *msg = oldMsgs.firstObject;
                         time = msg.sentTime;
                     }
                     [self
                         getHistoryMessageV2:time
                                       order:NCChannelHistoryMessageOrderAsc
                                    loadType:type
                                    complete:^(NSArray<NCMessage *> *newMsgs, BOOL isRemaining,
                                               NCChannelLoadMessageType type,
                                               BOOL isDoubleCallback) {
                                      __strong typeof(weakSelf) strongSelf = weakSelf;
                                      if (oldMsgs.count < strongSelf.chatVC.defaultMessageCount) {
                                          strongSelf.allMessagesAreLoaded = YES;
                                      } else {
                                          strongSelf.allMessagesAreLoaded = NO;
                                      }
                                      if (newMsgs.count < strongSelf.chatVC.defaultMessageCount) {
                                          weakSelf.isLoadingHistoryMessage = NO;
                                      } else {
                                          strongSelf.isLoadingHistoryMessage = YES;
                                      }
                                      NSMutableArray *msgArr = [[NSMutableArray alloc] init];
                                      [msgArr addObjectsFromArray:[[newMsgs reverseObjectEnumerator]
                                                                      allObjects]];
                                      [msgArr addObjectsFromArray:oldMsgs];
                                      [strongSelf loadLatestHistoryMessageV2:msgArr
                                                            isDoubleCallback:isDoubleCallback];
                                    }];
                   }];
}

- (void)loadHistoryMessageBeforeTimeV2:(long long)time {
    __weak typeof(self) weakSelf = self;
    [self getHistoryMessageV2:time
                        order:NCChannelHistoryMessageOrderDesc
                     loadType:self.chatVC.loadMessageType
                     complete:^(NSArray<NCMessage *> *messages, BOOL isRemaining,
                                NCChannelLoadMessageType type, BOOL isDoubleCallback) {
                       __strong typeof(weakSelf) strongSelf = weakSelf;
                       strongSelf.allMessagesAreLoaded = !isRemaining;

                       if (messages.count > 0) {
                           if (time == 0) {
                               [strongSelf loadLatestHistoryMessageV2:messages
                                                     isDoubleCallback:isDoubleCallback];
                           } else {
                               [strongSelf handleMessagesAfterLoadMore:messages];
                               NCMessage *message = messages.lastObject;
                               strongSelf.recordTime = message.sentTime;
                           }
                       }
                     }];
}

- (void)loadHistoryMessageAfterTimeV2:(long long)time {
    __weak typeof(self) weakSelf = self;
    [self getHistoryMessageV2:time
                        order:NCChannelHistoryMessageOrderAsc
                     loadType:self.chatVC.loadMessageType
                     complete:^(NSArray<NCMessage *> *messages, BOOL isRemaining,
                                NCChannelLoadMessageType type, BOOL isDoubleCallback) {
                       __strong typeof(weakSelf) strongSelf = weakSelf;
                       if (messages.count < strongSelf.chatVC.defaultMessageCount) {
                           strongSelf.isLoadingHistoryMessage = NO;
                       } else {
                           strongSelf.isLoadingHistoryMessage = YES;
                       }
                       [strongSelf loadMoreNewerMessageV2:messages];
                     }];
}

// Only the initial load can call back twice. isDoubleCallback marks local and remote versions of
// the same page; the remote result wins.
- (void)loadLatestHistoryMessageV2:(NSArray<NCMessage *> *)messages
                  isDoubleCallback:(BOOL)isDoubleCallback {
    if (messages.count <= 0) {
        return;
    }
    if (!self.chatVC.locatedMessageSentTime && messages.count < self.chatVC.defaultMessageCount) {
        self.isLoadingHistoryMessage = NO;
        self.recordTime = messages.lastObject.sentTime;
    }

    // For an initial double callback, remove the first local page before applying the authoritative
    // remote page.
    if (isDoubleCallback) {
        [self.chatVC.channelDataRepository removeAllObjects];
    }
    NSMutableArray *itemToFetchReceipt = [NSMutableArray array];
    NSInteger insertedCount = 0;

    for (int i = 0; i < messages.count; i++) {
        NCMessage *message = [messages objectAtIndex:i];
        NCMessageModel *model = [NCMessageModel modelWithNCMessage:message];
        if ([self pushOldMessageModel:model]) {
            [itemToFetchReceipt addObject:model];
            insertedCount++;
        }
    }
    [self rrs_fetchReadReceiptInfo:itemToFetchReceipt];
    if (insertedCount > 0) {
        [self.chatVC.util figureOutConversationDataRepositoryFromIndex:0 toIndex:insertedCount - 1];
    }
    [self.chatVC.messageCollectionView reloadData];
    [self handleAfterLoadLastestMessage];
}

- (void)loadMoreNewerMessageV2:(NSArray<NCMessage *> *)messages {
    if (messages.count <= 0) {
        return;
    }
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSMutableArray *itemToFetchReceipt = [NSMutableArray array];
    NSInteger previousItemCount = self.chatVC.channelDataRepository.count;
    for (NCMessage *message in messages) {
        NCMessage *checkedMessage = [self.chatVC willAppendAndDisplayMessage:message];
        if (checkedMessage) {
            NCMessageModel *model = [NCMessageModel modelWithNCMessage:checkedMessage];
            if ([self appendMessageModel:model]) {
                [self.chatVC.channelDataRepository addObject:model];
                [itemToFetchReceipt addObject:model];
                NSIndexPath *indexPath =
                    [NSIndexPath indexPathForItem:self.chatVC.channelDataRepository.count - 1
                                        inSection:0];
                [indexPaths addObject:indexPath];
            }
        }
    }
    [self rrs_fetchReadReceiptInfo:itemToFetchReceipt];
    if (indexPaths.count > 0) {
        [self.chatVC.util
            figureOutConversationDataRepositoryFromIndex:previousItemCount
                                                 toIndex:self.chatVC.channelDataRepository.count -
                                                         1];
        /* bugfix:PAASIOSDEV-259
         insertItemsAtIndexPaths: requires this invariant:
         updated index path count + current collection view cell count = data source count.
         Violating it crashes on iOS 12.
         */
        NSInteger collectionViewItemCount =
            [self.chatVC.messageCollectionView numberOfItemsInSection:0];
        BOOL canInsertItems =
            collectionViewItemCount > 0 && collectionViewItemCount == previousItemCount &&
            collectionViewItemCount + indexPaths.count == self.chatVC.channelDataRepository.count;
        if (canInsertItems) {
            [self.chatVC.messageCollectionView
                performBatchUpdates:^{
                  [self.chatVC.messageCollectionView insertItemsAtIndexPaths:indexPaths];
                }
                         completion:nil];
        } else {
            [self.chatVC.messageCollectionView reloadData];
        }
    }
}

// Only the initial load can call back twice. isDoubleCallback marks local and remote versions of
// the same page; the remote result wins.
- (void)getHistoryMessageV2:(long long)time
                      order:(NCChannelHistoryMessageOrder)order
                   loadType:(NCChannelLoadMessageType)loadType
                   complete:(void (^)(NSArray<NCMessage *> *messages, BOOL isRemaining,
                                      NCChannelLoadMessageType type,
                                      BOOL isDoubleCallback))complete {
    __weak typeof(self) weakSelf = self;

    void (^updateMessageListBlock)(NSArray<NCMessage *> *messages, BOOL isRemaining,
                                   NCChatUIErrorCode code, BOOL isDoubleCallback) =
        ^(NSArray<NCMessage *> *messages, BOOL isRemaining, NCChatUIErrorCode code,
          BOOL isDoubleCallback) {
          __strong typeof(weakSelf) strongSelf = weakSelf;
          dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.isIndicatorLoading = NO;
            [strongSelf.chatVC.collectionViewHeader stopAnimating];
            if (code == NCChatUIErrorCodeSuccess) {
                if (complete) {
                    complete(messages, isRemaining, loadType, isDoubleCallback);
                }
            } else {
                switch (loadType) {
                case NCChannelLoadMessageTypeAlways: {
                    if (complete) {
                        complete(messages, isRemaining, loadType, isDoubleCallback);
                    }
                } break;
                case NCChannelLoadMessageTypeAsk: {
                    [NCAlertView
                        showAlertController:nil
                                    message:NCUILocalizedString(@"load_msg_ask_info")
                               actionTitles:nil
                                cancelTitle:NCUILocalizedString(@"cancel")
                               confirmTitle:NCUILocalizedString(@"ok")
                             preferredStyle:(UIAlertControllerStyleAlert)actionsBlock:nil
                                cancelBlock:nil
                               confirmBlock:^{
                                 if (complete) {
                                     complete(messages, isRemaining, NCChannelLoadMessageTypeAlways,
                                              isDoubleCallback);
                                 }
                               }
                           inViewController:strongSelf.chatVC];
                } break;
                default:
                    break;
                }
            }
          });
        };

    void (^completeHandle)(NSArray<NCMessage *> *messages, BOOL isRemaining, NCChatUIErrorCode code,
                           BOOL isDoubleCallback) =
        ^(NSArray<NCMessage *> *messages, BOOL isRemaining, NCChatUIErrorCode code,
          BOOL isDoubleCallback) {
          __strong typeof(weakSelf) strongSelf = weakSelf;
          [strongSelf edit_refreshReferenceMessage:messages
                                          complete:^(NSArray<NCMessage *> *results) {
                                            updateMessageListBlock(results, isRemaining, code,
                                                                   isDoubleCallback);
                                          }];
        };

    // Load local data first only for the initial page, where time is zero.
    BOOL isFirstLoadLocal = (0 == time);
    if (isFirstLoadLocal) {
        // Since V5.6.1, direct and group channels load local data before the gap-recovery query
        // so the initial page is not blank on a weak network.
        // 1. Load local messages.
        [self loadLocalNCMessagesWithPageSize:self.chatVC.defaultMessageCount
            sentTime:0
            order:order
            completion:^(NSArray<NCMessage *> *messages, NCChatUIErrorCode code) {
              completeHandle(messages, YES, code, NO);

              // 2. Run the gap-recovery query.
              [self loadNCMessagesWithPageSize:self.chatVC.defaultMessageCount
                  time:time
                  order:order
                  completion:^(NSArray<NCMessage *> *remoteMessages, BOOL isRemaining,
                               NCChatUIErrorCode code) {
                    // Message deduplication requires removing the local page before applying
                    // gap-recovery results to preserve ordering. Signal the second callback so the
                    // caller clears its data and UI together before applying this page.
                    // isDoubleCallback identifies the remote replacement for the first local
                    // result.
                    completeHandle(remoteMessages, isRemaining, code, YES);
                  }
                  fallback:^{
                    completeHandle(nil, YES, NCChatUIErrorCodeSuccess, YES);
                  }];
            }
            fallback:^{
              completeHandle(nil, YES, NCChatUIErrorCodeSuccess, NO);

              // 2. Run the gap-recovery query.
              [self loadNCMessagesWithPageSize:self.chatVC.defaultMessageCount
                  time:time
                  order:order
                  completion:^(NSArray<NCMessage *> *remoteMessages, BOOL isRemaining,
                               NCChatUIErrorCode code) {
                    // Message deduplication requires removing the local page before applying
                    // gap-recovery results to preserve ordering. Signal the second callback so the
                    // caller clears its data and UI together before applying this page.
                    // isDoubleCallback identifies the remote replacement for the first local
                    // result.
                    completeHandle(remoteMessages, isRemaining, code, YES);
                  }
                  fallback:^{
                    completeHandle(nil, YES, NCChatUIErrorCodeSuccess, YES);
                  }];
            }];
    } else {
        [self loadNCMessagesWithPageSize:self.chatVC.defaultMessageCount
            time:time
            order:order
            completion:^(NSArray<NCMessage *> *messages, BOOL isRemaining, NCChatUIErrorCode code) {
              completeHandle(messages, isRemaining, code, NO);
            }
            fallback:^{
              completeHandle(nil, YES, NCChatUIErrorCodeSuccess, NO);
            }];
    }
}

- (void)handleAfterLoadLastestMessage {
    [self.chatVC updateUnreadMsgCountLabel];
    if (self.chatVC.unReadMessage > 0 && [self.chatVC shouldMarkMessagesAsRead]) {
        NCBaseChannel *channel = self.chatVC.currentChannel;
        [channel clearUnreadCountWithCompletion:^(BOOL isCleared, NCError *_Nullable error) {
          (void)isCleared;
          (void)error;
          /// Notify the UI after unread state is cleared.
          dispatch_async(dispatch_get_main_queue(), ^{
            [self.chatVC notifyUpdateUnreadMessageCount];
          });
        }];
    }

    if (self.chatVC.channelDataRepository.count == 0 && self.chatVC.unReadButton != nil) {
        [self.chatVC.unReadButton removeFromSuperview];
        self.chatVC.unReadMessage = 0;
    }
    if (self.chatVC.unReadMessage > self.chatVC.defaultMessageCount &&
        self.chatVC.enableUnreadMessageIcon == YES && !self.chatVC.unReadButton.selected) {
        [self.chatVC setupUnReadMessageView];
    }
    if (self.chatVC.locatedMessageSentTime > 0) {
        [self scrollToSuitablePosition];
    } else {
        [self.chatVC scrollToBottomAnimated:NO];
    }
    [self setupUnReadMentionedButton];
}

- (void)didReceiveNCMessage:(NCMessage *)ncMessage left:(NSInteger)left {
    if (!ncMessage || ![self p_tryClaimReceivedMessage:ncMessage]) {
        return;
    }
    NCMessageModel *model = [NCMessageModel modelWithNCMessage:ncMessage];
    if ([self p_enableCurrentConversationWithIdentifier:ncMessage.channelIdentifier]) {
        [self p_setNCMessageReadStats:ncMessage];

        BOOL isPersisted = model.isPersisted;
        BOOL isCounted = ncMessage.isCounted;
        // When receipts are enabled, send one for each received message; failed receipts remain
        // persisted for retry.
        if (left == 0) {
            [self p_receiveNCMessageAndUpdateReadStatus:ncMessage isPersisted:isPersisted];
        }

        __weak typeof(self) __blockSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
          __strong typeof(__blockSelf) strongSelf = __blockSelf;

          if (!strongSelf.chatVC.isViewLoaded && isCounted) {
              strongSelf.chatVC.unReadMessage++;
          }
          // Bound the number of displayed messages when a large batch arrives.
          // Users can pull down to load additional history.
          [strongSelf clearOldestMessagesWhenMemoryWarning];
          NCMessage *checkedMessage = [strongSelf.chatVC willAppendAndDisplayMessage:ncMessage];
          if (checkedMessage) {
              if (checkedMessage.direction == NCMessageDirectionSend) {
                  strongSelf.showUnreadViewMessageId = (long long)checkedMessage.clientId;
              }
              if (!strongSelf.isLoadingHistoryMessage) {
                  [strongSelf appendAndDisplayMessage:checkedMessage];
              }
              if (checkedMessage.direction == NCMessageDirectionSend) {
                  [strongSelf.appendMessageQueue addOperationWithBlock:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                      [strongSelf.chatVC updateForMessageSendSuccess:checkedMessage];
                    });
                  }];
              }
              UIMenuController *menu = [UIMenuController sharedMenuController];
              menu.menuVisible = NO;
              [[NCMenuController sharedMenuController] hideMenuAnimated:NO];
              NSString *currentUserId = [NCEngine getCurrentUserId];
              BOOL isCurrentUserSender =
                  [checkedMessage.senderUserId isEqualToString:currentUserId];
              // Determine whether to show the lower-right unread count.
              if (strongSelf.chatVC.enableNewComingMessageIcon == YES && isCounted &&
                  ![strongSelf isAtTheBottomOfTableView] && !isCurrentUserSender) {
                  if (checkedMessage) {
                      [strongSelf.unreadNewMsgArr addObject:checkedMessage];
                  }
                  [strongSelf.chatVC updateUnreadMsgCountLabel];
              }
              if (![strongSelf isAtTheBottomOfTableView] && !isCurrentUserSender) {
                  NCMentionedInfo *mentionedInfo = checkedMessage.content.mentionedInfo;
                  if (mentionedInfo.isMentionedMe) {
                      [strongSelf.unreadMentionedMessages addObject:checkedMessage];
                      [strongSelf setupUnReadMentionedButton];
                  }
              }
          }
        });
    } else {
        if (left == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self.chatVC notifyUpdateUnreadMessageCount];
            });
        }
    }
}

#pragma mark - NCMessageHandler

- (void)onReceivedMessage:(NCMessage *)message left:(int)left offline:(BOOL)offline {
    (void)offline;
    if (!message) {
        return;
    }
    [self didReceiveNCMessage:message left:left];
}

- (void)onMessagesUpdated:(NCMessagesUpdatedEvent *)event {
    [self handleModifiedMessages:event.messages];
}

- (void)handleModifiedMessages:(NSArray<NCMessage *> *)messages {
    if (![self p_tryClaimModifiedMessages:messages]) {
        return;
    }
    NSMutableArray<NCMessageModel *> *models = [NSMutableArray array];
    for (NCMessage *message in messages) {
        if ([self p_enableCurrentConversationWithIdentifier:message.channelIdentifier]) {
            NCMessageModel *model = [NCMessageModel modelWithNCMessage:message];
            if (model) {
                [models addObject:model];
            }
        }
    }
    if (models.count == 0) {
        return;
    }
    [self edit_refreshUIMessagesEditedStatus:models];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.chatVC edit_refreshReferenceViewContentIfNeeded:models
                                                     status:NCReferenceMessageStatusUpdated];
    });
}

- (BOOL)p_enableCurrentConversationWithIdentifier:(NCChannelIdentifier *)channelIdentifier {
    if (!channelIdentifier) {
        return NO;
    }
    NCChannelIdentifier *currentIdentifier = self.chatVC.currentChannelIdentifier;
    return currentIdentifier && [currentIdentifier isEqual:channelIdentifier];
}

- (BOOL)p_tryClaimReceivedMessage:(NCMessage *)message {
    NSString *dedupKey = [self p_receivedMessageDedupKey:message];
    if (dedupKey.length == 0) {
        return YES;
    }
    @synchronized(self.receivedMessageDedupKeys) {
        if ([self.receivedMessageDedupKeys containsObject:dedupKey]) {
            return NO;
        }
        [self.receivedMessageDedupKeys addObject:dedupKey];
        if (self.receivedMessageDedupKeys.count > 200) {
            [self.receivedMessageDedupKeys removeObjectAtIndex:0];
        }
    }
    return YES;
}

- (NSString *)p_receivedMessageDedupKey:(NCMessage *)message {
    if (message.messageId.length > 0) {
        return [NSString stringWithFormat:@"uid:%@", message.messageId];
    }
    NCChannelIdentifier *identifier = message.channelIdentifier;
    return [NSString stringWithFormat:@"fallback:%ld:%@:%ld:%lld:%ld", (long)identifier.channelType,
                                      identifier.channelId ?: @"", (long)message.clientId,
                                      message.sentTime, (long)message.direction];
}

- (BOOL)p_tryClaimModifiedMessages:(NSArray<NCMessage *> *)messages {
    NSString *dedupKey = [self p_modifiedMessagesDedupKey:messages];
    if (dedupKey.length == 0) {
        return YES;
    }
    @synchronized(self.modifiedMessageDedupKeys) {
        if ([self.modifiedMessageDedupKeys containsObject:dedupKey]) {
            return NO;
        }
        [self.modifiedMessageDedupKeys addObject:dedupKey];
        if (self.modifiedMessageDedupKeys.count > 200) {
            [self.modifiedMessageDedupKeys removeObjectAtIndex:0];
        }
    }
    return YES;
}

- (NSString *)p_modifiedMessagesDedupKey:(NSArray<NCMessage *> *)messages {
    NSMutableArray<NSString *> *components = [NSMutableArray array];
    for (NCMessage *message in messages) {
        NSString *messageKey = [self p_modifiedMessageDedupComponent:message];
        if (messageKey.length > 0) {
            [components addObject:messageKey];
        }
    }
    if (components.count == 0) {
        return nil;
    }
    NSArray<NSString *> *sortedComponents =
        [components sortedArrayUsingSelector:@selector(compare:)];
    return [sortedComponents componentsJoinedByString:@"|"];
}

- (NSString *)p_modifiedMessageDedupComponent:(NCMessage *)message {
    NSString *messageId = message.messageId ?: @"";
    long updateTimestamp = message.updateInfo.timestamp;
    NSInteger updateStatus = message.updateInfo.status;
    if (messageId.length > 0) {
        return [NSString
            stringWithFormat:@"%@:%ld:%ld", messageId, updateTimestamp, (long)updateStatus];
    }
    NCChannelIdentifier *identifier = message.channelIdentifier;
    return
        [NSString stringWithFormat:@"fallback:%ld:%@:%@:%ld:%ld:%ld", (long)identifier.channelType,
                                   identifier.channelId ?: @"", @"", (long)message.clientId,
                                   updateTimestamp, (long)updateStatus];
}

- (void)p_setNCMessageReadStats:(NCMessage *)message {
    if ([self.chatVC shouldMarkMessagesAsRead]) {
        if (message.clientId > 0 && message.receivedStatusInfo) {
            message.receivedStatusInfo.isRead = YES;
            [message setReceivedStatusInfo:message.receivedStatusInfo completion:nil];
        }
    }
}

- (void)p_receiveNCMessageAndUpdateReadStatus:(NCMessage *)message isPersisted:(BOOL)isPersisted {
    if ([self.chatVC shouldMarkMessagesAsRead] && message.direction == NCMessageDirectionReceive &&
        isPersisted) {
        [self.chatVC.util syncReadStatusWithDelay:YES];
    }
}

- (void)setAllMessagesAreLoaded:(BOOL)allMessagesAreLoaded {
    _allMessagesAreLoaded = allMessagesAreLoaded;
    if (allMessagesAreLoaded &&
        [self.loadDelegate respondsToSelector:@selector(noMoreMessageToFetch)]) {
        [self.loadDelegate noMoreMessageToFetch];
    }
}

#pragma mark - util
- (NCMessageModel *)setModelIsDisplayNickName:(NCMessageModel *)model {
    if (!model) {
        return nil;
    }
    if (model.messageDirection == NCMessageDirectionReceive) {
        model.isDisplayNickname = self.chatVC.displayUserNameInCell;
    } else {
        model.isDisplayNickname = NO;
    }
    [self hideUnreadButtonAfterLoadMetionedMessageWith:model];
    return model;
}

- (void)appendSendOutMessage:(NCMessage *)message {
    self.showUnreadViewMessageId = (long)message.clientId;
    [self appendAndDisplayMessage:message];
}

- (void)didDeleteMessageForAll:(NCMessage *)deletedMessage {
    NCChannelIdentifier *identifier = deletedMessage.channelIdentifier;
    // Update the lower-right unread count for the same channel when enabled, off the bottom,
    // outside search, and nonzero.
    if (self.chatVC.enableNewComingMessageIcon &&
        identifier.channelType == (NCChannelType)self.chatVC.channelType &&
        [identifier.channelId isEqual:self.chatVC.channelId] && ![self isAtTheBottomOfTableView] &&
        self.chatVC.locatedMessageSentTime == 0 && self.unreadNewMsgArr.count != 0) {
        for (NCMessage *messagge in self.unreadNewMsgArr) {
            if (messagge.clientId == deletedMessage.clientId) {
                [self.unreadNewMsgArr removeObject:messagge];
                break;
            }
        }

        [self.chatVC updateUnreadMsgCountLabel];
    }
    if (self.firstUnreadMessage && self.firstUnreadMessage.clientId == deletedMessage.clientId) {
    }
    [self p_updateDeletedReferenceMessagesWithMessage:deletedMessage];
    [self didReloadDeletedMessageForAllWithClientId:(long)deletedMessage.clientId];
}

// Called when a cell becomes visible.
- (void)removeMentionedMessage:(long)curMessageId {
    if (self.unreadMentionedMessages.count <= 0 || !curMessageId) {
        return;
    }
    NSArray *tempUnreadMentionedMessages = self.unreadMentionedMessages;
    for (NCMessage *message in tempUnreadMentionedMessages) {
        if (message.clientId == curMessageId) {
            [self.unreadMentionedMessages removeObject:message];
            [self setupUnReadMentionedButton];
            break;
        }
    }
}

- (void)didReloadDeletedMessageForAllWithClientId:(long)deletedMessageClientId {
    NCGetMessageByIdParams *params =
        [[NCGetMessageByIdParams alloc] initWithMessageClientId:deletedMessageClientId];
    [NCBaseChannel
        getMessageByIdWithParams:params
                      completion:^(NCMessage *_Nullable message, NCError *_Nullable error) {
                        (void)error;
                        dispatch_async(dispatch_get_main_queue(), ^{
                          int index = -1;
                          NCMessageModel *msgModel;
                          // Filter delayed refresh messages before updating the data source.
                          if (self.cachedReloadMessages.count > 0) {
                              for (int i = 0; i < self.cachedReloadMessages.count; i++) {
                                  msgModel = [self.cachedReloadMessages objectAtIndex:i];
                                  if (msgModel.clientId == deletedMessageClientId) {
                                      index = i;
                                      break;
                                  }
                              }

                              if (index >= 0) {
                                  if (message) {
                                      NCMessageModel *newModel =
                                          [NCMessageModel modelWithNCMessage:message];
                                      newModel.isDisplayMessageTime = msgModel.isDisplayMessageTime;
                                      newModel.isDisplayNickname = msgModel.isDisplayNickname;
                                      self.cachedReloadMessages[index] = newModel;
                                  }
                                  return;
                              }
                          }

                          for (int i = 0; i < self.chatVC.channelDataRepository.count; i++) {
                              msgModel = [self.chatVC.channelDataRepository objectAtIndex:i];
                              if (msgModel.clientId == deletedMessageClientId &&
                                  ![msgModel.objectName
                                      isEqualToString:
                                          NCOldMessageNotificationMessageTypeIdentifier]) {
                                  index = i;
                                  break;
                              }
                          }
                          if (index >= 0) {
                              NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index
                                                                          inSection:0];
                              [self.chatVC.channelDataRepository removeObject:msgModel];
                              if (message) {
                                  NCMessageModel *newModel =
                                      [NCMessageModel modelWithNCMessage:message];
                                  newModel.isDisplayMessageTime = msgModel.isDisplayMessageTime;
                                  newModel.isDisplayNickname = msgModel.isDisplayNickname;
                                  [self.chatVC.channelDataRepository insertObject:newModel
                                                                          atIndex:index];
                                  NSInteger collectionItemCount =
                                      [self.chatVC.messageCollectionView numberOfItemsInSection:0];
                                  if (indexPath.row < collectionItemCount &&
                                      indexPath.row < self.chatVC.channelDataRepository.count) {
                                      [self.chatVC.messageCollectionView
                                          reloadItemsAtIndexPaths:@[ indexPath ]];
                                  } else {
                                      [self.chatVC.messageCollectionView reloadData];
                                  }
                              } else {
                                  NSInteger collectionItemCount =
                                      [self.chatVC.messageCollectionView numberOfItemsInSection:0];
                                  BOOL canDelete = (indexPath.row < collectionItemCount) &&
                                                   (self.chatVC.channelDataRepository.count + 1 ==
                                                    collectionItemCount);
                                  if (canDelete) {
                                      [self.chatVC.messageCollectionView
                                          deleteItemsAtIndexPaths:@[ indexPath ]];
                                  } else {
                                      [self.chatVC.messageCollectionView reloadData];
                                  }
                              }
                          }
                        });
                      }];
}

- (void)p_updateDeletedReferenceMessagesWithMessage:(nullable NCMessage *)message {
    if (message.messageId.length > 0) {
        [self edit_setUIReferenceMessagesEditStatus:NCReferenceMessageStatusDeleted
                                      forMessageIds:@[ message.messageId ]];
    }
}

- (void)scrollToLoadMoreHistoryMessage {
    self.isIndicatorLoading = YES;
    [self performSelector:@selector(loadMoreHistoryMessage) withObject:nil afterDelay:0.5f];
}

- (void)scrollToLoadMoreNewerMessage {
    self.isIndicatorLoading = YES;
    [self performSelector:@selector(loadMoreNewerMessage) withObject:nil afterDelay:0.5f];
}

- (void)scrollToSuitablePosition {
    // Scroll to the message at the requested timestamp.
    [self scrollToLocatedMessage];
}

- (void)cancelAppendMessageQueue {
    [self.appendMessageQueue cancelAllOperations];
}

- (void)tapRightBottomMsgCountIcon:(UIGestureRecognizer *)gesture {
    [self.unreadNewMsgArr removeAllObjects];
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (self.isLoadingHistoryMessage) {
            /// Wait approximately 0.35 seconds for the scroll animation to finish.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                             [self
                                 appendLastestMessageToDataSourceWithCompletion:^(NSInteger count) {
                                   NSInteger totalcount = self.chatVC.channelDataRepository.count;
                                   NSInteger removableCount = totalcount - count;
                                   if (removableCount > 0 && removableCount <= totalcount) {
                                       [self.chatVC.channelDataRepository
                                           removeObjectsInRange:NSMakeRange(0, removableCount)];
                                   }
                                   [self.chatVC.messageCollectionView reloadData];
                                 }];
                           });
        }
        [self.chatVC scrollToBottomAnimated:YES];
    }
    self.isLoadingHistoryMessage = NO;
}

- (void)tapRightTopMsgUnreadButton {
    self.isLoadingHistoryMessage = YES;
    [self loadRightTopUnreadMessages];
}

- (NCMessageModel *)generateOldMessageModel {
    NCOldMessageNotificationMessage *oldMessageTip = [[NCOldMessageNotificationMessage alloc] init];
    NCMessageModel *oldMessageModel = [[NCMessageModel alloc] init];
    oldMessageModel.channelType = self.chatVC.channelType;
    oldMessageModel.channelId = self.chatVC.channelId ?: @"";
    oldMessageModel.messageDirection = NCMessageDirectionSend;
    oldMessageModel.content = oldMessageTip;
    oldMessageModel.objectName = NCOldMessageNotificationMessageTypeIdentifier;
    oldMessageModel.sentTime = 0;
    oldMessageModel.receivedTime = 0;
    return oldMessageModel;
}

- (void)loadUnReadMentionedMessages {
    NCMessage *firstUnReadMentionedMessagge = [self.unreadMentionedMessages firstObject];
    long long localTime = firstUnReadMentionedMessagge.sentTime;
    __weak typeof(self) weakSelf = self;
    [self
        getHistoryMessageV2:localTime + 1
                      order:NCChannelHistoryMessageOrderDesc
                   loadType:self.chatVC.loadMessageType
                   complete:^(NSArray<NCMessage *> *oldMsgs, BOOL isRemaining,
                              NCChannelLoadMessageType type, BOOL isDoubleCallback) {
                     __strong typeof(weakSelf) strongSelf = weakSelf;

                     long long time = localTime - 1;
                     if (oldMsgs.count > 0) {
                         NCMessage *msg = oldMsgs.firstObject;
                         time = msg.sentTime;
                     }
                     __weak typeof(strongSelf) weakSelf2 = strongSelf;

                     [strongSelf
                         getHistoryMessageV2:time
                                       order:NCChannelHistoryMessageOrderAsc
                                    loadType:type
                                    complete:^(NSArray<NCMessage *> *newMsgs, BOOL isRemaining,
                                               NCChannelLoadMessageType type,
                                               BOOL isDoubleCallback) {
                                      __strong typeof(weakSelf2) strongSelf2 = weakSelf2;

                                      NSMutableArray<NCMessage *> *msgArr = [NSMutableArray array];
                                      if (oldMsgs != nil) {
                                          msgArr = [[oldMsgs reverseObjectEnumerator] allObjects]
                                                       .mutableCopy;
                                      }
                                      [msgArr addObjectsFromArray:newMsgs];
                                      NSInteger oldMessageInsertIndex = NSNotFound;
                                      if (strongSelf2.firstUnreadMessage) {
                                          for (int i = 0; i < msgArr.count; i++) {
                                              NCMessage *message = msgArr[i];
                                              if (message.clientId ==
                                                  strongSelf2.firstUnreadMessage.clientId) {
                                                  oldMessageInsertIndex = i;
                                                  break;
                                              }
                                          }
                                      }
                                      // Remove all currently loaded messages.
                                      [strongSelf2.chatVC.channelDataRepository removeAllObjects];
                                      [strongSelf2.chatVC.messageCollectionView reloadData];
                                      /*
                                       bugID=50466:
                                       After reloadData, the collection view has not completed
                                       layout. Mark it for layout and force a layout pass before
                                       accessing rendered collection view content.
                                       */
                                      [strongSelf2.chatVC.messageCollectionView setNeedsLayout];
                                      [strongSelf2.chatVC.messageCollectionView layoutIfNeeded];

                                      [strongSelf2 loadMoreNewerMessageV2:msgArr];
                                      if (oldMessageInsertIndex != NSNotFound &&
                                          oldMessageInsertIndex <=
                                              strongSelf2.chatVC.channelDataRepository.count) {
                                          NCMessageModel *oldMessageModel =
                                              [strongSelf2 generateOldMessageModel];
                                          [strongSelf2.chatVC.channelDataRepository
                                              insertObject:oldMessageModel
                                                   atIndex:oldMessageInsertIndex];
                                          [strongSelf2
                                              rrs_fetchReadReceiptInfo:@[ oldMessageModel ]];
                                          [strongSelf2.chatVC.messageCollectionView reloadData];
                                      }

                                      [strongSelf2
                                          scrollToSpecifiedPosition:YES
                                                baseMessageClientId:firstUnReadMentionedMessagge
                                                                        .clientId];
                                      // After loading, the next scroll must reevaluate whether to
                                      // remove the unread button.
                                      if (NC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"18.0")) {
                                          if (firstUnReadMentionedMessagge.clientId ==
                                              self.firstUnreadMessage.clientId) {
                                              self.hideUnreadBtnForMentioned = NO;
                                              [self.chatVC.unReadButton removeFromSuperview];
                                              self.chatVC.unReadButton = nil;
                                              self.chatVC.unReadMessage = 0;
                                          } else {
                                              strongSelf2.hideUnreadBtnForMentioned = YES;
                                          }
                                      } else {
                                          strongSelf2.hideUnreadBtnForMentioned = YES;
                                      }

                                      // Hide the bottom new-message button when this is the last
                                      // message.
                                      [strongSelf2
                                          loadNCMessagesWithPageSize:1
                                                                time:0
                                                               order:
                                                                   NCChannelHistoryMessageOrderDesc
                                                          completion:^(
                                                              NSArray<NCMessage *> *latestMessages,
                                                              BOOL isRemaining,
                                                              NCChatUIErrorCode code) {
                                                            (void)isRemaining;
                                                            if (code != NCChatUIErrorCodeSuccess ||
                                                                latestMessages.count == 0) {
                                                                return;
                                                            }
                                                            NCMessage *curLastMessage =
                                                                [msgArr lastObject];
                                                            NCMessage *latestMessage =
                                                                [latestMessages firstObject];
                                                            if (latestMessage.clientId ==
                                                                curLastMessage.clientId) {
                                                                dispatch_async(
                                                                    dispatch_get_main_queue(), ^{
                                                                      strongSelf2.chatVC
                                                                          .unreadRightBottomIcon
                                                                          .hidden = YES;
                                                                      [strongSelf2.unreadNewMsgArr
                                                                              removeAllObjects];
                                                                    });
                                                            }
                                                          }
                                                            fallback:nil];
                                      [strongSelf2.unreadMentionedMessages
                                          removeObject:firstUnReadMentionedMessagge];
                                      [strongSelf2 setupUnReadMentionedButton];
                                    }];
                   }];
}

- (void)hideUnreadButtonAfterLoadMetionedMessageWith:(NCMessageModel *)message {
    // bugfix: 50540
    if (!self.hideUnreadBtnForMentioned) {
        return;
    }
    if (self.chatVC.unReadMessage == 0) {
        self.hideUnreadBtnForMentioned = NO;
        return;
    }
    if (message.clientId == self.firstUnreadMessage.clientId) {
        self.hideUnreadBtnForMentioned = NO;
        [self.chatVC.unReadButton removeFromSuperview];
        self.chatVC.unReadButton = nil;
        self.chatVC.unReadMessage = 0;
    }
}

- (void)loadRightTopUnreadMessages {
    __weak typeof(self) weakSelf = self;
    [self getHistoryMessageV2:self.firstUnreadMessage.sentTime
                        order:NCChannelHistoryMessageOrderAsc
                     loadType:self.chatVC.loadMessageType
                     complete:^(NSArray<NCMessage *> *messages, BOOL isRemaining,
                                NCChannelLoadMessageType type, BOOL isDoubleCallback) {
                       __strong typeof(weakSelf) strongSelf = weakSelf;
                       // Remove loaded messages so the page starts at the first unread message.
                       [strongSelf.chatVC.channelDataRepository removeAllObjects];
                       NSMutableArray<NCMessage *> *oldMessageArray = [NSMutableArray array];
                       if (strongSelf.firstUnreadMessage) {
                           [oldMessageArray addObject:strongSelf.firstUnreadMessage];
                       }
                       [oldMessageArray addObjectsFromArray:messages];
                       [strongSelf loadMoreNewerMessageV2:oldMessageArray];
                       if (oldMessageArray.count > 0) {
                           NCMessageModel *oldMessageModel = [strongSelf generateOldMessageModel];
                           [strongSelf.chatVC.channelDataRepository insertObject:oldMessageModel
                                                                         atIndex:0];
                           [strongSelf rrs_fetchReadReceiptInfo:@[ oldMessageModel ]];
                       }
                       [strongSelf
                           scrollToSpecifiedPosition:NO
                                 baseMessageClientId:strongSelf.firstUnreadMessage.clientId];
                       [strongSelf.chatVC.unReadButton removeFromSuperview];
                       strongSelf.chatVC.unReadButton = nil;
                       strongSelf.chatVC.unReadMessage = 0;
                     }];
}

- (void)scrollToSpecifiedPosition:(BOOL)ifUnReadMentioned
              baseMessageClientId:(long)baseMessageClientId {
    [self.chatVC.messageCollectionView reloadData];
    [self.chatVC.messageCollectionView setNeedsLayout];
    [self.chatVC.messageCollectionView layoutIfNeeded];
    if (self.chatVC.channelDataRepository.count > 0) {
        if (ifUnReadMentioned) {
            for (int i = 0; i < self.chatVC.channelDataRepository.count; i++) {
                NCMessageModel *model = self.chatVC.channelDataRepository[i];
                if (baseMessageClientId == model.clientId) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                    [self.chatVC.messageCollectionView
                        scrollToItemAtIndexPath:indexPath
                               atScrollPosition:UICollectionViewScrollPositionTop
                                       animated:NO];
                    break;
                }
            }
        } else {
            [self.chatVC.messageCollectionView
                scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                       atScrollPosition:UICollectionViewScrollPositionTop
                               animated:YES];
        }
    }
}

- (void)setupUnReadMentionedButton {
    if (self.chatVC.channelDataRepository.count > 0) {
        if (self.unreadMentionedMessages && self.chatVC.enableUnreadMentionedIcon == YES) {
            if (self.unreadMentionedMessages.count == 0) {
                self.chatVC.unReadMentionedButton.hidden = YES;
            } else {
                // TODO(qixinbing): Temporarily ignore the logic for @-mentions.
                //                self.chatVC.unReadMentionedButton.hidden = NO;
                //                NSString *unReadMentionedMessagesCount = [NSString
                //                stringWithFormat:@"%ld",
                //                (long)self.unreadMentionedMessages.count]; NSString
                //                *stringUnReadMentioned = [NSString
                //                stringWithFormat:NCUILocalizedString(@"have_mentioned_me_count"),
                //                unReadMentionedMessagesCount];
                //
                //                self.chatVC.unReadMentionedLabel.text = stringUnReadMentioned;
                //                [self.chatVC.util
                //                adaptUnreadButtonSize:self.chatVC.unReadMentionedLabel];
            }
        } else {
            self.chatVC.unReadMentionedButton.hidden = YES;
        }
    } else {
        [self.unreadMentionedMessages removeAllObjects];
        self.chatVC.unReadMentionedButton.hidden = YES;
    }
}

- (void)tapRightTopUnReadMentionedButton:(UIButton *)sender {
    if (self.unreadMentionedMessages.count <= 0) {
        return;
    }
    self.isLoadingHistoryMessage = YES;
    [self loadUnReadMentionedMessages];
}

- (void)resetSectionHeaderView {
    self.isIndicatorLoading = YES;
    CGPoint offset = self.chatVC.messageCollectionView.contentOffset;
    if (!self.allMessagesAreLoaded) {
        offset.y += COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT;
    }
    [UIView setAnimationsEnabled:NO];
    UICollectionViewLayout *layout = self.chatVC.messageCollectionView.collectionViewLayout;
    [self.chatVC.messageCollectionView.collectionViewLayout invalidateLayout];
    [self.chatVC.messageCollectionView setCollectionViewLayout:layout];
    [self.chatVC.messageCollectionView
        performBatchUpdates:^{
          self.chatVC.messageCollectionView.contentOffset = offset;
        }
        completion:^(BOOL finished) {
          self.isIndicatorLoading = NO;
          [UIView setAnimationsEnabled:YES];
        }];
}

// Bound the number of displayed messages when a large batch arrives.
// Users can pull down to load additional history.
- (void)clearOldestMessagesWhenMemoryWarning {
    if (self.chatVC.channelDataRepository.count > COLLECTION_VIEW_CELL_MAX_COUNT) {
        NSArray *array = [self.chatVC.messageCollectionView indexPathsForVisibleItems];
        if (array.count > 0) {
            NSIndexPath *indexPath = array.firstObject;
            // If a visible cell is among the 200 entries to be removed, the user may be loading or
            // reading history. Keep the data until it exceeds 300 entries, leaving a 100-message
            // buffer to avoid an abrupt jump.
            if (indexPath.row > 300) {
                NSRange range = NSMakeRange(0, COLLECTION_VIEW_CELL_REMOVE_COUNT);
                [self.chatVC.channelDataRepository removeObjectsInRange:range];
                [self.chatVC.messageCollectionView reloadData];
            }
        } else {
            // Clear immediately when the channel page still exists but is no longer visible.
            NSRange range = NSMakeRange(0, COLLECTION_VIEW_CELL_REMOVE_COUNT);
            [self.chatVC.channelDataRepository removeObjectsInRange:range];
            [self.chatVC.messageCollectionView reloadData];
        }
    }
}

- (void)scrollToLocatedMessage {
    if (self.chatVC.locatedMessageSentTime != 0) {
        for (int i = 0; i < self.chatVC.channelDataRepository.count; i++) {
            NCMessageModel *model = self.chatVC.channelDataRepository[i];
            if (model.sentTime == self.chatVC.locatedMessageSentTime) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                [self.chatVC.messageCollectionView
                    scrollToItemAtIndexPath:indexPath
                           atScrollPosition:UICollectionViewScrollPositionTop
                                   animated:NO];
                self.chatVC.locatedMessageSentTime = 0;
                break;
            }
        }
    }
}

- (void)scrollDidEnd {
    if (!self.isLoadingHistoryMessage) {
        CGFloat height = self.chatVC.messageCollectionView.frame.size.height;
        CGFloat contentOffsetY = self.chatVC.messageCollectionView.contentOffset.y;
        CGFloat bottomOffset =
            self.chatVC.messageCollectionView.contentSize.height - contentOffsetY;
        // Allow a 10-point tolerance because bottomOffset can exceed height by roughly 0.2 points
        // at the bottom.
        if (bottomOffset <= height + 10) {
            // The collection view is at the bottom.
            self.isShowingLastestMessage = YES;
        } else {
            self.isShowingLastestMessage = NO;
        }
    }
}

- (BOOL)isAtTheBottomOfTableView {
    if (self.isLoadingHistoryMessage) {
        return NO;
    }
    if (!self.isShowingLastestMessage) {
        NSIndexPath *lastIndexPath =
            [NSIndexPath indexPathForItem:self.chatVC.channelDataRepository.count - 1 inSection:0];
        BOOL isLastMessageVisible = [[self.chatVC.messageCollectionView indexPathsForVisibleItems]
            containsObject:lastIndexPath];
        self.isShowingLastestMessage = isLastMessageVisible;
    }
    return self.isShowingLastestMessage;
}

- (BOOL)isLoadingHistoryMessage {
    if (self.chatVC.channelDataRepository.count == 0) {
        return NO;
    }
    return _isLoadingHistoryMessage;
}

- (void)streamMessageCellDidUpdate:(NSNotification *)notifi {
    if (self.isShowingLastestMessage || [self isAtTheBottomOfTableView]) {
        [self.chatVC scrollToBottomAnimated:YES];
    }
}

#pragma mark - getter

- (BOOL)isMentionedEnabled {
    if (self.chatVC.channelType == NCChannelTypeGroup) {
        return NCChatUIConfigCenter.message.enableMessageMentioned;
    }
    return NO;
}

@end
