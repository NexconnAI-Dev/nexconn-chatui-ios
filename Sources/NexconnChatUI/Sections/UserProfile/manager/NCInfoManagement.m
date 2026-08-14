//
//  NCInfoManagement.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCInfoManagement.h"
#import "NCChatUIUserInfo.h"
#import "NCChatUIGroup.h"
#import "NCUserInfoCacheManager.h"
#import "NCInfoManagementCache.h"
#import "NCInfoUpdateCenter.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIErrorCode.h"
#import "NCChatUI.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCReadWriteLock.h"
#import "NSMutableArray+NCOperation.h"
#import "NCChannelInfoCache.h"

static NSUInteger const NC_KIT_FETCH_INFO_UINT_6 = 6;
static float const NC_KIT_FETCH_INFO_DELAY_TIME = 0.5;
static NSUInteger const NC_KIT_BATCH_FETCH_SIZE = 100;
static NSString * const NCInfoManagementGroupHandlerIdentifier = @"NCInfoManagementGroupHandlerIdentifier";
static NSString * const NCInfoManagementUserHandlerIdentifier = @"NCInfoManagementUserHandlerIdentifier";
static NSString * const NCInfoManagementConnectionHandlerIdentifier = @"NCInfoManagementConnectionHandlerIdentifier";

static BOOL NCGroupOperationMemberInfosContainUser(NCGroupOperationEvent *event, NSString *userId) {
    if (userId.length == 0) {
        return NO;
    }
    for (NCGroupMemberInfo *memberInfo in event.memberInfos) {
        if ([memberInfo.userId isEqualToString:userId]) {
            return YES;
        }
    }
    return NO;
}

static BOOL NCGroupOperationInvalidatesCurrentUser(NCGroupOperationEvent *event) {
    if (event.operation == NCGroupOperationDismiss) {
        return YES;
    }
    if (event.operation != NCGroupOperationKick && event.operation != NCGroupOperationQuit) {
        return NO;
    }
    return NCGroupOperationMemberInfosContainUser(event, [NCEngine getCurrentUserId]);
}

@interface NCInfoManagement ()<NCGroupChannelHandler, NCUserHandler, NCConnectionStatusHandler>

@property (nonatomic, strong) NCInfoManagementCache *cache;

@property (nonatomic, copy) NSString *userId;

/// User IDs currently being fetched, protected by userFetchingLock.
@property (nonatomic, strong) NSMutableSet<NSString *> *fetchingUserIds;

/// Group-member request keys currently being fetched, formatted as groupId_userId.
@property (nonatomic, strong) NSMutableSet<NSString *> *fetchingGroupMemberKeys;

/// Group IDs currently being fetched.
@property (nonatomic, strong) NSMutableSet<NSString *> *fetchingGroupIds;

/// 网络失败等待重拉的 userId 集合（使用 userFetchingLock 保护）
@property (nonatomic, strong) NSMutableSet<NSString *> *pendingRetryUserIds;

/// 网络失败等待重拉的群成员集合（groupId → userId 集合，使用 memberFetchingLock 保护）
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *pendingRetryGroupMembers;

/// 网络失败等待重拉的群组ID集合（使用 groupFetchingLock 保护）
@property (nonatomic, strong) NSMutableSet<NSString *> *pendingRetryGroupIds;

/// 读写锁，用于保护 fetchingUserIds 的并发读、独占写
@property (nonatomic, strong) NCReadWriteLock *userFetchingLock;

/// Read-write lock for concurrent reads and exclusive writes to fetchingGroupMemberKeys.
@property (nonatomic, strong) NCReadWriteLock *memberFetchingLock;

/// Read-write lock for concurrent reads and exclusive writes to fetchingGroupIds.
@property (nonatomic, strong) NCReadWriteLock *groupFetchingLock;

- (NCChatUIGroup *)p_chatUIGroupFromGroupInfo:(NCGroupInfo *)groupInfo;
- (NCChatUIGroup *)p_chatUIGroupByMergingEventGroup:(NCChatUIGroup *)groupInfo
                                  changedProperties:(NSArray<NSString *> *)changedProperties;
- (void)p_removeFetchingGroupMemberKeysInGroup:(NSString *)groupId;

@end

@implementation NCInfoManagement

/// 统一的重试错误码判断（适用于所有资料获取场景）
+ (BOOL)p_shouldRetryForErrorCode:(NSInteger)errorCode {
    return errorCode == NCChatUIErrorCodeNetDataIsSynchronizing ||
           errorCode == NCChatUIErrorCodeRequestOverFrequency ||
           errorCode == NCChatUIErrorCodeNetworkUnavailable;
}

+ (instancetype)sharedInstance {
    static NCInfoManagement *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.userId = [NCEngine getCurrentUserId];
        
        // 初始化读写锁
        instance.userFetchingLock = [NCReadWriteLock new];
        instance.memberFetchingLock = [NCReadWriteLock new];
        instance.groupFetchingLock = [NCReadWriteLock new];

        [NCEngine addGroupChannelHandlerWithIdentifier:NCInfoManagementGroupHandlerIdentifier
                                               handler:instance];
        [NCEngine addUserHandlerWithIdentifier:NCInfoManagementUserHandlerIdentifier
                                       handler:instance];
        [NCEngine addConnectionStatusHandlerWithIdentifier:NCInfoManagementConnectionHandlerIdentifier
                                                   handler:instance];
    });
    return instance;
}

#pragma mark -- public sync

- (nullable NCChatUIUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId {
    if (userId.length == 0) {
        return nil;
    }
    return [self.cache getUserCache:userId];
}

- (nullable NCChatUIUserInfo *)getGroupMemberFromCacheOnly:(NSString *)userId withGroupId:(NSString *)groupId {
    if (userId.length == 0 || groupId.length == 0) {
        return nil;
    }
    NCChatUIUserInfo *user = [self.cache getGroupMemberCache:userId groupId:groupId];
    return [self p_getMemberCache:user];
}

- (nullable NCChatUIGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId {
    if (groupId.length == 0) {
        return nil;
    }
    return [self.cache getGroupCache:groupId];
}

- (void)refreshUserInfo:(NCChatUIUserInfo *)userInfo {
    if (userInfo.userId.length == 0) {
        return;
    }
    NCChatUIUserInfo *resolvedUserInfo = [self p_userInfoFromFlatUserInfo:userInfo];
    [self refreshUserInfo:resolvedUserInfo complete:^(BOOL ret) {
        if (ret) {
            [self.cache cacheUser:resolvedUserInfo];
            [NCInfoUpdateCenter dispatchUserInfoUpdate:resolvedUserInfo];
        }
    }];
}

- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId {
    if (userId.length == 0) {
        return nil;
    }
    NCChatUIUserInfo *user = [self.cache getUserCache:userId];
    if (user) {
        return user;
    }
    
    // Avoid starting a duplicate request.
    if ([self p_isUserFetching:userId]) {
        NCLogD(@"[InfoManagement] user is fetching: %@", userId);
        return nil;
    }
    
    [self p_getUserInfo:userId complete:^(NCChatUIUserInfo *user) {
        if (user) {
            [self.cache cacheUser:user];
            [NCInfoUpdateCenter dispatchUserInfoUpdate:user];
        }
    }];
    return nil;
}

- (void)getUserInfo:(NSString *)userId complete:(void (^)(NCChatUIUserInfo * _Nonnull))complete {
    [self p_getUserInfo:userId complete:^(NCChatUIUserInfo *user) {
        [self.cache cacheUser:user];
        if (complete) {
            complete(user);
        }
    }];
}

- (NSArray<NCChatUIUserInfo *> *)getUserInfosFromCacheOnly:(NSArray<NSString *> *)userIds {
    if (userIds.count == 0) {
        return @[];
    }
    
    NSMutableArray *cachedUsers = [NSMutableArray array];
    for (NSString *userId in userIds) {
        NCChatUIUserInfo *user = [self.cache getUserCache:userId];
        if (user) {
            [cachedUsers addObject:user];
        }
    }
    
    return [cachedUsers copy];
}

- (void)loadUserInfos:(NSArray<NSString *> *)userIds {
    if (userIds.count == 0) {
        return;
    }
    
    // 1. Read cached entries.
    NSArray<NCChatUIUserInfo *> *cachedUsers = [self getUserInfosFromCacheOnly:userIds];
    
    // 2. Determine missing IDs.
    NSMutableSet *cachedUserIdsSet = [NSMutableSet setWithArray:[cachedUsers valueForKey:@"userId"]];
    [cachedUserIdsSet removeObject:[NSNull null]];  // Remove NSNull values produced for nil properties.
    NSMutableSet *missingUserIdsSet = [NSMutableSet setWithArray:userIds];
    [missingUserIdsSet minusSet:cachedUserIdsSet];
    
    // 3. Return when every entry was cached.
    if (missingUserIdsSet.count == 0) {
        return;
    }
    
    // 4. Mark new requests and batch-fetch them; consumers update through notifications.
    NSArray *userIdsToFetch = [self p_filterAndMarkFetchingUserIds:missingUserIdsSet.allObjects];
    if (userIdsToFetch.count > 0) {
        [self p_batchFetchUserInfos:userIdsToFetch complete:nil];
    }
}

- (void)fetchUserInfos:(NSArray<NSString *> *)userIds {
    if (userIds.count == 0) {
        return;
    }
    
    // Mark new requests and batch-fetch them; consumers update through notifications.
    NSArray *userIdsToFetch = [self p_filterAndMarkFetchingUserIds:userIds];
    if (userIdsToFetch.count > 0) {
        [self p_batchFetchUserInfos:userIdsToFetch complete:nil];
    }
}

- (void)clearUserInfo:(NSString *)userId {
    [self.cache removeUserCache:userId];
}

- (void)clearAllUserInfo {
    [self.cache removeAllUserCache];
}

- (NCChatUIUserInfo *)getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId{
    if (userId.length == 0 || groupId.length == 0) {
        return nil;
    }
    NCChatUIUserInfo *user = [self.cache getGroupMemberCache:userId groupId:groupId];
    if (user) {
        return [self p_getMemberCache:user];
    }
    
    // Avoid starting a duplicate request.
    if ([self p_isGroupMemberFetching:userId groupId:groupId]) {
        NCLogD(@"[InfoManagement] group member is fetching: %@ in group: %@", userId, groupId);
        return nil;
    }
    
    [self p_getGroupMember:userId withGroupId:groupId complete:^(NCChatUIUserInfo * _Nullable user) {
        if (user) {
            [self.cache cacheGroupMember:user groupId:groupId];
            [NCInfoUpdateCenter dispatchGroupMemberInfoUpdate:user groupId:groupId];
        }
    }];
    
    return nil;
}

- (void)getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId complete:(void (^)(NCChatUIUserInfo * _Nullable))complete {
    [self p_getGroupMember:userId withGroupId:groupId complete:^(NCChatUIUserInfo * _Nullable user) {
        [self.cache cacheGroupMember:user groupId:groupId];
        if (complete) {
            complete([self p_getMemberCache:user]);
        }
    }];
}

- (NSArray<NCChatUIUserInfo *> *)getGroupMembersFromCacheOnly:(NSArray<NSString *> *)userIds withGroupId:(NSString *)groupId {
    if (userIds.count == 0 || groupId.length == 0) {
        return @[];
    }
    NSMutableArray *cachedUsers = [NSMutableArray array];
    for (NSString *userId in userIds) {
        NCChatUIUserInfo *user = [self.cache getGroupMemberCache:userId groupId:groupId];
        if (user) {
            [cachedUsers addObject:[self p_getMemberCache:user]];
        }
    }
    return [cachedUsers copy];
}

- (void)preloadGroupMembers:(NSArray<NSString *> *)userIds 
                 inGroup:(NSString *)groupId {
    if (userIds.count == 0 || groupId.length == 0) {
        return;
    }
    
    // 1. Read cached entries.
    NSArray<NCChatUIUserInfo *> *cachedMembers = [self getGroupMembersFromCacheOnly:userIds withGroupId:groupId];
    
    // 2. Determine missing IDs.
    NSMutableSet *cachedUserIdsSet = [NSMutableSet setWithArray:[cachedMembers valueForKey:@"userId"]];
    [cachedUserIdsSet removeObject:[NSNull null]];  // Remove NSNull values produced for nil properties.
    NSMutableSet *missingUserIdsSet = [NSMutableSet setWithArray:userIds];
    [missingUserIdsSet minusSet:cachedUserIdsSet];
    
    // 3. Return when every entry was cached.
    if (missingUserIdsSet.count == 0) {
        return;
    }
    
    // 4. Mark new requests and batch-fetch them.
    NSArray *userIdsToFetch = [self p_filterAndMarkFetchingGroupMemberKeys:missingUserIdsSet.allObjects 
                                                                    groupId:groupId];
    if (userIdsToFetch.count > 0) {
        [self p_batchFetchGroupMembers:userIdsToFetch groupId:groupId complete:nil];
    }
}

- (void)fetchGroupMembers:(NSArray<NSString *> *)userIds withGroupId:(NSString *)groupId {
    if (userIds.count == 0 || !groupId) {
        return;
    }
    
    // Mark new requests and batch-fetch them; consumers update through notifications.
    NSArray *userIdsToFetch = [self p_filterAndMarkFetchingGroupMemberKeys:userIds groupId:groupId];
    if (userIdsToFetch.count > 0) {
        [self p_batchFetchGroupMembers:userIdsToFetch groupId:groupId complete:nil];
    }
}

- (void)refreshGroupMember:(NCChatUIUserInfo *)userInfo withGroupId:(NSString *)groupId {
    if (userInfo.userId.length == 0  || groupId.length == 0) {
        return;
    }
    NCChatUIUserInfo *resolvedUserInfo = [self p_userInfoFromFlatUserInfo:userInfo];
    [self refreshGroupMember:resolvedUserInfo withGroupId:groupId complete:^(BOOL ret) {
        if (ret) {
            [self.cache cacheGroupMember:resolvedUserInfo groupId:groupId];
            [NCInfoUpdateCenter dispatchGroupMemberInfoUpdate:resolvedUserInfo groupId:groupId];
        }
    }];
}

- (void)clearGroupMember:(NSString *)userId inGroup:(NSString *)groupId {
    [self.cache removeGroupMemberCache:userId groupId:groupId];
}

- (void)clearAllGroupMember {
    [self.cache removeAllGroupMemberCache];
}

- (NCChatUIGroup *)getGroupInfo:(NSString *)groupId {
    if (groupId.length == 0) {
        return nil;
    }
    NCChatUIGroup *group = [self getGroupInfoFromCacheOnly:groupId];
    if (group) {
        return group;
    }
    
    // Check request state under the read lock.
    if ([self p_isGroupFetching:groupId]) {
        NCLogD(@"[InfoManagement] group is fetching: %@", groupId);
        return nil;
    }
    
    [self p_getGroupInfo:groupId complete:^(NCChatUIGroup * _Nullable group) {
        if (group) {
            [NCInfoUpdateCenter dispatchGroupInfoUpdate:group];
        }
    }];
    
    return nil;
}

- (void)getGroupInfo:(NSString *)groupId complete:(void (^)(NCChatUIGroup * _Nullable))complete {
    [self p_getGroupInfo:groupId complete:^(NCChatUIGroup * _Nullable groupInfo) {
        if (complete) {
            complete(groupInfo);
        }
    }];
}

- (NSArray<NCChatUIGroup *> *)getGroupInfosFromCacheOnly:(NSArray<NSString *> *)groupIds {
    if (groupIds.count == 0) {
        return @[];
    }
    NSMutableArray *cachedGroups = [NSMutableArray array];
    for (NSString *groupId in groupIds) {
        NCChatUIGroup *group = [self getGroupInfoFromCacheOnly:groupId];
        if (group) {
            [cachedGroups addObject:group];
        }
    }
    return [cachedGroups copy];
}

- (void)preloadGroupInfos:(NSArray<NSString *> *)groupIds {
    if (groupIds.count == 0) {
        return;
    }
    
    // 1. Read cached entries.
    NSArray<NCChatUIGroup *> *cachedGroups = [self getGroupInfosFromCacheOnly:groupIds];
    
    // 2. Determine missing IDs.
    NSMutableSet *cachedGroupIdsSet = [NSMutableSet setWithArray:[cachedGroups valueForKey:@"groupId"]];
    [cachedGroupIdsSet removeObject:[NSNull null]];
    NSMutableSet *missingGroupIdsSet = [NSMutableSet setWithArray:groupIds];
    [missingGroupIdsSet minusSet:cachedGroupIdsSet];
    
    // 3. Return when every entry was cached.
    if (missingGroupIdsSet.count == 0) {
        return;
    }
    
    // 4. Mark new requests and batch-fetch them; consumers update through notifications.
    NSArray *groupIdsToFetch = [self p_filterAndMarkFetchingGroupIds:missingGroupIdsSet.allObjects];
    if (groupIdsToFetch.count > 0) {
        [self p_batchFetchGroupInfos:groupIdsToFetch complete:nil];
    }
}

- (void)fetchGroupInfos:(NSArray<NSString *> *)groupIds {
    if (groupIds.count == 0) {
        return;
    }
    
    // Mark new requests and batch-fetch them; consumers update through notifications.
    NSArray *groupIdsToFetch = [self p_filterAndMarkFetchingGroupIds:groupIds];
    if (groupIdsToFetch.count > 0) {
        [self p_batchFetchGroupInfos:groupIdsToFetch complete:nil];
    }
}


- (void)refreshGroupInfo:(NCChatUIGroup *)groupInfo {
    if (groupInfo.groupId.length == 0) {
        return;
    }
    [self refreshGroupInfo:groupInfo complete:^(BOOL ret) {
        if (ret) {
            [NCInfoUpdateCenter dispatchGroupInfoUpdate:groupInfo];
        }
    }];
}

- (void)refreshGroupInfoCache:(NCChatUIGroup *)groupInfo {
    if (groupInfo.groupId.length == 0) {
        return;
    }

    NCChatUIGroup *displayGroup = [NCChatUIGroup new];
    displayGroup.groupId = groupInfo.groupId;
    displayGroup.groupName = groupInfo.groupName;
    displayGroup.avatarUrl = groupInfo.avatarUrl;
    displayGroup.extra = groupInfo.extra;
    displayGroup.notice = groupInfo.notice;
    [self.cache cacheGroup:displayGroup];
    [NCInfoUpdateCenter dispatchGroupInfoUpdate:displayGroup];
}

- (void)clearGroupInfo:(NSString *)groupId {
    [self.cache removeGroupCache:groupId];
}

- (void)clearAllGroupInfo {
    [self.cache removeAllGroupCache];
}

- (void)updateMyUserProfile:(NCUserProfile *)profile
                    success:(void (^)(void))successBlock
                      error:(nullable void (^)(NSInteger errorCode, NSString * _Nullable errorKey))errorBlock {
    [[NCEngine userModule] updateMyUserProfile:profile completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        if (error) {
            if (errorBlock) {
                errorBlock(error.code, errorKeys.firstObject);
            }
            return;
        }
        [self getUserInfo:profile.userId complete:nil];
        if (successBlock) {
            successBlock();
        }
    }];
}

- (void)updateMyUserProfile:(NCUserProfile *)profile
               successBlock:(void (^)(void))successBlock
                 errorBlock:(nullable void (^)(NSInteger errorCode,  NSArray<NSString *> * _Nullable errorKeys))errorBlock {
    [[NCEngine userModule] updateMyUserProfile:profile completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        if (error) {
            if (errorBlock) {
                errorBlock(error.code, errorKeys);
            }
            return;
        }
        [self getUserInfo:profile.userId complete:nil];
        if (successBlock) {
            successBlock();
        }
    }];
}


- (void)setFriendInfo:(NSString *)userId
               remark:(nullable NSString *)remark
           extProfile:(nullable NSDictionary<NSString *, NSString*> *)extProfile
              success:(void (^)(void))successBlock
                error:(void (^)(NSInteger errorCode))errorBlock {
    NCSetFriendInfoParams *params = [[NCSetFriendInfoParams alloc] initWithUserId:userId];
    params.remark = remark;
    params.extProfile = extProfile;
    [[NCEngine userModule] setFriendInfoWithParams:params completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        if (error) {
            if (errorBlock) {
                errorBlock(error.code);
            }
            return;
        }
        [self p_cacheAndDispatchFriendRemarkForUserId:userId remark:remark];
        [self p_refreshUserCacheAfterFriendInfoChanged:userId];
        if (successBlock) {
            successBlock();
        }
    }];
}

- (void)setFriendInfo:(NSString *)userId
               remark:(nullable NSString *)remark
           extProfile:(nullable NSDictionary<NSString *, NSString*> *)extProfile
         successBlock:(void (^)(void))successBlock
           errorBlock:(void (^)(NSInteger errorCode, NSArray<NSString *> * _Nullable errorKeys))errorBlock {
    NCSetFriendInfoParams *params = [[NCSetFriendInfoParams alloc] initWithUserId:userId];
    params.remark = remark;
    params.extProfile = extProfile;
    [[NCEngine userModule] setFriendInfoWithParams:params completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        if (error) {
            if (errorBlock) {
                errorBlock(error.code, errorKeys);
            }
            return;
        }
        [self p_cacheAndDispatchFriendRemarkForUserId:userId remark:remark];
        [self p_refreshUserCacheAfterFriendInfoChanged:userId];
        if (successBlock) {
            successBlock();
        }
    }];
}

- (void)updateGroupInfo:(NCGroupInfo *)groupInfo
                success:(void (^)(void))successBlock
                  error:(void (^)(NSInteger errorCode, NSString *errorKey))errorBlock {
    NCUpdateGroupInfoParams *params = [self p_updateGroupInfoParamsFromGroupInfo:groupInfo];
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:groupInfo.groupId];
    [channel updateInfoWithParams:params completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        if (error) {
            if (errorBlock) {
                errorBlock(error.code, errorKeys.firstObject);
            }
            return;
        }
        [self getGroupInfo:groupInfo.groupId complete:nil];
        if (successBlock) {
            successBlock();
        }
    }];
}

- (void)updateGroupInfo:(NCGroupInfo *)groupInfo
           successBlock:(void (^)(void))successBlock
             errorBlock:(void (^)(NSInteger errorCode, NSArray<NSString *> * _Nullable errorKeys))errorBlock {
    NCUpdateGroupInfoParams *params = [self p_updateGroupInfoParamsFromGroupInfo:groupInfo];
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:groupInfo.groupId];
    [channel updateInfoWithParams:params completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        if (error) {
            if (errorBlock) {
                errorBlock(error.code, errorKeys);
            }
            return;
        }
        [self getGroupInfo:groupInfo.groupId complete:nil];
        if (successBlock) {
            successBlock();
        }
    }];
}

- (void)setGroupMemberInfo:(NSString *)groupId
                    userId:(NSString *)userId
                  nickname:(nullable NSString *)nickname
                     extra:(nullable NSString *)extra
                   success:(void (^)(void))successBlock
                     error:(void (^)(NSInteger errorCode))errorBlock {
    NCSetGroupMemberInfoParams *params = [NCSetGroupMemberInfoParams new];
    params.userId = userId;
    params.nickname = nickname;
    params.extra = extra;
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:groupId];
    [channel setMemberInfoWithParams:params completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        if (error) {
            if (errorBlock) {
                errorBlock(error.code);
            }
            return;
        }
        [self p_cacheAndDispatchGroupMember:[self p_groupMember:userId nickname:nickname extra:extra] groupId:groupId];
        if (successBlock) {
            successBlock();
        }
    }];
}

- (void)setGroupMemberInfo:(NSString *)groupId
                    userId:(NSString *)userId
                  nickname:(nullable NSString *)nickname
                     extra:(nullable NSString *)extra
              successBlock:(void (^)(void))successBlock
                errorBlock:(void (^)(NSInteger errorCode, NSArray<NSString *> * _Nullable errorKeys))errorBlock {
    NCSetGroupMemberInfoParams *params = [NCSetGroupMemberInfoParams new];
    params.userId = userId;
    params.nickname = nickname;
    params.extra = extra;
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:groupId];
    [channel setMemberInfoWithParams:params completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        if (error) {
            if (errorBlock) {
                errorBlock(error.code, errorKeys);
            }
            return;
        }
        [self p_cacheAndDispatchGroupMember:[self p_groupMember:userId nickname:nickname extra:extra] groupId:groupId];
        if (successBlock) {
            successBlock();
        }
    }];
}
#pragma mark -- private batch fetch

/// Recursively processes items in batches and invokes complete once with accumulated results.
/// @param allItems All items to process.
/// @param startIndex Start index of the current batch.
/// @param accumulatedResults Results accumulated across completed batches.
/// @param batchProcessor Processes one batch and invokes continueNextBatch when that batch is finished.
- (void)p_processBatchItems:(NSArray *)allItems
                  startIndex:(NSUInteger)startIndex
          accumulatedResults:(NSMutableArray *)accumulatedResults
              batchProcessor:(void(^)(NSArray *batchItems, 
                                      NSUInteger batchStart, 
                                      NSUInteger batchEnd, 
                                      void(^continueNextBatch)(void)))batchProcessor
                    complete:(nullable void(^)(NSArray *results))complete {
    // Finish after every batch has been processed.
    if (startIndex >= allItems.count) {
        if (complete) {
            complete([accumulatedResults copy]);
        }
        return;
    }
    
    // Calculate the current batch range.
    NSUInteger endIndex = MIN(startIndex + NC_KIT_BATCH_FETCH_SIZE, allItems.count);
    NSArray *batchItems = [allItems subarrayWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
    
    // Process the current batch.
    batchProcessor(batchItems, startIndex, endIndex, ^{
        // Continue with the next batch.
        [self p_processBatchItems:allItems
                       startIndex:endIndex
               accumulatedResults:accumulatedResults
                   batchProcessor:batchProcessor
                         complete:complete];
    });
}

- (NSArray<NSString *> *)p_filterAndMarkFetching:(NSArray<NSString *> *)items
                                      fetchingSet:(NSMutableSet<NSString *> *)fetchingSet
                                             lock:(NCReadWriteLock *)lock {
    if (items.count == 0) {
        return @[];
    }
    NSMutableSet *itemsToFetchSet = [NSMutableSet setWithArray:items];
    [lock performWriteLockBlock:^{
        // Exclude requests already in flight.
        [itemsToFetchSet minusSet:fetchingSet];
        // Mark the remaining items as in flight.
        [fetchingSet unionSet:itemsToFetchSet];
    }];
    return [itemsToFetchSet allObjects];
}

- (void)p_removeFetching:(NSArray<NSString *> *)items
             fetchingSet:(NSMutableSet<NSString *> *)fetchingSet
                    lock:(NCReadWriteLock *)lock {
    if (items.count == 0) {
        return;
    }
    NSSet *itemsSet = [NSSet setWithArray:items];
    [lock performWriteLockBlock:^{
        [fetchingSet minusSet:itemsSet];
    }];
}

/// Returns YES when the user is currently being fetched.
- (BOOL)p_isUserFetching:(NSString *)userId {
    if (!userId) return NO;
    
    __block BOOL result = NO;
    [self.userFetchingLock performReadLockBlock:^{
        result = [self.fetchingUserIds containsObject:userId];
    }];
    return result;
}

/// Excludes in-flight user IDs, marks new IDs as in flight, and returns IDs to request.
- (NSArray<NSString *> *)p_filterAndMarkFetchingUserIds:(NSArray<NSString *> *)userIds {
    return [self p_filterAndMarkFetching:userIds
                             fetchingSet:self.fetchingUserIds
                                    lock:self.userFetchingLock];
}

/// Removes completed user IDs from fetchingUserIds.
- (void)p_removeFetchingUserIds:(NSArray<NSString *> *)userIds {
    [self p_removeFetching:userIds
               fetchingSet:self.fetchingUserIds
                      lock:self.userFetchingLock];
}

/// Returns YES when the group member is currently being fetched.
- (BOOL)p_isGroupMemberFetching:(NSString *)userId groupId:(NSString *)groupId {
    if (!userId || !groupId) return NO;
    
    __block BOOL result = NO;
    NSString *key = [NSString stringWithFormat:@"%@_%@", groupId, userId];
    [self.memberFetchingLock performReadLockBlock:^{
        result = [self.fetchingGroupMemberKeys containsObject:key];
    }];
    return result;
}

- (NSArray<NSString *> *)p_filterAndMarkFetchingGroupMemberKeys:(NSArray<NSString *> *)userIds
                                                        groupId:(NSString *)groupId {
    if (userIds.count == 0 || !groupId) {
        return @[];
    }
    
    // Build composite request keys.
    NSMutableSet *inputKeys = [NSMutableSet setWithCapacity:userIds.count];
    for (NSString *userId in userIds) {
        NSString *key = [NSString stringWithFormat:@"%@_%@", groupId, userId];
        [inputKeys addObject:key];
    }
    
    [self.memberFetchingLock performWriteLockBlock:^{
        // Exclude requests already in flight.
        [inputKeys minusSet:self.fetchingGroupMemberKeys];
        // Mark the remaining keys as in flight.
        [self.fetchingGroupMemberKeys unionSet:inputKeys];
    }];
    
    // Recover user IDs from the composite keys.
    NSUInteger prefixLength = groupId.length + 1;  // Length of the "groupId_" prefix.
    NSMutableArray *userIdsToFetch = [NSMutableArray arrayWithCapacity:inputKeys.count];
    for (NSString *key in inputKeys) {
        // Extract userId after the "groupId_" prefix.
        if (key.length > prefixLength) {
            NSString *userId = [key substringFromIndex:prefixLength];
            [userIdsToFetch nc_addObject:userId];
        }
    }
    return [userIdsToFetch copy];
}

/// Removes completed group-member request markers.
- (void)p_removeFetchingGroupMemberKeys:(NSArray<NSString *> *)userIds
                                groupId:(NSString *)groupId {
    if (userIds.count == 0 || !groupId) {
        return;
    }
    
    NSMutableSet *keysToRemove = [NSMutableSet setWithCapacity:userIds.count];
    for (NSString *userId in userIds) {
        NSString *key = [NSString stringWithFormat:@"%@_%@", groupId, userId];
        [keysToRemove addObject:key];
    }
    
    
    [self.memberFetchingLock performWriteLockBlock:^{
        [self.fetchingGroupMemberKeys minusSet:keysToRemove];
    }];
}

- (void)p_removeFetchingGroupMemberKeysInGroup:(NSString *)groupId {
    if (groupId.length == 0) {
        return;
    }
    NSString *prefix = [NSString stringWithFormat:@"%@_", groupId];
    [self.memberFetchingLock performWriteLockBlock:^{
        NSMutableSet<NSString *> *keysToRemove = [NSMutableSet set];
        for (NSString *key in self.fetchingGroupMemberKeys) {
            if ([key hasPrefix:prefix]) {
                [keysToRemove addObject:key];
            }
        }
        [self.fetchingGroupMemberKeys minusSet:keysToRemove];
        [self.pendingRetryGroupMembers removeObjectForKey:groupId];
    }];
}

/// 群组是否正在请求中，YES 表示正在请求中
- (BOOL)p_isGroupFetching:(NSString *)groupId {
    if (!groupId) return NO;
    
    __block BOOL result = NO;
    [self.groupFetchingLock performReadLockBlock:^{
        result = [self.fetchingGroupIds containsObject:groupId];
    }];
    return result;
}

/// Excludes in-flight group IDs, marks new IDs as in flight, and returns IDs to request.
- (NSArray<NSString *> *)p_filterAndMarkFetchingGroupIds:(NSArray<NSString *> *)groupIds {
    return [self p_filterAndMarkFetching:groupIds
                             fetchingSet:self.fetchingGroupIds
                                    lock:self.groupFetchingLock];
}

/// Removes completed group request markers.
- (void)p_removeFetchingGroupIds:(NSArray<NSString *> *)groupIds {
    [self p_removeFetching:groupIds
               fetchingSet:self.fetchingGroupIds
                      lock:self.groupFetchingLock];
}

/// Fetches group-member info in batches and returns accumulated results once complete.
- (void)p_batchFetchGroupMembers:(NSArray<NSString *> *)userIds
                         groupId:(NSString *)groupId
                        complete:(nullable void (^)(NSArray<NCChatUIUserInfo *> *))complete {
    if (userIds.count == 0 || groupId.length == 0) {
        if (complete) {
            complete(@[]);
        }
        return;
    }
    
    NSMutableArray *accumulatedResults = [NSMutableArray array];
    [self p_processBatchItems:userIds
                   startIndex:0
           accumulatedResults:accumulatedResults
               batchProcessor:^(NSArray *batchUserIds, NSUInteger batchStart, NSUInteger batchEnd, void(^continueNextBatch)(void)) {
        
        [self p_batchGetGroupMembers:batchUserIds
                             groupId:groupId
                          retryCount:NC_KIT_FETCH_INFO_UINT_6
                            complete:^(NSArray<NCGroupMemberInfo *> *groupMembers) {
            
            // Cache each member, dispatch its update notification, and accumulate the final completion result.
            for (NCGroupMemberInfo *memberInfo in groupMembers) {
                if (!memberInfo) {
                    continue;
                }
                NCChatUIUserInfo *managedUser = [NCChatUIUserInfo new];
                managedUser.memberInfo = memberInfo;
                [self.cache cacheGroupMember:managedUser groupId:groupId];
                [NCInfoUpdateCenter dispatchGroupMemberInfoUpdate:managedUser groupId:groupId];
                [accumulatedResults addObject:managedUser];
            }
            
            // Remove request markers for the current batch.
            [self p_removeFetchingGroupMemberKeys:batchUserIds groupId:groupId];
            
            // Continue with the next batch.
            continueNextBatch();
        }];
    } complete:complete];
}

/// Fetches one group-member batch with retries.
- (void)p_batchGetGroupMembers:(NSArray<NSString *> *)userIds
                       groupId:(NSString *)groupId
                    retryCount:(NSUInteger)retryCount
                      complete:(void (^)(NSArray<NCGroupMemberInfo *> *groupMembers))complete {
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:groupId ?: @""];
    if (!channel) {
        if (complete) {
            complete(@[]);
        }
        return;
    }
    [channel getMembersWithUserIds:userIds completion:^(NSArray<NCGroupMemberInfo *> * _Nullable groupMembers, NCError * _Nullable error) {
        if (!error) {
            if (complete) {
                complete(groupMembers ?: @[]);
            }
            return;
        }
        // 数据同步中、请求过频或网络不可用时重试
        if ([NCInfoManagement p_shouldRetryForErrorCode:error.code] && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_batchGetGroupMembers:userIds groupId:groupId retryCount:retryCount - 1 complete:complete];
            });
        } else {
            // 重试用完，记录失败待网络恢复后补拉
            [self.memberFetchingLock performWriteLockBlock:^{
                NSMutableSet *users = self.pendingRetryGroupMembers[groupId];
                if (!users) {
                    users = [NSMutableSet set];
                    self.pendingRetryGroupMembers[groupId] = users;
                }
                [users addObjectsFromArray:userIds];
            }];
            // 失败时返回空数组
            if (complete) {
                complete(@[]);
            }
        }
    }];
}

/// Fetches group info in batches and returns accumulated results once complete.
- (void)p_batchFetchGroupInfos:(NSArray<NSString *> *)groupIds
                      complete:(nullable void (^)(NSArray<NCChatUIGroup *> *))complete {
    if (groupIds.count == 0) {
        if (complete) {
            complete(@[]);
        }
        return;
    }
    
    NSMutableArray *accumulatedResults = [NSMutableArray array];
    [self p_processBatchItems:groupIds
                   startIndex:0
           accumulatedResults:accumulatedResults
               batchProcessor:^(NSArray *batchGroupIds, NSUInteger batchStart, NSUInteger batchEnd, void(^continueNextBatch)(void)) {
        
        [self p_batchGetGroupInfos:batchGroupIds
                        retryCount:NC_KIT_FETCH_INFO_UINT_6
                          complete:^(NSArray<NCGroupInfo *> *groupInfos) {
            
            // Cache each group, dispatch its update notification, and accumulate the final completion result.
            for (NCGroupInfo *groupInfo in groupInfos) {
                NCChatUIGroup *managedGroup = [self p_chatUIGroupFromGroupInfo:groupInfo];
                [self.cache cacheGroup:managedGroup];
                [NCInfoUpdateCenter dispatchGroupInfoUpdate:managedGroup];

                [accumulatedResults addObject:managedGroup];
            }
            
            // Remove request markers for the current batch.
            [self p_removeFetchingGroupIds:batchGroupIds];
            
            // Continue with the next batch.
            continueNextBatch();
        }];
    } complete:complete];
}

/// Fetches one group-info batch with retries.
- (void)p_batchGetGroupInfos:(NSArray<NSString *> *)groupIds
                   retryCount:(NSUInteger)retryCount
                     complete:(void (^)(NSArray<NCGroupInfo *> *groupInfos))complete {
    [NCGroupChannel getGroupsInfoWithGroupIds:groupIds completion:^(NSArray<NCGroupInfo *> * _Nullable groupInfos, NCError * _Nullable error) {
        if (!error) {
            if (complete) {
                complete(groupInfos ?: @[]);
            }
            return;
        }
        // 数据同步中、请求过频或网络不可用时重试
        if ([NCInfoManagement p_shouldRetryForErrorCode:error.code] && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_batchGetGroupInfos:groupIds retryCount:retryCount - 1 complete:complete];
            });
        } else {
            // 重试用完，记录失败待网络恢复后补拉
            [self.groupFetchingLock performWriteLockBlock:^{
                [self.pendingRetryGroupIds addObjectsFromArray:groupIds];
            }];
            // 失败时返回空数组
            if (complete) {
                complete(@[]);
            }
        }
    }];
}

/// Fetches user info in batches and returns accumulated results once complete.
- (void)p_batchFetchUserInfos:(NSArray<NSString *> *)userIds complete:(nullable void (^)(NSArray<NCChatUIUserInfo *> *users))complete {
    if (userIds.count == 0) {
        if (complete) {
            complete(@[]);
        }
        return;
    }
    
    NSMutableArray *accumulatedResults = [NSMutableArray array];
    [self p_processBatchItems:userIds
                   startIndex:0
           accumulatedResults:accumulatedResults
               batchProcessor:^(NSArray *batchUserIds, NSUInteger batchStart, NSUInteger batchEnd, void(^continueNextBatch)(void)) {
        
        // First, fetch friend info for the batch.
        [self p_batchGetFriendsInfo:batchUserIds
                         retryCount:NC_KIT_FETCH_INFO_UINT_6
                           complete:^(NSArray<NCFriendInfo *> *friendInfos) {
            
            // Cache each friend, dispatch its update notification, and accumulate the final completion result.
            NSMutableSet *foundUserIds = [NSMutableSet set];
            for (NCFriendInfo *friendInfo in friendInfos) {
                NCChatUIUserInfo *managedUser = [NCChatUIUserInfo new];
                managedUser.friendInfo = friendInfo;
                [self.cache cacheUser:managedUser];
                [NCInfoUpdateCenter dispatchUserInfoUpdate:managedUser];
                
                if (friendInfo.userId) {
                    [foundUserIds addObject:friendInfo.userId];
                }
                [accumulatedResults addObject:managedUser];
            }
            
            // Remove request markers for users resolved as friends.
            [self p_removeFetchingUserIds:[foundUserIds allObjects]];
            
            // Collect users not resolved by the friend-info request.
            NSMutableArray *notFoundUserIds = [NSMutableArray array];
            for (NSString *userId in batchUserIds) {
                if (![foundUserIds containsObject:userId]) {
                    [notFoundUserIds addObject:userId];
                }
            }
            
            // Next, fetch profiles for users not resolved as friends.
            if (notFoundUserIds.count > 0) {
                [self p_batchGetUserProfiles:notFoundUserIds
                                  retryCount:NC_KIT_FETCH_INFO_UINT_6
                                    complete:^(NSArray<NCUserProfile *> *profiles) {
                    
                    // Cache profiles, dispatch notifications, and accumulate results.
                    for (NCUserProfile *profile in profiles) {
                        NCChatUIUserInfo *managedUser = [NCChatUIUserInfo new];
                        managedUser.profile = profile;
                        [self.cache cacheUser:managedUser];
                        [NCInfoUpdateCenter dispatchUserInfoUpdate:managedUser];
                        [accumulatedResults addObject:managedUser];
                    }
                    
                    // Clear markers for every profile fallback ID, whether or not a profile was returned.
                    [self p_removeFetchingUserIds:notFoundUserIds];
                    
                    // Continue with the next batch.
                    continueNextBatch();
                }];
            } else {
                // Every user in this batch was resolved as a friend; continue.
                continueNextBatch();
            }
        }];
    } complete:complete];
}

/// Fetches one friend-info batch with retries.
- (void)p_batchGetFriendsInfo:(NSArray<NSString *> *)userIds 
                   retryCount:(NSUInteger)retryCount 
                     complete:(void (^)(NSArray<NCFriendInfo *> *friendInfos))complete {
    [[NCEngine userModule] getFriendsInfoWithUserIds:userIds completion:^(NSArray<NCFriendInfo *> * _Nullable friendInfos, NCError * _Nullable error) {
        if (!error) {
            if (complete) {
                complete(friendInfos ?: @[]);
            }
            return;
        }
        // 启动早期网络/同步状态未就绪时继续重试，避免过早降级为 profile-only 缓存。
        if ([NCInfoManagement p_shouldRetryForErrorCode:error.code] && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_batchGetFriendsInfo:userIds retryCount:retryCount - 1 complete:complete];
            });
        } else {
            // Return an empty batch so the caller falls back to user profiles.
            if (complete) {
                complete(@[]);
            }
        }
    }];
}

/// Fetches one user-profile batch with retries.
- (void)p_batchGetUserProfiles:(NSArray<NSString *> *)userIds
                    retryCount:(NSUInteger)retryCount
                      complete:(void (^)(NSArray<NCUserProfile *> *profiles))complete {
    [[NCEngine userModule] getUserProfilesWithUserIds:userIds completion:^(NSArray<NCUserProfile *> * _Nullable userProfiles, NCError * _Nullable error) {
        if (!error) {
            if (complete) {
                complete(userProfiles ?: @[]);
            }
            return;
        }
        // 数据同步中、请求过频或网络不可用时重试
        if ([NCInfoManagement p_shouldRetryForErrorCode:error.code] && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_batchGetUserProfiles:userIds retryCount:retryCount - 1 complete:complete];
            });
        } else {
            // 重试用完，记录失败待网络恢复后补拉
            [self.userFetchingLock performWriteLockBlock:^{
                [self.pendingRetryUserIds addObjectsFromArray:userIds];
            }];
            // 失败时返回空数组
            if (complete) {
                complete(@[]);
            }
        }
    }];
}

#pragma mark -- private async

- (void)refreshUserInfo:(NCChatUIUserInfo *)userInfo complete:(void (^)(BOOL))complete {
    NCChatUIUserInfo *resolvedUserInfo = [self p_userInfoFromFlatUserInfo:userInfo];
    if ([userInfo.userId isEqualToString:[NCEngine getCurrentUserId]]) {
        NCUserProfile *profile = resolvedUserInfo.profile;
        if (!profile) {
            complete(NO);
            return;
        }
        [[NCEngine userModule] updateMyUserProfile:profile completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
            complete(error == nil);
        }];
    } else if (resolvedUserInfo.friendInfo){
        NCSetFriendInfoParams *params = [[NCSetFriendInfoParams alloc] initWithUserId:userInfo.userId];
        params.remark = resolvedUserInfo.friendInfo.remark;
        params.extProfile = resolvedUserInfo.friendInfo.extProfile;
        [[NCEngine userModule] setFriendInfoWithParams:params completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
            complete(error == nil);
        }];
    } else {
        complete(NO);
    }
}

- (void)p_getUserInfo:(NSString *)userId complete:(void (^)(NCChatUIUserInfo *))complete {
    if (userId == nil) {
        return complete(nil);
    }
    if ([[NCEngine getCurrentUserId] isEqualToString:userId]) {
        [self p_getMyProflieByRetry:NC_KIT_FETCH_INFO_UINT_6 complete:complete];
    } else {
        [self p_getFriendsInfoByRetry:userId retryCount:NC_KIT_FETCH_INFO_UINT_6 complete:^(NCChatUIUserInfo * _Nullable user) {
            if (user) {
                complete(user);
            } else {
                [self p_getUserProfileByRetry:userId retryCount:NC_KIT_FETCH_INFO_UINT_6 complete:complete];
            }
        }];
    }
}

- (void)refreshGroupMember:(NCChatUIUserInfo *)userInfo withGroupId:(NSString *)groupId complete:(void (^)(BOOL))complete {
    NCChatUIUserInfo *resolvedUserInfo = [self p_userInfoFromFlatUserInfo:userInfo];
    NCGroupMemberInfo *memberInfo = resolvedUserInfo.memberInfo;
    if (!memberInfo) {
        complete(NO);
        return;
    }
    NCSetGroupMemberInfoParams *params = [NCSetGroupMemberInfoParams new];
    params.userId = memberInfo.userId;
    params.nickname = memberInfo.nickname;
    params.extra = memberInfo.extra;
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:groupId];
    [channel setMemberInfoWithParams:params completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        complete(error == nil);
    }];
}

- (void)p_getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId complete:(void (^)( NCChatUIUserInfo *_Nullable user))complete {
    if (userId == nil || groupId == nil) {
        return complete(nil);
    }
    [self p_getGroupMemberByRetry:userId withGroupId:groupId retryCount:NC_KIT_FETCH_INFO_UINT_6 complete:complete];
}

- (void)p_getGroupInfo:(NSString *)groupId complete:(void (^)(NCChatUIGroup * _Nullable))complete {
    if (groupId == nil) {
        return complete(nil);
    }
    [self p_getGroupInfoByRetry:groupId retryCount:NC_KIT_FETCH_INFO_UINT_6 complete:complete];
}

- (void)p_getMyProflieByRetry:(int)retryCount complete:(void (^)( NCChatUIUserInfo *_Nullable user))complete {
    [[NCEngine userModule] getMyUserProfileWithCompletion:^(NCUserProfile * _Nullable userProfile, NCError * _Nullable error) {
        if (error) {
            if ([NCInfoManagement p_shouldRetryForErrorCode:error.code] && retryCount > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self p_getMyProflieByRetry:retryCount-1 complete:complete];
                });
            } else {
                complete(nil);
            }
            return;
        }
        if (!userProfile) {
            complete(nil);
            return;
        }
        NCChatUIUserInfo *managedUser = [NCChatUIUserInfo new];
        managedUser.profile = userProfile;
        complete(managedUser);
    }];
}

- (void)p_getFriendsInfoByRetry:(NSString *)userId retryCount:(int)retryCount complete:(void (^)( NCChatUIUserInfo *_Nullable user))complete {
    [[NCEngine userModule] getFriendsInfoWithUserIds:@[userId] completion:^(NSArray<NCFriendInfo *> * _Nullable friendInfos, NCError * _Nullable error) {
        if (!error && friendInfos.firstObject) {
            NCChatUIUserInfo *managedUser = [NCChatUIUserInfo new];
            managedUser.friendInfo = friendInfos.firstObject;
            complete(managedUser);
        } else {
            if (error && [NCInfoManagement p_shouldRetryForErrorCode:error.code] && retryCount > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self p_getFriendsInfoByRetry:userId retryCount:retryCount-1 complete:complete];
                });
            } else {
                complete(nil);
            }
        }
    }];
}

- (void)p_getUserProfileByRetry:(NSString *)userId retryCount:(int)retryCount complete:(void (^)( NCChatUIUserInfo *_Nullable user))complete {
    [[NCEngine userModule] getUserProfilesWithUserIds:@[userId] completion:^(NSArray<NCUserProfile *> * _Nullable userProfiles, NCError * _Nullable error) {
        if (error) {
            if ([NCInfoManagement p_shouldRetryForErrorCode:error.code] && retryCount > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self p_getUserProfileByRetry:userId retryCount:retryCount-1 complete:complete];
                });
            } else {
                complete(nil);
            }
            return;
        }
        if (userProfiles.firstObject) {
            NCChatUIUserInfo *managedUser = [NCChatUIUserInfo new];
            managedUser.profile = userProfiles.firstObject;
            complete(managedUser);
        } else {
            complete(nil);
        }
    }];
}


- (void)p_getGroupMemberByRetry:(NSString *)userId withGroupId:(NSString *)groupId retryCount:(int)retryCount complete:(void (^)( NCChatUIUserInfo *_Nullable user))complete {
    [self p_batchGetGroupMembers:@[userId] groupId:groupId retryCount:retryCount complete:^(NSArray<NCGroupMemberInfo *> *groupMembers) {
        if (groupMembers.firstObject) {
            NCChatUIUserInfo *managedUser = [NCChatUIUserInfo new];
            managedUser.memberInfo = groupMembers.firstObject;
            complete(managedUser);
        } else {
            complete(nil);
        }
    }];
}

- (void)p_getGroupInfoByRetry:(NSString *)groupId retryCount:(int)retryCount complete:(void (^)(NCChatUIGroup * _Nullable))complete {
    [NCGroupChannel getGroupsInfoWithGroupIds:@[groupId] completion:^(NSArray<NCGroupInfo *> * _Nullable groupInfos, NCError * _Nullable error) {
        if (error) {
            if ([NCInfoManagement p_shouldRetryForErrorCode:error.code] && retryCount > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self p_getGroupInfoByRetry:groupId retryCount:retryCount-1 complete:complete];
                });
            } else {
                complete(nil);
            }
            return;
        }
        if (groupInfos.firstObject) {
            NCChatUIGroup *managedGroup = [self p_chatUIGroupFromGroupInfo:groupInfos.firstObject];
            [self.cache cacheGroup:managedGroup];
            complete(managedGroup);
        } else {
            complete(nil);
        }
    }];
}

- (void)refreshGroupInfo:(NCChatUIGroup *)groupInfo complete:(void (^)(BOOL))complete {
    if (!groupInfo) {
        complete(NO);
        return;
    }
    NCChatUIGroup *resolvedGroupInfo = [NCChatUIGroup new];
    resolvedGroupInfo.groupId = groupInfo.groupId;
    resolvedGroupInfo.groupName = groupInfo.groupName;
    resolvedGroupInfo.avatarUrl = groupInfo.avatarUrl;
    resolvedGroupInfo.extra = groupInfo.extra;
    resolvedGroupInfo.notice = groupInfo.notice;
    resolvedGroupInfo.groupInfo = groupInfo.groupInfo;
    NCChatUIGroup *cachedGroupInfo = [self.cache getGroupCache:groupInfo.groupId];
    resolvedGroupInfo.groupInfo = resolvedGroupInfo.groupInfo ?: cachedGroupInfo.groupInfo;
    NCGroupInfo *group = resolvedGroupInfo.groupInfo;
    if (!group) {
        complete(NO);
        return;
    }
    NCUpdateGroupInfoParams *params = [self p_updateGroupInfoParamsFromGroupInfo:group];
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:group.groupId];
    [channel updateInfoWithParams:params completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        complete(error == nil);
    }];
}

- (NCChatUIUserInfo *)p_getMemberCache:(NCChatUIUserInfo *)member {
    if (!member) {
        return member;
    }
    NCChatUIUserInfo *tempUser = [self.cache getUserCache:member.userId];
    if (!tempUser) {
        return member;
    }
    NCChatUIUserInfo *managedMember = member;
    managedMember.profile = tempUser.profile ?: managedMember.profile;
    managedMember.friendInfo = tempUser.friendInfo ?: managedMember.friendInfo;
    // Use cached user info for group members except for the group-specific nickname.
    if (managedMember.memberInfo.nickname.length == 0) {
        managedMember.name = tempUser.name;
    }
    managedMember.avatarUrl = tempUser.avatarUrl;
    managedMember.extra = tempUser.extra;
    return managedMember;
}

- (void)p_cacheAndDispatchGroupMember:(NCChatUIUserInfo *)userInfo groupId:(NSString *)groupId {
    if (userInfo.userId.length == 0 || groupId.length == 0) {
        return;
    }
    NCChatUIUserInfo *resolvedUserInfo = [self p_resolvedGroupMember:userInfo groupId:groupId];
    [self.cache cacheGroupMember:resolvedUserInfo groupId:groupId];
    [NCInfoUpdateCenter dispatchGroupMemberInfoUpdate:[self p_getMemberCache:resolvedUserInfo] groupId:groupId];
}

- (void)p_cacheAndDispatchFriendRemarkForUserId:(NSString *)userId
                                         remark:(nullable NSString *)remark {
    if (userId.length == 0) {
        return;
    }
    NCChatUIUserInfo *optimisticUserInfo = [NCChatUIUserInfo new];
    optimisticUserInfo.userId = userId;
    optimisticUserInfo.alias = remark;
    NCChatUIUserInfo *resolvedUserInfo = [self p_userInfoFromFlatUserInfo:optimisticUserInfo];
    [self.cache cacheUser:resolvedUserInfo];
    [NCInfoUpdateCenter dispatchUserInfoUpdate:resolvedUserInfo];
}

- (void)p_refreshUserCacheAfterFriendInfoChanged:(NSString *)userId {
    if (userId.length == 0) {
        return;
    }
    [self getUserInfo:userId complete:^(NCChatUIUserInfo *user) {
        if (user) {
            [NCInfoUpdateCenter dispatchUserInfoUpdate:user];
        }
    }];
}

- (NCChatUIUserInfo *)p_resolvedGroupMember:(NCChatUIUserInfo *)userInfo groupId:(NSString *)groupId {
    if (!userInfo) {
        return nil;
    }
    NCChatUIUserInfo *cachedUserInfo = [self.cache getGroupMemberCache:userInfo.userId groupId:groupId];
    NCGroupMemberInfo *cachedMemberInfo = cachedUserInfo.memberInfo;
    NCGroupMemberInfo *incomingMemberInfo = userInfo.memberInfo;

    NCChatUIUserInfo *resolvedUserInfo = [NCChatUIUserInfo new];
    resolvedUserInfo.userId = userInfo.userId.length > 0 ? userInfo.userId : cachedUserInfo.userId;
    resolvedUserInfo.name = userInfo.name.length > 0 ? userInfo.name : cachedUserInfo.name;
    resolvedUserInfo.avatarUrl = userInfo.avatarUrl.length > 0 ? userInfo.avatarUrl : cachedUserInfo.avatarUrl;
    resolvedUserInfo.alias = userInfo.alias.length > 0 ? userInfo.alias : cachedUserInfo.alias;
    resolvedUserInfo.extra = userInfo.extra.length > 0 ? userInfo.extra : cachedUserInfo.extra;
    resolvedUserInfo.profile = userInfo.profile ?: cachedUserInfo.profile;
    resolvedUserInfo.friendInfo = userInfo.friendInfo ?: cachedUserInfo.friendInfo;

    if (incomingMemberInfo || cachedMemberInfo) {
        NCGroupMemberInfo *memberInfo = [NCGroupMemberInfo new];
        memberInfo.userId = incomingMemberInfo.userId.length > 0 ? incomingMemberInfo.userId : resolvedUserInfo.userId;
        memberInfo.name = incomingMemberInfo.name.length > 0 ? incomingMemberInfo.name : cachedMemberInfo.name;
        memberInfo.avatarUrl = incomingMemberInfo.avatarUrl.length > 0 ? incomingMemberInfo.avatarUrl : cachedMemberInfo.avatarUrl;
        memberInfo.nickname = incomingMemberInfo ? incomingMemberInfo.nickname : cachedMemberInfo.nickname;
        memberInfo.extra = incomingMemberInfo.extra.length > 0 ? incomingMemberInfo.extra : cachedMemberInfo.extra;
        memberInfo.joinedTime = incomingMemberInfo.joinedTime > 0 ? incomingMemberInfo.joinedTime : cachedMemberInfo.joinedTime;
        memberInfo.role = incomingMemberInfo ? incomingMemberInfo.role : cachedMemberInfo.role;
        memberInfo.isRobot = incomingMemberInfo.isRobot || cachedMemberInfo.isRobot;
        resolvedUserInfo.memberInfo = memberInfo;
    }
    return resolvedUserInfo;
}

- (NCChatUIUserInfo *)p_groupMember:(NSString *)userId
                            nickname:(nullable NSString *)nickname
                               extra:(nullable NSString *)extra {
    if (userId.length == 0) {
        return nil;
    }
    NCGroupMemberInfo *memberInfo = [NCGroupMemberInfo new];
    memberInfo.userId = userId;
    memberInfo.nickname = nickname ?: @"";
    memberInfo.extra = extra;
    NCChatUIUserInfo *userInfo = [NCChatUIUserInfo new];
    userInfo.memberInfo = memberInfo;
    return userInfo;
}

- (NCChatUIUserInfo *)p_userInfoFromFlatUserInfo:(NCChatUIUserInfo *)userInfo {
    if (!userInfo) {
        return nil;
    }
    NCChatUIUserInfo *resolvedUserInfo = [NCChatUIUserInfo new];
    resolvedUserInfo.userId = userInfo.userId;
    resolvedUserInfo.name = userInfo.name;
    resolvedUserInfo.avatarUrl = userInfo.avatarUrl;
    resolvedUserInfo.alias = userInfo.alias;
    resolvedUserInfo.extra = userInfo.extra;

    NCChatUIUserInfo *cachedUserInfo = [self.cache getUserCache:userInfo.userId];
    if (!cachedUserInfo) {
        return resolvedUserInfo;
    }

    resolvedUserInfo.profile = cachedUserInfo.profile;
    resolvedUserInfo.friendInfo = cachedUserInfo.friendInfo;
    resolvedUserInfo.memberInfo = cachedUserInfo.memberInfo;

    if ([userInfo.userId isEqualToString:[NCEngine getCurrentUserId]]) {
        NCUserProfile *profile = cachedUserInfo.profile ?: [NCUserProfile new];
        profile.userId = userInfo.userId;
        profile.name = userInfo.name;
        profile.avatarUrl = userInfo.avatarUrl;
        profile.extProfile = [self p_profileDictionaryFromExtra:userInfo.extra];
        resolvedUserInfo.profile = profile;
        return resolvedUserInfo;
    }

    if (cachedUserInfo.friendInfo) {
        NCFriendInfo *friendInfo = cachedUserInfo.friendInfo;
        friendInfo.userId = userInfo.userId;
        friendInfo.name = userInfo.name;
        friendInfo.avatarUrl = userInfo.avatarUrl;
        friendInfo.remark = userInfo.alias;
        friendInfo.extProfile = [self p_profileDictionaryFromExtra:userInfo.extra];
        resolvedUserInfo.friendInfo = friendInfo;
    }

    if (cachedUserInfo.memberInfo) {
        NCGroupMemberInfo *memberInfo = cachedUserInfo.memberInfo;
        memberInfo.userId = userInfo.userId;
        memberInfo.name = userInfo.name;
        memberInfo.avatarUrl = userInfo.avatarUrl;
        memberInfo.extra = userInfo.extra;
        if (memberInfo.nickname.length == 0) {
            memberInfo.nickname = userInfo.name;
        }
        resolvedUserInfo.memberInfo = memberInfo;
    }

    return resolvedUserInfo;
}

- (NSDictionary<NSString *, NSString *> *)p_profileDictionaryFromExtra:(NSString *)extra {
    if (extra.length == 0) {
        return nil;
    }
    NSData *jsonData = [extra dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        return nil;
    }
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return (NSDictionary<NSString *, NSString *> *)jsonObject;
}

- (NCUpdateGroupInfoParams *)p_updateGroupInfoParamsFromGroupInfo:(NCGroupInfo *)groupInfo {
    if (!groupInfo) {
        return nil;
    }
    NCUpdateGroupInfoParams *params = [NCUpdateGroupInfoParams new];
    params.groupName = groupInfo.groupName;
    params.avatarUrl = groupInfo.avatarUrl;
    params.introduction = groupInfo.introduction;
    params.notice = groupInfo.notice;
    params.extProfile = groupInfo.extProfile;
    params.joinPermissionValue = @((NSInteger)groupInfo.joinPermission);
    params.removeMemberPermissionValue = @((NSInteger)groupInfo.removeMemberPermission);
    params.invitePermissionValue = @((NSInteger)groupInfo.invitePermission);
    params.inviteHandlePermissionValue = @((NSInteger)groupInfo.inviteHandlePermission);
    params.groupInfoEditPermissionValue = @((NSInteger)groupInfo.groupInfoEditPermission);
    params.memberInfoEditPermissionValue = @((NSInteger)groupInfo.memberInfoEditPermission);
    return params;
}

- (NCChatUIGroup *)p_chatUIGroupFromGroupInfo:(NCGroupInfo *)groupInfo {
    if (!groupInfo) {
        return nil;
    }
    NCChatUIGroup *group = [NCChatUIGroup new];
    group.groupId = groupInfo.groupId;
    group.groupName = groupInfo.groupName;
    group.avatarUrl = groupInfo.avatarUrl;
    group.notice = groupInfo.notice;
    return group;
}

- (NCChatUIGroup *)p_chatUIGroupByMergingEventGroup:(NCChatUIGroup *)groupInfo
                                  changedProperties:(NSArray<NSString *> *)changedProperties {
    if (!groupInfo) {
        return nil;
    }
    NCChatUIGroup *cachedGroupInfo = [self.cache getGroupCache:groupInfo.groupId];
    if (!cachedGroupInfo) {
        NCChatUIGroup *displayGroup = [NCChatUIGroup new];
        displayGroup.groupId = groupInfo.groupId;
        displayGroup.groupName = groupInfo.groupName;
        displayGroup.avatarUrl = groupInfo.avatarUrl;
        displayGroup.extra = groupInfo.extra;
        displayGroup.notice = groupInfo.notice;
        return displayGroup;
    }
    BOOL groupNameChanged = [changedProperties containsObject:@"groupName"];
    BOOL avatarUrlChanged = [changedProperties containsObject:@"avatarUrl"];
    BOOL noticeChanged = [changedProperties containsObject:@"notice"];
    NCChatUIGroup *resolvedGroupInfo = [NCChatUIGroup new];
    resolvedGroupInfo.groupId = groupInfo.groupId.length > 0 ? groupInfo.groupId : cachedGroupInfo.groupId;
    resolvedGroupInfo.groupName = groupNameChanged ? groupInfo.groupName : (groupInfo.groupName.length > 0 ? groupInfo.groupName : cachedGroupInfo.groupName);
    resolvedGroupInfo.avatarUrl = avatarUrlChanged ? groupInfo.avatarUrl : (groupInfo.avatarUrl.length > 0 ? groupInfo.avatarUrl : cachedGroupInfo.avatarUrl);
    resolvedGroupInfo.extra = groupInfo.extra.length > 0 ? groupInfo.extra : cachedGroupInfo.extra;
    resolvedGroupInfo.notice = noticeChanged ? groupInfo.notice : (groupInfo.notice.length > 0 ? groupInfo.notice : cachedGroupInfo.notice);
    return resolvedGroupInfo;
}

#pragma mark -- NCGroupChannelHandler

/// Handles a group profile change event.
/// - Parameter operatorInfo: Information about the operator.
/// - Parameter groupInfo: Group data; only properties listed in updateKeys are valid.
/// - Parameter updateKeys: Changed group properties.
/// - Parameter operationTime: Operation timestamp.
- (void)onGroupInfoChanged:(NCGroupInfoChangedEvent *)event {
    if (event.groupInfo.groupId.length == 0) {
        return;
    }
    NCChatUIGroup *group = [self p_chatUIGroupFromGroupInfo:event.groupInfo];
    NCChatUIGroup *resolvedGroup = [self p_chatUIGroupByMergingEventGroup:group
                                                        changedProperties:event.changedProperties];
    [self.cache cacheGroup:resolvedGroup];
    [NCInfoUpdateCenter dispatchGroupInfoUpdate:resolvedGroup];
    [self p_getGroupInfo:event.groupInfo.groupId complete:^(NCChatUIGroup * _Nullable groupInfo) {
        if (groupInfo) {
            [NCInfoUpdateCenter dispatchGroupInfoUpdate:groupInfo];
        }
    }];
}

/// Handles a group-member profile change event.
/// - Parameter groupId: Group ID.
/// - Parameter operatorInfo: Group-member information for the operator.
/// - Parameter memberInfo: Updated group-member information.
/// - Parameter operationTime: Operation timestamp.
- (void)onGroupMemberInfoChanged:(NCGroupMemberInfoChangedEvent *)event {
    NCChatUIUserInfo *managedUser = [NCChatUIUserInfo new];
    managedUser.memberInfo = event.memberInfo;
    [self p_cacheAndDispatchGroupMember:managedUser groupId:event.groupId];
}

- (void)onGroupOperation:(NCGroupOperationEvent *)event {
    if (event.groupId.length == 0 || !NCGroupOperationInvalidatesCurrentUser(event)) {
        return;
    }
    NSString *groupId = event.groupId;
    [self.cache removeGroupCache:groupId];
    [self.cache removeGroupMemberCacheForGroupId:groupId];
    [[NCChannelInfoCache sharedCache] clearConversationInfo:NCChannelTypeGroup channelId:groupId];
    [self p_removeFetchingGroupIds:@[groupId]];
    [self p_removeFetchingGroupMemberKeysInGroup:groupId];
    [self.groupFetchingLock performWriteLockBlock:^{
        [self.pendingRetryGroupIds removeObject:groupId];
    }];
}

#pragma mark -- NCUserHandler

- (void)onFriendCleared:(NCFriendClearedEvent *)event {
    [self.cache removeAllUserCache];
}

- (void)onFriendRemove:(NCFriendRemoveEvent *)event {
    for (NSString *userId in event.userIds) {
        [self.cache removeUserCache:userId];
    }
}

- (void)onFriendInfoChangedSync:(NCFriendInfoChangedSyncEvent *)event {
    [self getUserInfo:event.userId complete:nil];
}

#pragma mark -- subscription
- (void)onSubscriptionChanged:(NCSubscriptionChangedEvent *)event {
    for (NCSubscriptionStatusInfo *subscribeEvent in event.events) {
        if (subscribeEvent.subscribeType == NCSubscribeTypeUserProfile ||
            subscribeEvent.subscribeType == NCSubscribeTypeFriendUserProfile) {
            [self.cache removeUserCache:subscribeEvent.userId];
        }
    }
}

#pragma mark -- getter

- (NCInfoManagementCache *)cache {
    if (!_cache) {
        _cache = [NCInfoManagementCache new];
    }
    return _cache;
}

- (NSMutableSet<NSString *> *)fetchingUserIds {
    if (!_fetchingUserIds) {
        _fetchingUserIds = [NSMutableSet set];
    }
    return _fetchingUserIds;
}

- (NSMutableSet<NSString *> *)fetchingGroupMemberKeys {
    if (!_fetchingGroupMemberKeys) {
        _fetchingGroupMemberKeys = [NSMutableSet set];
    }
    return _fetchingGroupMemberKeys;
}

- (NSMutableSet<NSString *> *)fetchingGroupIds {
    if (!_fetchingGroupIds) {
        _fetchingGroupIds = [NSMutableSet set];
    }
    return _fetchingGroupIds;
}

- (NSMutableSet<NSString *> *)pendingRetryUserIds {
    if (!_pendingRetryUserIds) {
        _pendingRetryUserIds = [NSMutableSet set];
    }
    return _pendingRetryUserIds;
}

- (NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *)pendingRetryGroupMembers {
    if (!_pendingRetryGroupMembers) {
        _pendingRetryGroupMembers = [NSMutableDictionary dictionary];
    }
    return _pendingRetryGroupMembers;
}

- (NSMutableSet<NSString *> *)pendingRetryGroupIds {
    if (!_pendingRetryGroupIds) {
        _pendingRetryGroupIds = [NSMutableSet set];
    }
    return _pendingRetryGroupIds;
}

#pragma mark -- NCChatUIConnectionStatusDelegate
- (void)onConnectionStatusChanged:(NCConnectionStatusChangedEvent *)event {
    NSString *currentUserId = [NCEngine getCurrentUserId];
    if (event.status != NCConnectionStatusConnected || currentUserId.length == 0) {
        return;
    }
    if (self.userId.length == 0) {
        self.userId = currentUserId;
        return;
    }
    if (![self.userId isEqualToString:currentUserId]) {
        self.userId = currentUserId;
        [self.cache removeAllUserCache];
        [self.cache removeAllGroupCache];
        [self.cache removeAllGroupMemberCache];
    }

    // 网络恢复后，重拉失败的资料
    if (event.status == NCConnectionStatusConnected) {
        [self p_retryFailedInfoFetches];
    }
}

/// 网络恢复后，补拉之前因网络失败而未获取到的资料
- (void)p_retryFailedInfoFetches {
    // 1. 取出并清空失败的用户ID
    __block NSArray<NSString *> *userIds = nil;
    [self.userFetchingLock performWriteLockBlock:^{
        userIds = [self.pendingRetryUserIds allObjects];
        [self.pendingRetryUserIds removeAllObjects];
    }];

    // 2. 取出并清空失败的群成员（groupId → userId 集合）
    __block NSDictionary<NSString *, NSMutableSet<NSString *> *> *groupMembers = nil;
    [self.memberFetchingLock performWriteLockBlock:^{
        groupMembers = [self.pendingRetryGroupMembers copy];
        [self.pendingRetryGroupMembers removeAllObjects];
    }];

    // 3. 取出并清空失败的群组ID
    __block NSArray<NSString *> *groupIds = nil;
    [self.groupFetchingLock performWriteLockBlock:^{
        groupIds = [self.pendingRetryGroupIds allObjects];
        [self.pendingRetryGroupIds removeAllObjects];
    }];

    // 4. 补拉用户资料
    if (userIds.count > 0) {
        [self fetchUserInfos:userIds];
    }

    // 5. 补拉群资料
    if (groupIds.count > 0) {
        [self fetchGroupInfos:groupIds];
    }

    // 6. 补拉群成员：逐组补拉
    [groupMembers enumerateKeysAndObjectsUsingBlock:^(NSString *groupId, NSMutableSet<NSString *> *users, BOOL *stop) {
        if (groupId.length > 0 && users.count > 0) {
            [self fetchGroupMembers:users.allObjects withGroupId:groupId];
        }
    }];
}

@end
