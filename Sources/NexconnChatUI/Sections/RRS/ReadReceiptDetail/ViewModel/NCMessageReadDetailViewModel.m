//
//  NCMessageReadDetailViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageReadDetailViewModel.h"
#import "NCChatUI.h"
#import "NCChatUIErrorCode.h"
#import "NCUserInfoCacheManager.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

// TODO: This still derives the NC identifier and channel from NCMessageModel. Remove it when
// message details own NC context directly.
static NCChannelIdentifier *NCChannelIdentifierFromMessageModel(NCMessageModel *messageModel) {
    NSString *channelId = messageModel.channelId ?: @"";
    switch (messageModel.channelType) {
    case NCChannelTypeDirect:
        return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeDirect
                                                      channelId:channelId];
    case NCChannelTypeGroup:
        return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeGroup
                                                      channelId:channelId];
    case NCChannelTypeSystem:
        return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeSystem
                                                      channelId:channelId];
    case NCChannelTypeCommunity:
        return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeCommunity
                                                      channelId:channelId];
    default:
        return nil;
    }
}

static NCBaseChannel *NCChannelFromMessageModel(NCMessageModel *messageModel) {
    NSString *channelId = messageModel.channelId ?: @"";
    switch (messageModel.channelType) {
    case NCChannelTypeDirect:
        return [[NCDirectChannel alloc] initWithChannelId:channelId];
    case NCChannelTypeGroup:
        return [[NCGroupChannel alloc] initWithChannelId:channelId];
    case NCChannelTypeSystem:
        return [[NCSystemChannel alloc] initWithChannelId:channelId];
    case NCChannelTypeCommunity:
        return [[NCCommunityChannel alloc] initWithChannelId:channelId];
    default:
        return nil;
    }
}

static NCChatUIUserInfo *NCReadDetailManagedUserInfo(NSString *userId, NCChannelType channelType,
                                                     NSString *channelId) {
    if (userId.length == 0) {
        return nil;
    }
    if (channelType == NCChannelTypeGroup) {
        NCChatUIUserInfo *memberInfo =
            [[NCUserInfoCacheManager sharedManager] getUserInfo:userId inGroupId:channelId];
        NCChatUIUserInfo *userInfo = [[NCUserInfoCacheManager sharedManager] getUserInfo:userId];
        if (memberInfo && userInfo.alias.length > 0) {
            memberInfo.alias = userInfo.alias;
        }
        return memberInfo ?: userInfo;
    }
    return [[NCUserInfoCacheManager sharedManager] getUserInfo:userId];
}

@interface NCMessageReadDetailViewModel ()

@property (nonatomic, strong) NCMessageModel *messageModel;
@property (nonatomic, strong) NCMessageReadDetailViewConfig *config;
@property (nonatomic, assign) NCMessageReadDetailTabType currentTabType;

// Users who have read the message.
@property (nonatomic, strong) NSMutableArray<NCMessageReadDetailCellViewModel *> *readUserList;
@property (nonatomic, strong, nullable) NCMessagesReadReceiptUsersQuery *readUsersQuery;
@property (nonatomic, assign) BOOL isLoadingRead;

// Users who have not read the message.
@property (nonatomic, strong) NSMutableArray<NCMessageReadDetailCellViewModel *> *unreadUserList;
@property (nonatomic, strong, nullable) NCMessagesReadReceiptUsersQuery *unreadUsersQuery;
@property (nonatomic, assign) BOOL isLoadingUnread;

// Pagination state.
@property (nonatomic, assign) BOOL hasMoreReadUsers;
@property (nonatomic, assign) BOOL hasMoreUnreadUsers;

// readReceiptInfo retry count.
@property (nonatomic, assign) NSInteger readInfoRetryCount;

@end

@implementation NCMessageReadDetailViewModel

/// Maximum retry count.
static const NSInteger kNCReadReceiptMaxRetryCount = 3;

/// Retry delay.
static const NSTimeInterval kNCReadReceiptRetryDelay = (1 * NSEC_PER_SEC);

- (instancetype)initWithMessageModel:(NCMessageModel *)messageModel
                              config:(NCMessageReadDetailViewConfig *)config {
    self = [super init];
    if (self) {
        _messageModel = messageModel;
        _config = config ?: [[NCMessageReadDetailViewConfig alloc] init];
        _currentTabType = NCMessageReadDetailTabTypeRead;

        _readUserList = [NSMutableArray array];
        _unreadUserList = [NSMutableArray array];

        _isLoadingRead = NO;
        _isLoadingUnread = NO;
    }
    return self;
}

- (void)bindResponder:(id<NCMessageReadDetailViewModelResponder>)responder {
    self.responder = responder;
}

- (void)switchTabToType:(NCMessageReadDetailTabType)tabType {
    if (self.currentTabType == tabType) {
        return;
    }

    self.currentTabType = tabType;

    // Load the read list when switching to it for the first time.
    if (tabType == NCMessageReadDetailTabTypeRead) {
        if (self.readUserList.count == 0 && self.readUsersQuery == nil) {
            [self loadReadUsers];
        }
    } else {
        if (self.unreadUserList.count == 0 && self.unreadUsersQuery == nil) {
            [self loadUnreadUsers];
        }
    }
}

#pragma mark - Data Loading

- (void)loadData {
    // Use existing readReceiptInfo first; if absent, fetch it from the current NCBaseChannel.
    [self loadReadReceiptInfo:^{
      // Load the read and unread lists concurrently.
      [self loadReadUsers];
      [self loadUnreadUsers];
    }];
}

- (void)loadReadUsers {
    [self loadUserListWithType:NCMessageReadDetailTabTypeRead reset:YES];
}

- (void)loadUnreadUsers {
    [self loadUserListWithType:NCMessageReadDetailTabTypeUnread reset:YES];
}

- (void)loadUserListWithType:(NCMessageReadDetailTabType)tabType reset:(BOOL)reset {
    BOOL isRead = tabType == NCMessageReadDetailTabTypeRead;
    // Avoid duplicate loads for the same list.
    BOOL isLoading = isRead ? self.isLoadingRead : self.isLoadingUnread;
    if (isLoading) {
        return;
    }

    // Mark the selected list as loading.
    if (isRead) {
        self.isLoadingRead = YES;
    } else {
        self.isLoadingUnread = YES;
    }

    if (reset) {
        NSMutableArray<NCMessageReadDetailCellViewModel *> *userList =
            isRead ? self.readUserList : self.unreadUserList;
        [userList removeAllObjects];
        if (isRead) {
            self.hasMoreReadUsers = YES;
            self.readUsersQuery = nil;
        } else {
            self.hasMoreUnreadUsers = YES;
            self.unreadUsersQuery = nil;
        }
    }

    NCMessagesReadReceiptUsersQuery *query = isRead ? self.readUsersQuery : self.unreadUsersQuery;
    if (!query) {
        NCChannelIdentifier *channelIdentifier =
            NCChannelIdentifierFromMessageModel(self.messageModel);
        if (!channelIdentifier || self.messageModel.messageId.length == 0) {
            if (isRead) {
                self.isLoadingRead = NO;
            } else {
                self.isLoadingUnread = NO;
            }
            return;
        }
        NCMessagesReadReceiptUsersQueryParams *params =
            [[NCMessagesReadReceiptUsersQueryParams alloc] init];
        params.channelIdentifier = channelIdentifier;
        params.messageId = self.messageModel.messageId;
        params.pageSize = self.config.pageSize;
        params.isAscending = NO;
        params.status =
            isRead ? NCMessageReadReceiptStatusResponded : NCMessageReadReceiptStatusUnresponded;
        query = [NCBaseChannel createMessagesReadReceiptUsersQueryWithParams:params];
        if (isRead) {
            self.readUsersQuery = query;
        } else {
            self.unreadUsersQuery = query;
        }
    }

    __weak typeof(self) weakSelf = self;
    [query loadNextPageWithCompletion:^(NCMessageReadReceiptUsersPageResult *_Nullable page,
                                        NCError *_Nullable error) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf)
          return;

      // Clear the loading state.
      if (isRead) {
          strongSelf.isLoadingRead = NO;
      } else {
          strongSelf.isLoadingUnread = NO;
      }

      if (error) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.responder updateUserListForTabType:tabType isEmpty:YES hasMoreData:NO];
          });
          return;
      }

      NSMutableArray<NCMessageReadDetailCellViewModel *> *userList =
          isRead ? strongSelf.readUserList : strongSelf.unreadUserList;

      for (NCMessageReadReceiptUser *user in page.data) {
          NCChatUIUserInfo *userInfo = NCReadDetailManagedUserInfo(
              user.userId, strongSelf.messageModel.channelType, strongSelf.messageModel.channelId);

          NCMessageReadDetailCellViewModel *cellVM =
              [[NCMessageReadDetailCellViewModel alloc] initWithUserInfo:userInfo
                                                                readTime:user.timestamp];
          [userList addObject:cellVM];
      }

      if (isRead) {
          strongSelf.hasMoreReadUsers = userList.count < query.totalCount;
      } else {
          strongSelf.hasMoreUnreadUsers = userList.count < query.totalCount;
      }

      BOOL hasMoreData = isRead ? strongSelf.hasMoreReadUsers : strongSelf.hasMoreUnreadUsers;
      dispatch_async(dispatch_get_main_queue(), ^{
        [strongSelf.responder updateUserListForTabType:tabType
                                               isEmpty:(userList.count == 0)
                                           hasMoreData:hasMoreData];
      });
    }];
}

- (void)loadMoreData {
    BOOL isRead = (self.currentTabType == NCMessageReadDetailTabTypeRead);
    BOOL hasMoreData = isRead ? self.hasMoreReadUsers : self.hasMoreUnreadUsers;
    if (!hasMoreData) {
        return;
    }
    [self loadUserListWithType:self.currentTabType reset:NO];
}

- (void)loadReadReceiptInfo:(void (^)(void))completion {
    void (^safeCompletion)(void) = ^(void) {
      !completion ?: completion();
    };
    // Reuse readReceiptInfo already attached to the message model.
    if (self.messageModel.readReceiptInfo) {
        safeCompletion();
        return;
    }

    NCBaseChannel *channel = NCChannelFromMessageModel(self.messageModel);
    if (!channel || self.messageModel.messageId.length == 0) {
        safeCompletion();
        return;
    }

    __weak typeof(self) weakSelf = self;
    [channel
        getMessageReadReceiptInfoWithMessageIds:@[ self.messageModel.messageId ]
                                     completion:^(
                                         NSArray<NCMessageReadReceiptInfo *> *_Nullable infoList,
                                         NCError *_Nullable error) {
                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       if (!strongSelf)
                                           return;

                                       // Retry throttled or temporarily empty responses.
                                       void (^retryBlock)(void) = ^(void) {
                                         if (strongSelf.readInfoRetryCount <
                                             kNCReadReceiptMaxRetryCount) {
                                             strongSelf.readInfoRetryCount++;
                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                                                          kNCReadReceiptRetryDelay),
                                                            dispatch_get_main_queue(), ^{
                                                              [strongSelf
                                                                  loadReadReceiptInfo:completion];
                                                            });
                                         } else {
                                             safeCompletion();
                                         }
                                       };

                                       if (error.code == NCChatUIErrorCodeRequestOverFrequency) {
                                           retryBlock();
                                           return;
                                       }

                                       if (!error) {
                                           // Apply a successful response on the main queue.
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                             if (infoList.count > 0) {
                                                 strongSelf.readInfoRetryCount =
                                                     0; // Reset after a successful response.
                                                 NCMessageReadReceiptInfo *info =
                                                     infoList.firstObject;
                                                 strongSelf.messageModel.readReceiptInfo = info;
                                                 [strongSelf.responder
                                                     updateTabViewWithReadCount:info.readCount
                                                                    unreadCount:info.unreadCount];
                                                 safeCompletion();
                                             } else {
                                                 // The first request may return no data, so retry
                                                 // it.
                                                 retryBlock();
                                             }
                                           });
                                       }
                                     }];
}

#pragma mark - utils

- (NSMutableArray<NCMessageReadDetailCellViewModel *> *)currentUserList {
    if (self.currentTabType == NCMessageReadDetailTabTypeUnread) {
        return self.unreadUserList;
    }
    return self.readUserList;
}

- (NSInteger)getReadCount {
    return self.messageModel.readReceiptInfo.readCount;
}

- (NSInteger)getUnreadCount {
    return self.messageModel.readReceiptInfo.unreadCount;
}

- (NSInteger)getTotalCount {
    return [self getReadCount] + [self getUnreadCount];
}

- (NSInteger)numberOfSectionsForTabType:(NCMessageReadDetailTabType)tabType {
    return 1;
}

- (NSInteger)numberOfRowsForTabType:(NCMessageReadDetailTabType)tabType
                          inSection:(NSInteger)section {
    NSArray<NCMessageReadDetailCellViewModel *> *userList =
        tabType == NCMessageReadDetailTabTypeRead ? self.readUserList : self.unreadUserList;

    return userList.count;
}

- (NCMessageReadDetailCellViewModel *)cellViewModelForTabType:(NCMessageReadDetailTabType)tabType
                                                      atIndex:(NSInteger)index {
    NSArray<NCMessageReadDetailCellViewModel *> *userList =
        tabType == NCMessageReadDetailTabTypeRead ? self.readUserList : self.unreadUserList;

    // Guard against an out-of-bounds index.
    if (index < 0 || index >= userList.count) {
        return nil;
    }

    return userList[index];
}

- (CGFloat)cellHeightForTabType:(NCMessageReadDetailTabType)tabType atIndex:(NSInteger)index {
    NCMessageReadDetailCellViewModel *cellViewModel = [self cellViewModelForTabType:tabType
                                                                            atIndex:index];
    return cellViewModel ? cellViewModel.cellHeight : 0;
}

@end
