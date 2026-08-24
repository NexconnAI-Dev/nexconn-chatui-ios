//
//  NCGroupManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupManager.h"
#import "NCChatUIErrorCode.h"
#import "NSMutableArray+NCOperation.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <NexconnChatUI/NCChatUILog.h>
#import <objc/runtime.h>

@implementation NCUIPagingQueryOption
@end

@implementation NCUIPagingQueryResult
@end

@interface NCGroupQueryState : NSObject

@property (nonatomic, strong, nullable) id query;
@property (nonatomic, assign) NSInteger loadedCount;
@property (nonatomic, assign) BOOL hasMoreInQuery;
@property (nonatomic, strong) NSMutableArray *bufferedItems;

@end

@implementation NCGroupQueryState

- (instancetype)init {
    self = [super init];
    if (self) {
        _hasMoreInQuery = YES;
        _bufferedItems = [NSMutableArray array];
    }
    return self;
}

@end

static NSString *const NCGroupManagerHasMorePageToken = @"nc_group_query_has_more";
static const void *NCGroupManagerQueryStatesKey = &NCGroupManagerQueryStatesKey;

@implementation NCGroupManager

+ (NSMutableDictionary<NSString *, NCGroupQueryState *> *)
    queryStatesForOption:(NCUIPagingQueryOption *)option
          createIfNeeded:(BOOL)createIfNeeded {
    NSMutableDictionary<NSString *, NCGroupQueryState *> *states =
        objc_getAssociatedObject(option, NCGroupManagerQueryStatesKey);
    if (!states && createIfNeeded) {
        states = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(option, NCGroupManagerQueryStatesKey, states,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return states;
}

+ (void)resetQueryStatesIfNeededForOption:(NCUIPagingQueryOption *)option {
    if (option.pageToken.length != 0) {
        return;
    }
    NSMutableDictionary<NSString *, NCGroupQueryState *> *states = [self queryStatesForOption:option
                                                                               createIfNeeded:NO];
    [states removeAllObjects];
}

+ (NCGroupQueryState *)queryStateForOption:(NCUIPagingQueryOption *)option key:(NSString *)key {
    NSMutableDictionary<NSString *, NCGroupQueryState *> *states = [self queryStatesForOption:option
                                                                               createIfNeeded:YES];
    NCGroupQueryState *state = states[key];
    if (!state) {
        state = [NCGroupQueryState new];
        states[key] = state;
    }
    return state;
}

+ (NSString *)memberStateKeyForGroupId:(NSString *)groupId role:(NCGroupMemberRole)role {
    return [NSString stringWithFormat:@"members:%@:%ld", groupId ?: @"", (long)role];
}

+ (NSString *)joinedGroupsStateKeyForRole:(NCGroupMemberRole)role {
    return [NSString stringWithFormat:@"joined:%ld", (long)role];
}

+ (NSString *)searchJoinedGroupsStateKeyForKeyword:(NSString *)keyword {
    return [NSString stringWithFormat:@"searchJoined:%@", keyword ?: @""];
}

+ (NSUInteger)pageSizeForOption:(NCUIPagingQueryOption *)option {
    return option.count > 0 ? (NSUInteger)option.count : 20;
}

+ (NSInteger)totalCountForQuery:(id)query {
    if (!query || ![query respondsToSelector:@selector(totalCount)]) {
        return -1;
    }
    NSNumber *value = [query valueForKey:@"totalCount"];
    return value ? value.integerValue : -1;
}

+ (BOOL)query:(id)query
    hasMoreAfterLoadedCount:(NSInteger)loadedCount
           currentPageCount:(NSInteger)currentPageCount
                   pageSize:(NSUInteger)pageSize {
    NSInteger totalCount = [self totalCountForQuery:query];
    if (totalCount >= 0) {
        return loadedCount < totalCount;
    }
    if (pageSize == 0) {
        return currentPageCount > 0;
    }
    return currentPageCount >= (NSInteger)pageSize;
}

+ (BOOL)stateHasRemainingItems:(NCGroupQueryState *)state {
    if (!state) {
        return NO;
    }
    if (state.bufferedItems.count > 0) {
        return YES;
    }
    if (!state.query) {
        return YES;
    }
    return state.hasMoreInQuery;
}

+ (NCUIPagingQueryResult *)pagingResultWithData:(NSArray *)data hasMore:(BOOL)hasMore {
    NCUIPagingQueryResult *result = [NCUIPagingQueryResult new];
    result.data = data ?: @[];
    result.pageToken = hasMore ? NCGroupManagerHasMorePageToken : nil;
    return result;
}

+ (void)appendMembersFromState:(NCGroupQueryState *)state
                       groupId:(NSString *)groupId
                          role:(NCGroupMemberRole)role
                   neededCount:(NSUInteger)neededCount
                      pageSize:(NSUInteger)pageSize
                   isAscending:(BOOL)isAscending
                   accumulator:(NSMutableArray<NCGroupMemberInfo *> *)accumulator
                    completion:(void (^)(BOOL hasMore, NCError *_Nullable error))completion {
    if (neededCount == 0) {
        completion([self stateHasRemainingItems:state], nil);
        return;
    }
    if (state.bufferedItems.count > 0) {
        NSUInteger consumeCount = MIN(neededCount, (NSUInteger)state.bufferedItems.count);
        NSArray<NCGroupMemberInfo *> *items =
            [state.bufferedItems subarrayWithRange:NSMakeRange(0, consumeCount)];
        [accumulator addObjectsFromArray:items];
        [state.bufferedItems removeObjectsInRange:NSMakeRange(0, consumeCount)];
        if (consumeCount == neededCount || state.bufferedItems.count > 0) {
            completion([self stateHasRemainingItems:state], nil);
            return;
        }
    }
    if (state.query && !state.hasMoreInQuery) {
        completion(NO, nil);
        return;
    }
    if (!state.query) {
        NCGroupMembersByRoleQueryParams *params = [NCGroupMembersByRoleQueryParams new];
        params.groupId = groupId ?: @"";
        params.role = role;
        params.pageSize = pageSize;
        params.isAscending = isAscending;
        state.query = [NCGroupChannel createGroupMembersByRoleQueryWithParams:params];
    }
    [(NCGroupMembersByRoleQuery *)state.query
        loadNextPageWithCompletion:^(NCGroupMembersByRolePageResult *_Nullable page,
                                     NCError *_Nullable error) {
          if (error) {
              completion(NO, error);
              return;
          }
          NSArray<NCGroupMemberInfo *> *members = page.data ?: @[];
          [state.bufferedItems addObjectsFromArray:members];
          state.loadedCount += members.count;
          state.hasMoreInQuery = [self query:state.query
                     hasMoreAfterLoadedCount:state.loadedCount
                            currentPageCount:members.count
                                    pageSize:pageSize];
          [self appendMembersFromState:state
                               groupId:groupId
                                  role:role
                           neededCount:neededCount
                              pageSize:pageSize
                           isAscending:isAscending
                           accumulator:accumulator
                            completion:completion];
        }];
}

+ (void)getGroupMemberInfos:(NSString *)groupId
                     option:(NCUIPagingQueryOption *)option
                       role:(NCGroupMemberRole)role
                   complete:
                       (void (^)(NCUIPagingQueryResult<NCGroupMemberInfo *> *_Nullable))complete {
    [self getGroupMemberInfos:3 groupId:groupId option:option role:role complete:complete];
}

+ (void)getGroupMemberInfos:(NSInteger)count
                    groupId:(NSString *)groupId
                     option:(NCUIPagingQueryOption *)option
                       role:(NCGroupMemberRole)role
                   complete:
                       (void (^)(NCUIPagingQueryResult<NCGroupMemberInfo *> *_Nullable))complete {
    // Try at most three times.
    if (count <= 0) {
        return complete(nil);
    }
    [self resetQueryStatesIfNeededForOption:option];
    NSUInteger pageSize = [self pageSizeForOption:option];
    if (role == NCGroupMemberRoleUndef) {
        NSMutableArray<NCGroupMemberInfo *> *members = [NSMutableArray array];
        NSArray<NSNumber *> *roles = @[
            @(NCGroupMemberRoleOwner),
            @(NCGroupMemberRoleAdmin),
            @(NCGroupMemberRoleNormal),
        ];
        __block BOOL hasMore = NO;
        __block void (^loadRoleAtIndex)(NSInteger);
        loadRoleAtIndex = ^(NSInteger index) {
          if (members.count >= pageSize || index >= roles.count) {
              for (NSInteger remainIndex = index; remainIndex < roles.count; remainIndex++) {
                  NCGroupMemberRole remainRole = (NCGroupMemberRole)roles[remainIndex].integerValue;
                  NCGroupQueryState *remainState = [self
                      queryStateForOption:option
                                      key:[self memberStateKeyForGroupId:groupId role:remainRole]];
                  hasMore = hasMore || [self stateHasRemainingItems:remainState];
              }
              complete([self pagingResultWithData:members.copy hasMore:hasMore]);
              return;
          }
          NCGroupMemberRole currentRole = (NCGroupMemberRole)roles[index].integerValue;
          NCGroupQueryState *state =
              [self queryStateForOption:option
                                    key:[self memberStateKeyForGroupId:groupId role:currentRole]];
          NSUInteger neededCount = pageSize > members.count ? pageSize - members.count : 0;
          [self
              appendMembersFromState:state
                             groupId:groupId
                                role:currentRole
                         neededCount:neededCount
                            pageSize:pageSize
                         isAscending:option.order
                         accumulator:members
                          completion:^(BOOL stateHasMore, NCError *_Nullable error) {
                            if (error) {
                                NCLogE(@"Failed to fetch group members, error: %@", @(error.code));
                                if (error.code == NCChatUIErrorCodeNetDataIsSynchronizing) {
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                                                 (int64_t)(1.0 * NSEC_PER_SEC)),
                                                   dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                                                   ^{
                                                     [self getGroupMemberInfos:count - 1
                                                                       groupId:groupId
                                                                        option:option
                                                                          role:role
                                                                      complete:complete];
                                                   });
                                } else {
                                    complete(nil);
                                }
                                return;
                            }
                            hasMore = hasMore || stateHasMore;
                            loadRoleAtIndex(index + 1);
                          }];
        };
        loadRoleAtIndex(0);
    } else {
        NCGroupQueryState *state =
            [self queryStateForOption:option key:[self memberStateKeyForGroupId:groupId role:role]];
        NSMutableArray<NCGroupMemberInfo *> *members = [NSMutableArray array];
        [self appendMembersFromState:state
                             groupId:groupId
                                role:role
                         neededCount:pageSize
                            pageSize:pageSize
                         isAscending:option.order
                         accumulator:members
                          completion:^(BOOL hasMore, NCError *_Nullable error) {
                            if (error) {
                                NCLogE(@"Failed to fetch group members, error: %@", @(error.code));
                                if (error.code == NCChatUIErrorCodeNetDataIsSynchronizing) {
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                                                 (int64_t)(1.0 * NSEC_PER_SEC)),
                                                   dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                                                   ^{
                                                     [self getGroupMemberInfos:count - 1
                                                                       groupId:groupId
                                                                        option:option
                                                                          role:role
                                                                      complete:complete];
                                                   });
                                } else {
                                    complete(nil);
                                }
                                return;
                            }
                            complete([self pagingResultWithData:members.copy hasMore:hasMore]);
                          }];
    }
}

+ (void)getGroupMemberInfos:(NSString *)groupId
                    userIds:(NSArray<NSString *> *)userIds
                   complete:(void (^)(NSArray<NCGroupMemberInfo *> *_Nullable))complete {
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:groupId ?: @""];
    if (!channel) {
        complete(nil);
        return;
    }
    [channel getMembersWithUserIds:userIds
                        completion:^(NSArray<NCGroupMemberInfo *> *_Nullable members,
                                     NCError *_Nullable error) {
                          if (error) {
                              complete(nil);
                              return;
                          }
                          complete(members);
                        }];
}

+ (void)getJoinedGroupInfosByRole:(NCGroupMemberRole)role
                           option:(NCUIPagingQueryOption *)option
                         complete:
                             (void (^)(NCUIPagingQueryResult<NCGroupInfo *> *_Nullable))complete {
    [self resetQueryStatesIfNeededForOption:option];
    NSString *stateKey = [self joinedGroupsStateKeyForRole:role];
    NCGroupQueryState *state = [self queryStateForOption:option key:stateKey];
    if (!state.query) {
        NCJoinedGroupsByRoleQueryParams *params = [NCJoinedGroupsByRoleQueryParams new];
        params.role = role;
        params.pageSize = [self pageSizeForOption:option];
        params.isAscending = option.order;
        state.query = [NCGroupChannel createJoinedGroupsByRoleQueryWithParams:params];
    }
    [(NCJoinedGroupsByRoleQuery *)state.query
        loadNextPageWithCompletion:^(NCJoinedGroupsByRolePageResult *_Nullable page,
                                     NCError *_Nullable error) {
          if (error) {
              complete(nil);
              return;
          }
          NSArray<NCGroupInfo *> *groupInfos = page.data ?: @[];
          state.loadedCount += groupInfos.count;
          state.hasMoreInQuery = [self query:state.query
                     hasMoreAfterLoadedCount:state.loadedCount
                            currentPageCount:groupInfos.count
                                    pageSize:[self pageSizeForOption:option]];
          complete([self pagingResultWithData:groupInfos hasMore:state.hasMoreInQuery]);
        }];
}

+ (void)searchJoinedGroupInfos:(NSString *)keyword
                        option:(NCUIPagingQueryOption *)option
                      complete:(void (^)(NCUIPagingQueryResult<NCGroupInfo *> *_Nullable))complete {
    [self resetQueryStatesIfNeededForOption:option];
    NSString *stateKey = [self searchJoinedGroupsStateKeyForKeyword:keyword];
    NCGroupQueryState *state = [self queryStateForOption:option key:stateKey];
    if (!state.query) {
        NCSearchJoinedGroupsQueryParams *params = [NCSearchJoinedGroupsQueryParams new];
        params.groupName = keyword ?: @"";
        params.pageSize = [self pageSizeForOption:option];
        params.isAscending = option.order;
        state.query = [NCGroupChannel createSearchJoinedGroupsQueryWithParams:params];
    }
    [(NCSearchJoinedGroupsQuery *)state.query
        loadNextPageWithCompletion:^(NSArray<NCGroupInfo *> *_Nullable groups,
                                     NCError *_Nullable error) {
          if (error) {
              complete(nil);
              return;
          }
          NSArray<NCGroupInfo *> *groupInfos = groups ?: @[];
          state.loadedCount += groupInfos.count;
          state.hasMoreInQuery = [self query:state.query
                     hasMoreAfterLoadedCount:state.loadedCount
                            currentPageCount:groupInfos.count
                                    pageSize:[self pageSizeForOption:option]];
          complete([self pagingResultWithData:groupInfos hasMore:state.hasMoreInQuery]);
        }];
}

+ (void)fetchFriendInfosWithUserIds:(NSArray<NSString *> *)userIds
                           complete:(void (^)(NSArray<NCFriendInfo *> *_Nullable))complete {
    if (userIds.count == 0) {
        return complete(nil);
    }
    [[NCEngine userModule]
        getFriendsInfoWithUserIds:userIds
                       completion:^(NSArray<NCFriendInfo *> *_Nullable friendInfos,
                                    NCError *_Nullable error) {
                         if (error) {
                             complete(nil);
                             return;
                         }
                         complete(friendInfos);
                       }];
}

+ (void)fetchFriendInfos:(NSArray<NCGroupMemberInfo *> *)members
                complete:(void (^)(NSArray<NCFriendInfo *> *_Nullable))complete {
    NSMutableArray *userIdList = [NSMutableArray array];
    for (NCGroupMemberInfo *member in members) {
        [userIdList nc_addObject:member.userId];
    }
    [self fetchFriendInfosWithUserIds:userIdList.copy complete:complete];
}

+ (nullable NCFriendInfo *)friendWithUserId:(NSString *)userId
                              inFriendInfos:(NSArray<NCFriendInfo *> *)friendInfos {
    for (NCFriendInfo *info in friendInfos) {
        if ([info.userId isEqualToString:userId]) {
            return info;
        }
    }
    return nil;
}
@end
