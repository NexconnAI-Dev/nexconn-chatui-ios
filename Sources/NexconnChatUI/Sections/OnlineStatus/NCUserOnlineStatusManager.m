//
//  NCUserOnlineStatusManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUserOnlineStatusManager.h"
#import <NexconnChatUI/NCChatUIErrorCode.h>
#import <NexconnChatUI/NCChatUILog.h>
#import "NCChatUI.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

#pragma mark - Internal Types

/**
 * Internal result object for a subscription-limit recovery plan.
 */
@interface NCSubscriptionPlan : NSObject

/// User IDs retained without an unsubscribe or subscribe operation.
@property (nonatomic, copy) NSArray<NSString *> *keepUserIds;

/// User IDs to unsubscribe.
@property (nonatomic, copy) NSArray<NSString *> *unsubscribeUserIds;

/// User IDs to subscribe, including new and resubscription candidates.
@property (nonatomic, copy) NSArray<NSString *> *subscribeUserIds;

@end

@implementation NCSubscriptionPlan
@end

/// Default subscription lifetime: seven days, in seconds.
static const NSInteger kNCOnlineStatusDefaultSubscribeExpiry = 7 * 24 * 60 * 60;

/// Raw remaining-time threshold used to select resubscription candidates: one day in seconds.
static const NSInteger kNCOnlineStatusSubscribeExpiryThreshold = 1 * 24 * 60 * 60;

/// Default maximum subscription count.
static const NSInteger kNCOnlineStatusMaxSubscribeCount = 1000;

/// Maximum friend-query batch size.
static const NSInteger kNCOnlineStatusFriendQueryBatchSize = 100;

/// Maximum subscription batch size.
static const NSInteger kNCOnlineStatusSubscribeBatchSize = 20;

/// Batch size used by limit recovery to subscribe one user at a time.
static const NSInteger kNCOnlineStatusSubscribeMinBatchSize = 1;

/// Default batch retry delay: 500 milliseconds, stored in nanoseconds for dispatch_after.
static const int64_t kNCOnlineStatusBatchRetryDelay = (500 * NSEC_PER_MSEC);

/// Queue-specific key used to detect cacheQueue reentry and avoid deadlock.
static const void *kNCOnlineStatusCacheQueueKey = &kNCOnlineStatusCacheQueueKey;
/// NCEngine handler identifier.
static NSString * const kNCOnlineStatusUserHandlerIdentifier = @"NCUserOnlineStatusManager";

typedef void (^NCBatchRetryBlock)(NSArray * _Nullable retryItems);
typedef void (^NCBatchFailBlock)(NCChatUIErrorCode status);
typedef NSArray * _Nonnull (^NCBatchPendingSnapshotBlock)(void);

/// Signals completion of the current batch.
typedef void (^NCBatchCompletion)(void);

/// - Parameters:
///   - batch: Items in the current batch.
///   - context: Caller-provided context.
///   - pendingSnapshot: Returns the items remaining from the current batch position.
///   - batchCompletion: Advances to the next batch after the current batch finishes.
///   - retry: Retries the current batch when retryItems is nil, or retries only the supplied items.
///   - fail: Terminates processing with an error status.
typedef void (^NCBatchExecutorBlock)(NSArray *batch,
                                     id context,
                                     NCBatchPendingSnapshotBlock pendingSnapshot,
                                     NCBatchCompletion batchCompletion,
                                     NCBatchRetryBlock retry,
                                     NCBatchFailBlock fail);

@interface NCUserOnlineStatusManager ()<NCUserHandler, NCConnectionStatusHandler>

/// Serial queue protecting manager state.
@property (nonatomic, strong) dispatch_queue_t cacheQueue;

/// Online status cache with automatic memory-pressure eviction.
/// Always use objectForKey: to determine whether an entry is still present.
@property (nonatomic, strong) NSCache<NSString *, NCSubscribeUserOnlineStatus *> *statusCache;

/// User IDs with an online-status request in flight.
@property (nonatomic, strong) NSMutableSet<NSString *> *fetchingUserIds;

/// Unordered set of subscribed user IDs.
@property (nonatomic, strong) NSMutableSet<NSString *> *subscribedUserIds;

/// Cache of user IDs positively identified as friends.
@property (nonatomic, strong) NSMutableSet<NSString *> *friendUserIds;

/// Whether the friend-online-status subscription sync callback has been received.
@property (nonatomic, assign) BOOL friendOnlineStatusSyncCompleted;

/// User IDs waiting to be classified after friend-online-status subscription sync.
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *pendingFriendProfileUserIds;

/// Friend user IDs waiting for an online-status fetch after subscription sync.
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *pendingFriendOnlineStatusUserIds;

@end

@implementation NCUserOnlineStatusManager

+ (instancetype)sharedManager {
    static NCUserOnlineStatusManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NCUserOnlineStatusManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize the status cache.
        _statusCache = [[NSCache alloc] init];
        _statusCache.countLimit = 5000; // Cache at most 5,000 user statuses.
        _statusCache.name = @"nexconn.chat.onlinestatus.cache";
        
        // Initialize the in-flight request set.
        _fetchingUserIds = [NSMutableSet set];
        
        // Initialize the unordered subscribed-user set.
        _subscribedUserIds = [NSMutableSet set];
        
        // Initialize the confirmed-friend cache.
        _friendUserIds = [NSMutableSet set];
        
        // Initialize ordered pending-user collections.
        _pendingFriendProfileUserIds = [NSMutableOrderedSet orderedSet];
        _pendingFriendOnlineStatusUserIds = [NSMutableOrderedSet orderedSet];
        
        // Create the serial state queue.
        _cacheQueue = dispatch_queue_create("nexconn.chat.onlinestatus.cache", DISPATCH_QUEUE_SERIAL);
        // Mark the queue so nested calls can detect their execution context.
        dispatch_queue_set_specific(_cacheQueue, kNCOnlineStatusCacheQueueKey, (void *)kNCOnlineStatusCacheQueueKey, NULL);
        
        // Register for NC user events.
        [NCEngine addUserHandlerWithIdentifier:kNCOnlineStatusUserHandlerIdentifier handler:self];
        
        // Register for connection status events.
        [NCEngine addConnectionStatusHandlerWithIdentifier:kNCOnlineStatusUserHandlerIdentifier handler:self];
        
        // Friend relationship events arrive through the user handler.

    }
    return self;
}

- (void)dealloc {
    // Remove event handlers.
    [NCEngine removeUserHandlerForIdentifier:kNCOnlineStatusUserHandlerIdentifier];
    [NCEngine removeConnectionStatusHandlerForIdentifier:kNCOnlineStatusUserHandlerIdentifier];
}

#pragma mark - Public Methods

- (void)fetchOnlineStatus:(NSArray<NSString *> *)userIds {
    [self fetchOnlineStatusForUsers:userIds processSubscribeLimit:YES];
}

- (void)fetchOnlineStatus:(NSString *)userId processSubscribeLimit:(BOOL)processSubscribeLimit {
    if (!userId || userId.length == 0) {
        NCLogD(@"Fetch online status, user id is invalid");
        return;
    }
    [self fetchOnlineStatusForUsers:@[userId] processSubscribeLimit:processSubscribeLimit];
}

- (void)fetchFriendOnlineStatus:(NSArray<NSString *> *)userIds {
    if (userIds.count == 0) {
        NCLogD(@"Fetch friend online status, no users to fetch");
        return;
    }
    NCLogD(@"Fetch friend online status, users:%@", userIds);
    if (![self isFriendOnlineStatusSubscribeEnable]) {
        NCLogD(@"fetchFriendOnlineStatus, friend online status subscribe is not enabled");
        return;
    }
    __block BOOL syncCompleted = NO;
    __block NSUInteger addedCount = 0;

    [self performOnCacheQueueSyncSafe:^{
        syncCompleted = self.friendOnlineStatusSyncCompleted;
        if (!syncCompleted) {
            NSUInteger beforeCount = self.pendingFriendOnlineStatusUserIds.count;
            [self.pendingFriendOnlineStatusUserIds addObjectsFromArray:userIds];
            addedCount = self.pendingFriendOnlineStatusUserIds.count - beforeCount;
        }
    }];

    if (!syncCompleted) {
        NCLogD(@"Friend online status sync not completed, queuing %lu users (%lu new, %lu duplicates, total pending: %lu)",
               (unsigned long)userIds.count,
               (unsigned long)addedCount,
               (unsigned long)(userIds.count - addedCount),
               (unsigned long)self.pendingFriendOnlineStatusUserIds.count);
        return;
    }

    [self getSubscribeUsersOnlineStatus:userIds];
}

- (NCSubscribeUserOnlineStatus *)getCachedOnlineStatus:(NSString *)userId {
    if (!userId || userId.length == 0) {
        return nil;
    }
    __block NCSubscribeUserOnlineStatus *status = nil;
    [self performOnCacheQueueSyncSafe:^{
        status = [self.statusCache objectForKey:userId];
    }];
    if (status) {
        NCLogD(@"Get cached online status, user:%@, isOnline:%@", userId, status.isOnline ? @"YES" : @"NO");
    }
    return status;
}

- (void)clearCache {
    dispatch_async(self.cacheQueue, ^{
        [self.statusCache removeAllObjects];
        [self.fetchingUserIds removeAllObjects];
        [self.subscribedUserIds removeAllObjects];
        [self.friendUserIds removeAllObjects];
        [self.pendingFriendProfileUserIds removeAllObjects];
        [self.pendingFriendOnlineStatusUserIds removeAllObjects];
        self.friendOnlineStatusSyncCompleted = NO;
    });
}

#pragma mark - NCConnectionStatusHandler

- (void)onConnectionStatusChanged:(NCConnectionStatusChangedEvent *)event {
    if (event.status == NCConnectionStatusConnected) {
        // Log the current user after a successful connection.
        NSString *currentUserId = [NCEngine getCurrentUserId];
        NCLogD(@"Connected as user: %@", currentUserId);
    } else if (event.status == NCConnectionStatusSignOut) {
        // Clear local cache and subscription tracking after sign-out.
        NSString *currentUserId = [NCEngine getCurrentUserId];
        NCLogD(@"User signOut %@ , clearing all cache and subscriptions", currentUserId);
        [self clearCache];
    }
}

#pragma mark - NCUserHandler (Subscription Events)

- (void)onSubscriptionSyncCompleted:(NCSubscriptionSyncCompletedEvent *)event {
    if (event.type == NCSubscribeTypeFriendOnlineStatus) {
        NCLogD(@"Friend online status sync completed");
        
        dispatch_async(self.cacheQueue, ^{
            // Record receipt of the subscription sync callback.
            self.friendOnlineStatusSyncCompleted = YES;
        });
        [self handlePendingFetchOnlineStatus];
    }
}

- (void)onSubscriptionChangedOnOtherDevices:(NCSubscriptionChangedOnOtherDevicesEvent *)event {
    NSMutableArray<NSString *> *subscribedUsers = [NSMutableArray array];
    NSMutableArray<NSString *> *unsubscribedUsers = [NSMutableArray array];
    
    for (NCSubscribeChangeEvent *changeEvent in event.events) {
        if (changeEvent.subscribeType == NCSubscribeTypeOnlineStatus && changeEvent.userId.length > 0) {
            if (changeEvent.operationType == NCSubscribeOperationTypeSubscribe) {
                [subscribedUsers addObject:changeEvent.userId];
            } else {
                [unsubscribedUsers addObject:changeEvent.userId];
            }
        }
    }
    if (subscribedUsers.count == 0 && unsubscribedUsers.count == 0) return;
    
    NSArray<NSString *> *addSnapshot = [subscribedUsers copy];
    NSArray<NSString *> *removeSnapshot = [unsubscribedUsers copy];

    dispatch_async(self.cacheQueue, ^{
        // Mutate subscription tracking only on cacheQueue.
        if (addSnapshot.count > 0) {
            [self.subscribedUserIds addObjectsFromArray:addSnapshot];
        }
        if (removeSnapshot.count > 0) {
            [self.subscribedUserIds minusSet:[NSSet setWithArray:removeSnapshot]];
        }
    });

    // Perform fetch and notification work outside cacheQueue to avoid reentry.
    if (addSnapshot.count > 0) {
        NCLogD(@"Other device subscribed users:%@, fetching online status", addSnapshot);
        [self getSubscribeUsersOnlineStatus:addSnapshot];
    }
    if (removeSnapshot.count > 0) {
        NCLogD(@"Other device unsubscribed users:%@, clearing cache", removeSnapshot);
        [self clearOnlineStatusCache:removeSnapshot];
    }
}

/**
 * Handles subscription status change events by refreshing affected users.
 */
- (void)onSubscriptionChanged:(NCSubscriptionChangedEvent *)event {
    if (!event.events || event.events.count == 0) {
        return;
    }
    NSMutableArray<NSString *> *userIds = [NSMutableArray array];
    
    for (NCSubscriptionStatusInfo *statusInfo in event.events) {
        // Process only regular and friend online-status events.
        if (statusInfo.subscribeType == NCSubscribeTypeOnlineStatus ||
            statusInfo.subscribeType == NCSubscribeTypeFriendOnlineStatus) {
            [userIds addObject:statusInfo.userId];
        }
    }
    NCLogD(@"Event change, userIds:%@", userIds);
    [self getSubscribeUsersOnlineStatus:userIds.copy];
}

#pragma mark - NCUserHandler (Friend Relationship Events)

/// Records the user as a friend, removes any regular subscription, and fetches friend status when enabled.
- (void)onFriendAdd:(NCFriendAddEvent *)event {
    NSString *userId = event.userId;
    if (!userId || userId.length == 0) {
        return;
    }
    NCLogD(@"onFriendAdd, userId:%@", userId);
    // Record the confirmed friend ID.
    dispatch_async(self.cacheQueue, ^{
        [self.friendUserIds addObject:userId];
    });

    // Remove the regular online-status subscription.
    [self unsubscribeUsers:@[userId] completion:nil];

    if ([self isFriendOnlineStatusSubscribeEnable]) {
        // Friend status is available only when the app setting is enabled.
        [self fetchFriendOnlineStatus:@[userId]];
    } else {
        NCLogD(@"onFriendAdd, friend online status subscribe is not enabled");
    }
}

/// Removes the IDs from the friend cache and subscribes to them as non-friends.
- (void)onFriendRemove:(NCFriendRemoveEvent *)event {
    NSArray<NSString *> *userIds = event.userIds;
    if (!userIds || userIds.count == 0) {
        return;
    }
    // Remove the IDs from the confirmed-friend cache.
    dispatch_async(self.cacheQueue, ^{
        for (NSString *userId in userIds) {
            if (userId && userId.length > 0) {
                [self.friendUserIds removeObject:userId];
            }
        }
    });
    // Subscribe to the removed friend IDs as non-friends.
    [self subscribeUsers:userIds pageSize:0 processSubscribeLimit:YES];
}

/// Clears the known-friend set and subscribes to the IDs that were present in it.
- (void)onFriendCleared:(NCFriendClearedEvent *)event {
    __block NSArray *subscribeUserIds = nil;
    [self performOnCacheQueueSyncSafe:^{
        subscribeUserIds = [self.friendUserIds copy];
        [self.friendUserIds removeAllObjects];
    }];

    if (subscribeUserIds.count > 0) {
        // Start subscriptions outside cacheQueue to avoid reentry.
        [self subscribeUsers:subscribeUserIds pageSize:0 processSubscribeLimit:YES];
    }
}

#pragma mark - Private Methods

/// Returns whether friend online-status notifications are enabled in app settings.
- (BOOL)isFriendOnlineStatusSubscribeEnable {
    NCAppSettings *appSettings = [NCEngine getAppSettings];
    return appSettings.isFriendOnlineStatusSubscribeEnable;
}

- (void)handlePendingFetchOnlineStatus {
    __block NSArray<NSString *> *profileSnapshot = nil;
    __block NSArray<NSString *> *friendStatusSnapshot = nil;

    // Atomically snapshot and clear pending IDs on cacheQueue.
    [self performOnCacheQueueSyncSafe:^{
        if (self.pendingFriendProfileUserIds.count > 0) {
            NCLogD(@"Processing %lu pending users after friend profile sync completed",
                   (unsigned long)self.pendingFriendProfileUserIds.count);
            profileSnapshot = [self.pendingFriendProfileUserIds.array copy];
            [self.pendingFriendProfileUserIds removeAllObjects];
        }

        if (self.pendingFriendOnlineStatusUserIds.count > 0) {
            NCLogD(@"Processing %lu pending friend online status users after sync completed",
                   (unsigned long)self.pendingFriendOnlineStatusUserIds.count);
            friendStatusSnapshot = [self.pendingFriendOnlineStatusUserIds.array copy];
            [self.pendingFriendOnlineStatusUserIds removeAllObjects];
        }
    }];

    if (profileSnapshot.count > 0) {
        [self filterAndFetchOnlineStatus:profileSnapshot processSubscribeLimit:YES];
    }

    if (friendStatusSnapshot.count > 0) {
        [self getSubscribeUsersOnlineStatus:friendStatusSnapshot];
    }
}

- (void)fetchOnlineStatusForUsers:(NSArray<NSString *> *)userIds
            processSubscribeLimit:(BOOL)processSubscribeLimit {
    if (userIds.count == 0) {
        NCLogD(@"Fetch online status, no users to fetch");
        return;
    }
    NCLogD(@"Fetch online status, users:%@", userIds);

    __block BOOL syncCompleted = NO;
    __block NSUInteger addedCount = 0;
    __block NSUInteger pendingCount = 0;

    [self performOnCacheQueueSyncSafe:^{
        syncCompleted = self.friendOnlineStatusSyncCompleted;
        if (!syncCompleted) {
            NSUInteger beforeCount = self.pendingFriendProfileUserIds.count;
            [self.pendingFriendProfileUserIds addObjectsFromArray:userIds];
            addedCount = self.pendingFriendProfileUserIds.count - beforeCount;
            pendingCount = self.pendingFriendProfileUserIds.count;
        }
    }];

    if (!syncCompleted) {
        NCLogD(@"Friend sync not completed, queuing %lu users (%lu new, %lu duplicates, total pending: %lu)",
               (unsigned long)userIds.count,
               (unsigned long)addedCount,
               (unsigned long)(userIds.count - addedCount),
               (unsigned long)pendingCount);
        return;
    }

    // The subscription sync callback has already arrived; process immediately.
    [self filterAndFetchOnlineStatus:userIds processSubscribeLimit:processSubscribeLimit];
}

- (void)filterAndFetchOnlineStatus:(NSArray<NSString *> *)userIds
             processSubscribeLimit:(BOOL)processSubscribeLimit {
    if (userIds.count == 0) {
        return;
    }
    [self filterFriendAndNonFriendUserIds:userIds
                           perBatchResult:^(NSArray<NSString *> * _Nullable friendUserIds,
                                             NSArray<NSString *> * _Nullable nonFriendUserIds) {
        if (nonFriendUserIds.count > 0) {
            [self subscribeUsers:nonFriendUserIds pageSize:0 processSubscribeLimit:processSubscribeLimit];
        }
        // Fetch friend status only when the app setting is enabled.
        if (friendUserIds.count > 0 && [self isFriendOnlineStatusSubscribeEnable]) {
            [self getSubscribeUsersOnlineStatus:friendUserIds];
        } else {
            NCLogD(@"filterAndFetchOnlineStatus, friend online status subscribe is %@", [self isFriendOnlineStatusSubscribeEnable] ? @"enabled" : @"disabled");
        }
    } completion:^(BOOL success) {
        if (!success) {
            NCLogD(@"Filter friend/non-friend failed, skip fetching online status");
        }
    }];
}

/// Classifies user IDs as friends or non-friends in batches.
- (void)filterFriendAndNonFriendUserIds:(NSArray<NSString *> *)userIds
                         perBatchResult:(void (^)(NSArray<NSString *> * _Nullable friendUserIds,
                                                  NSArray<NSString *> * _Nullable nonFriendUserIds))perBatchResult
                             completion:(void (^)(BOOL success))completion {
    __block BOOL completionCalled = NO;
    // Finish the classification once.
    void (^finish)(BOOL) = ^(BOOL success) {
        if (completionCalled) {
            return;
        }
        completionCalled = YES;
        if (completion) {
            completion(success);
        }
    };
    if (userIds.count == 0) {
        finish(YES);
        return;
    }
    
    // Resolve IDs already present in the confirmed-friend cache first.
    __block NSSet *friendCacheSnapshot = nil;
    [self performOnCacheQueueSyncSafe:^{
        friendCacheSnapshot = [self.friendUserIds copy];
    }];
    NSMutableOrderedSet<NSString *> *knownFriendIds = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet<NSString *> *unknownUserIds = [NSMutableOrderedSet orderedSet];
    for (NSString *userId in userIds) {
        if (![userId isKindOfClass:[NSString class]] || userId.length == 0) {
            continue;
        }
        if ([friendCacheSnapshot containsObject:userId]) {
            [knownFriendIds addObject:userId];
        } else {
            [unknownUserIds addObject:userId];
        }
    }
    
    // Report known friends before querying the remaining IDs.
    if (knownFriendIds.count > 0 && perBatchResult) {
        NCLogD(@"Known friend ids:%@", knownFriendIds.array);
        perBatchResult([knownFriendIds.array copy], @[]);
    }

    // Return when every valid ID was already known as a friend.
    if (unknownUserIds.count == 0) {
        NCLogD(@"No unknown user ids, finish");
        finish(YES);
        return;
    }

    __block NSMutableOrderedSet<NSString *> *pendingUnknownUserIds = [unknownUserIds mutableCopy];

    // Query the remaining IDs in batches.
    [self batchQueryFriendsInfo:unknownUserIds.array
                perBatchResult:^(NSArray<NSString *> * _Nullable batchFriendUserIds,
                                  NSArray<NSString *> * _Nullable batchNonFriendUserIds) {
        NCLogD(@"perBatchResult, friendUserIds:%@, nonFriendUserIds:%@", batchFriendUserIds, batchNonFriendUserIds);
        if (batchFriendUserIds.count > 0) {
            NSSet *friendSet = [NSSet setWithArray:batchFriendUserIds];
            dispatch_async(self.cacheQueue, ^{
                // Cache only IDs confirmed as friends.
                [self.friendUserIds unionSet:friendSet];
            });
        }
        if (perBatchResult) {
            perBatchResult(batchFriendUserIds, batchNonFriendUserIds);
        }
        
        // Remove classified IDs from the pending set.
        for (NSString *userId in batchFriendUserIds) {
            [pendingUnknownUserIds removeObject:userId];
        }
        for (NSString *userId in batchNonFriendUserIds) {
            [pendingUnknownUserIds removeObject:userId];
        }
    } completion:^(NCChatUIErrorCode status) {
        BOOL treatAsSuccess = (status == NCChatUIErrorCodeSuccess || status == NCChatUIErrorCodeUserProfileServiceUnavailable);
        if (status == NCChatUIErrorCodeUserProfileServiceUnavailable &&
            perBatchResult &&
            pendingUnknownUserIds.count > 0) {
            // The current fallback treats every unresolved ID as a non-friend when the profile service is unavailable.
            perBatchResult(@[], [pendingUnknownUserIds.array copy]);
        }
        if (!treatAsSuccess) {
            NCLogD(@"Filter failed with status:%ld", (long)status);
        }
        finish(treatAsSuccess);
    }];
}

- (void)batchQueryFriendsInfo:(NSArray<NSString *> *)userIds
              perBatchResult:(void (^)(NSArray<NSString *> * _Nullable friendUserIds,
                                       NSArray<NSString *> * _Nullable nonFriendUserIds))perBatchResult
                   completion:(void (^)(NCChatUIErrorCode status))completion {
    
    if (!userIds || userIds.count == 0) {
        if (completion) {
            completion(NCChatUIErrorCodeSuccess);
        }
        return;
    }
    [self processQueueItems:userIds
                  batchSize:kNCOnlineStatusFriendQueryBatchSize
                    context:nil
                   executor:^(NSArray *batch,
                              id context,
                              NCBatchPendingSnapshotBlock pendingSnapshot,
                              NCBatchCompletion batchCompletion,
                              NCBatchRetryBlock retry,
                              NCBatchFailBlock fail) {
        NCLogD(@"Querying friends batch users:%@", batch);
        
        [[NCEngine userModule] getFriendsInfoWithUserIds:batch
                                               completion:^(NSArray<NCFriendInfo *> * _Nullable friendInfos, NCError * _Nullable error) {
            NSInteger errorCode = error ? error.code : NCChatUIErrorCodeSuccess;
            if (errorCode == NCChatUIErrorCodeSuccess) {
                NSMutableSet *friendIdSet = [NSMutableSet set];
                for (NCFriendInfo *friendInfo in friendInfos) {
                    if (friendInfo.userId && friendInfo.userId.length > 0) {
                        [friendIdSet addObject:friendInfo.userId];
                    }
                }
                NSMutableArray *batchFriends = [NSMutableArray array];
                NSMutableArray *batchNonFriends = [NSMutableArray array];
                for (NSString *userId in batch) {
                    if ([friendIdSet containsObject:userId]) {
                        [batchFriends addObject:userId];
                    } else {
                        [batchNonFriends addObject:userId];
                    }
                }
                if (perBatchResult) {
                    perBatchResult([batchFriends copy], [batchNonFriends copy]);
                }
                // The full batch succeeded; continue without retrying.
                batchCompletion();
            } else if (errorCode == NCChatUIErrorCodeRequestOverFrequency) {
                NCLogD(@"batchQueryFriendsInfo over frequency, users:%@", batch);
                retry(nil);
            } else if (errorCode == NCChatUIErrorCodeUserProfileServiceUnavailable) {
                NCLogD(@"User profile service unavailable, treat all as non-friends");
                fail(NCChatUIErrorCodeUserProfileServiceUnavailable);
            } else {
                NCLogD(@"batchQueryFriendsInfo failed, code:%ld, users:%@", (long)errorCode, batch);
                fail(errorCode);
            }
        }];
    } completion:^(NCChatUIErrorCode status) {
        if (completion) {
            completion(status);
        }
    }];
}

- (void)getSubscribeUsersOnlineStatus:(NSArray<NSString *> *)userIds {
    // Exclude IDs with a request already in flight.
    __block NSMutableArray *needFetchUserIds = [NSMutableArray array];
    [self performOnCacheQueueSyncSafe:^{
        for (NSString *userId in userIds) {
            if (userId.length > 0 && ![self.fetchingUserIds containsObject:userId]) {
                [needFetchUserIds addObject:userId];
                [self.fetchingUserIds addObject:userId];
            }
        }
    }];
    
    // Return when every ID is already being fetched.
    if (needFetchUserIds.count == 0) {
        NCLogD(@"Get subscribe users online status, no users to fetch");
        return;
    }
    NCLogD(@"Get subscribe users online status, users:%@", needFetchUserIds);

    [[NCEngine userModule] getSubscribeUsersOnlineStatusWithUserIds:needFetchUserIds
                                                          completion:^(NSArray<NCSubscribeUserOnlineStatus *> * _Nullable status, NCError * _Nullable error) {
        NSInteger statusCode = error ? error.code : NCChatUIErrorCodeSuccess;
        NCLogD(@"getSubscribeUsersOnlineStatus, code:%ld", (long)statusCode);
        // Clear the in-flight markers.
        dispatch_async(self.cacheQueue, ^{
            [self.fetchingUserIds minusSet:[NSSet setWithArray:needFetchUserIds]];
        });
        
        if (statusCode == NCChatUIErrorCodeSuccess && status) {
            [self cacheOnlineStatusesAndNotify:status];
        } else if (statusCode == NCChatUIErrorCodeRequestOverFrequency) {
            NCLogD(@"getSubscribeUsersOnlineStatus over frequency, retry users:%@", needFetchUserIds);
            [self getSubscribeUsersOnlineStatus:needFetchUserIds];
        } else {
            NCLogD(@"getSubscribeUsersOnlineStatus failed, users:%@", needFetchUserIds);
        }
    }];
}

- (void)clearOnlineStatusCache:(NSArray<NSString *> *)userIds {
    if (!userIds || userIds.count == 0) {
        return;
    }
    
    // Remove cached entries on the serial queue.
    dispatch_async(self.cacheQueue, ^{
        NSMutableArray *clearedUserIds = [NSMutableArray array];
        
        for (NSString *userId in userIds) {
            if (userId && userId.length > 0) {
                // Notify only for entries that were actually present.
                if ([self.statusCache objectForKey:userId] != nil) {
                    // Remove the cached status.
                    [self.statusCache removeObjectForKey:userId];
                    [clearedUserIds addObject:userId];
                }
            }
        }
        
        NCLogD(@"Cleared online status cache for %lu users, users: %@",
               (unsigned long)clearedUserIds.count, [clearedUserIds copy]);
        
        // Notify observers on the main queue when entries were removed.
        if (clearedUserIds.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:NCChatUIUserOnlineStatusChangedNotification
                                                                    object:nil
                                                                  userInfo:@{NCChatUIUserOnlineStatusChangedUserIdsKey: [clearedUserIds copy]}];
            });
        }
    });
}

/// Caches statuses on cacheQueue and notifies observers on the main queue.
- (void)cacheOnlineStatusesAndNotify:(NSArray<NCSubscribeUserOnlineStatus *> *)statuses {
    if (!statuses || statuses.count == 0) {
        return;
    }
    
    NSMutableArray<NCSubscribeUserOnlineStatus *> *validStatuses = [NSMutableArray array];
    
    for (NCSubscribeUserOnlineStatus *status in statuses) {
        if (status.userId.length > 0) {
            [validStatuses addObject:status];
        }
    }
    
    if (validStatuses.count == 0) {
        return;
    }
    
    NSArray<NCSubscribeUserOnlineStatus *> *statusSnapshot = [validStatuses copy];
    
    dispatch_async(self.cacheQueue, ^{
        NSMutableArray<NSString *> *changedUserIds = [NSMutableArray array];
        NSMutableDictionary <NSString *, NSString *> *changedStatus = [NSMutableDictionary dictionary];
        
        for (NCSubscribeUserOnlineStatus *status in statusSnapshot) {
            [self.statusCache setObject:status forKey:status.userId];
            [changedUserIds addObject:status.userId];
            [changedStatus setValue:status.isOnline ? @"YES" : @"NO" forKey:status.userId];
        }
        
        NCLogD(@"Cached online status for users:%@", changedStatus);
        
        if (changedUserIds.count > 0) {
            NCLogD(@"Notify changed online status for users:%@", changedUserIds);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:NCChatUIUserOnlineStatusChangedNotification
                                                                    object:nil
                                                                  userInfo:@{NCChatUIUserOnlineStatusChangedUserIdsKey: changedUserIds}];
            });
        }
    });
}

#pragma mark - Subscription Management

/// Subscribes to user online status.
- (void)subscribeUsers:(NSArray<NSString *> *)userIds
              pageSize:(NSInteger)pageSize
 processSubscribeLimit:(BOOL)processSubscribeLimit {
    if (userIds.count == 0) {
        return;
    }
    NSInteger batchSize = pageSize > 0 ? pageSize : kNCOnlineStatusSubscribeBatchSize;
    
    [self processQueueItems:userIds
                  batchSize:batchSize
                    context:nil
                   executor:^(NSArray *batch,
                              id context,
                              NCBatchPendingSnapshotBlock pendingSnapshot,
                              NCBatchCompletion batchCompletion,
                              NCBatchRetryBlock retry,
                              NCBatchFailBlock fail) {
        
        NCLogD(@"Subscribing batch users:%@", batch);
        NCSubscribeEventParams *params = [[NCSubscribeEventParams alloc] initWithSubscribeType:NCSubscribeTypeOnlineStatus userIds:batch];
        params.expiry = kNCOnlineStatusDefaultSubscribeExpiry;
        
        [[NCEngine userModule] subscribeEventWithParams:params completion:^(NSArray<NSString *> * _Nullable failedUserIds, NCError * _Nullable error) {
            NSInteger statusCode = error ? error.code : NCChatUIErrorCodeSuccess;
            NCLogD(@"subscribeEvent completion code:%ld, users:%@", (long)statusCode, batch);
            switch (statusCode) {
                case NCChatUIErrorCodeSuccess: {
                    [self recordSubscribedUsers:batch];
                    [self getSubscribeUsersOnlineStatus:batch];
                    // The current batch succeeded.
                    batchCompletion();
                    break;
                }
                case NCChatUIErrorCodeSubscribeOnlineServiceUnavailable: {
                    // Stop when the online-status subscription service is unavailable.
                    NCLogD(@"Subscribe online service unavailable, terminate subscription process");
                    fail(statusCode);
                    break;
                }
                case NCChatUIErrorCodeBeSubscribedUserIdsCountExceedLimit: {
                    // failedUserIds contains users rejected because their subscriber limit was reached.
                    NSArray *failedList = failedUserIds ?: @[];
                    NCLogD(@"Be-subscribed count exceeded limit for users:%@", failedList);
                    NSMutableArray *retryUsers = [batch mutableCopy];
                    if (failedList.count > 0) {
                        [retryUsers removeObjectsInArray:failedList];
                    }
                    // Drop rejected IDs and retry the remainder of the batch.
                    retry([retryUsers copy]);
                    break;
                }
                case NCChatUIErrorCodeSubscribedUserIdsExceedLimit: {
                    NCLogD(@"Subscribe count exceeded limit, processSubscribeLimit:%@", processSubscribeLimit ? @"YES" : @"NO");
                    // The current account exceeded its subscription limit.
                    if (processSubscribeLimit) {
                        // Invoke the eviction strategy when limit handling is enabled.
                        [self handleSubscribeExceedLimit];
                    }
                    fail(statusCode);
                    break;
                }
                case NCChatUIErrorCodeRequestOverFrequency: {
                    // Retry the current batch after the default rate-limit delay.
                    NCLogD(@"subscribeEvent over frequency, retry users:%@", batch);
                    retry(nil);
                    break;
                }
                default: {
                    NCLogD(@"subscribeEvent failed");
                    fail(statusCode);
                    break;
                }
            }
        }];
    } completion:^(NCChatUIErrorCode status) {
        
    }];
}

/// Unsubscribes from user online status.
- (void)unsubscribeUsers:(NSArray<NSString *> *)userIds completion:(void (^)(NCChatUIErrorCode status, NSArray<NSString *> * _Nullable failedUserIds))completion {
    if (!userIds || userIds.count == 0) {
        if (completion) {
            completion(NCChatUIErrorCodeInvalidParameterUserIdList, nil);
        }
        return;
    }
    
    // Unsubscribe in batches.
    [self batchUnsubscribeUsers:userIds
                      pageSize:0
               collectedFailed:[NSMutableArray array]
                    completion:completion];
}

- (void)batchUnsubscribeUsers:(NSArray<NSString *> *)userIds
                     pageSize:(NSInteger)pageSize
              collectedFailed:(NSMutableArray<NSString *> *)collectedFailed
                   completion:(void (^)(NCChatUIErrorCode status, NSArray<NSString *> * _Nullable failedUserIds))completion {
    if (userIds.count == 0) {
        if (completion) {
            completion(NCChatUIErrorCodeSuccess, collectedFailed.count > 0 ? [collectedFailed copy] : nil);
        }
        return;
    }
    
    NSInteger batchSize = pageSize > 0 ? pageSize : kNCOnlineStatusSubscribeBatchSize;
    
    [self processQueueItems:userIds
                  batchSize:batchSize
                    context:collectedFailed
                   executor:^(NSArray *batch,
                              NSMutableArray<NSString *> *failedContext,
                              NCBatchPendingSnapshotBlock pendingSnapshot,
                              NCBatchCompletion batchCompletion,
                              NCBatchRetryBlock retry,
                              NCBatchFailBlock fail) {
        
        NCLogD(@"Unsubscribing batch users:%@", batch);
        NCUnsubscribeEventParams *params = [[NCUnsubscribeEventParams alloc] initWithSubscribeType:NCSubscribeTypeOnlineStatus userIds:batch];
        
        [[NCEngine userModule] unsubscribeEventWithParams:params completion:^(NSArray<NSString *> * _Nullable failedUserIds, NCError * _Nullable error) {
            NSInteger statusCode = error ? error.code : NCChatUIErrorCodeSuccess;
            NCLogD(@"unSubscribeEvent completion code:%ld, users:%@, failedUserIds:%@", (long)statusCode, batch, failedUserIds);
            if (statusCode == NCChatUIErrorCodeSuccess) {
                [self removeSubscribedUsers:batch];
                
                NSArray<NSString *> *successUserIds = batch;
                if (failedUserIds.count > 0) {
                    NSMutableArray *successful = [batch mutableCopy];
                    [successful removeObjectsInArray:failedUserIds];
                    successUserIds = [successful copy];
                    [failedContext addObjectsFromArray:failedUserIds];
                }
                [self clearOnlineStatusCache:successUserIds];                
                // The current batch succeeded.
                batchCompletion();
            } else if (statusCode == NCChatUIErrorCodeRequestOverFrequency) {
                NCLogD(@"unSubscribeEvent over frequency");
                retry(nil);
            } else {
                if (failedUserIds.count > 0) {
                    [failedContext addObjectsFromArray:failedUserIds];
                }
                NCLogD(@"unSubscribeEvent failed");
                fail(statusCode);
            }
        }];
    } completion:^(NCChatUIErrorCode status) {
        NCLogD(@"batchUnsubscribeUsers completion code:%ld", (long)status);
        if (completion) {
            completion(status, collectedFailed.count > 0 ? [collectedFailed copy] : nil);
        }
    }];
}

/// Records subscribed user IDs.
- (void)recordSubscribedUsers:(NSArray<NSString *> *)userIds {
    if (!userIds || userIds.count == 0) {
        return;
    }
    dispatch_async(self.cacheQueue, ^{
        NCLogD(@"Recorded subscribed users, users:%@", userIds);
        [self.subscribedUserIds addObjectsFromArray:userIds];
    });
}

/// Removes IDs from local subscription tracking.
- (void)removeSubscribedUsers:(NSArray<NSString *> *)userIds {
    if (!userIds || userIds.count == 0) {
        return;
    }
    
    dispatch_async(self.cacheQueue, ^{
        [self.subscribedUserIds minusSet:[NSSet setWithArray:userIds]];
        NCLogD(@"Removed subscribed users, users:%@", userIds);
    });
}

/// Builds a limit-recovery plan from the delegate's priority-ordered user list.
- (void)handleSubscribeExceedLimit {
    // The delegate supplies users whose online status should remain visible.
    if (!self.delegate) {
        NCLogD(@"Delegate is not set, cannot handle subscribe exceed limit");
        return;
    }
    
    NSArray<NSString *> *allUserIds = [self.delegate userIdsNeedOnlineStatus:self];
    
    // Stop when the delegate supplies no users.
    if (!allUserIds || allUserIds.count == 0) {
        NCLogD(@"Delegate returned empty user list, no users need online status");
        return;
    }
    
    // Treat IDs absent from the confirmed-friend cache as non-friends for this recovery pass.
    __block NSMutableArray *nonFriendUserIds = [NSMutableArray array];
    [self performOnCacheQueueSyncSafe:^{
        for (NSString *userId in allUserIds) {
            if (userId && userId.length > 0 && ![self.friendUserIds containsObject:userId]) {
                [nonFriendUserIds addObject:userId];
            }
        }
    }];
    
    if (nonFriendUserIds.count > 0) {
        // Apply the priority-based plan to IDs treated as non-friends.
        NCLogD(@"Delegate provided users:%@, filtered to users:%@ non-friends for subscription",
               allUserIds, nonFriendUserIds);
        
        // Query all current subscription records, including subscribeTime.
        [self getAllSubscribedEvents:^(NSArray<NCSubscriptionStatusInfo *> * _Nullable allSubscribedEvents) {
            if (!allSubscribedEvents) {
                // Stop if subscription records cannot be loaded.
                NCLogD(@"Query all subscribed events failed, cannot handle subscribe exceed limit");
                return;
            }
            
            // Calculate and execute the recovery plan.
            NCSubscriptionPlan *plan = [self calculateSubscriptionStrategy:allSubscribedEvents
                                                          nonFriendUserIds:nonFriendUserIds];
            [self executeSubscriptionPlan:plan];
        }];
        
    } else {
        // Every supplied ID is present in the confirmed-friend cache.
        NCLogD(@"All users are friends, no subscription needed");
    }
}

/// Selects users whose current raw remaining-time calculation is positive and within the threshold.
- (NSArray<NSString *> *)findUsersNeedResubscribe:(NSArray<NCSubscriptionStatusInfo *> *)events {
    NSMutableArray *resubscribeList = [NSMutableArray array];
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970] * 1000; // Current epoch time in milliseconds.
    
    for (NCSubscriptionStatusInfo *event in events) {
        if (event.userId && event.userId.length > 0) {
            // Subtract the current millisecond timestamp from subscribeTime without unit conversion.
            NSTimeInterval remainingTime = event.subscribeTime - currentTime;
            
            // Compare the positive raw difference directly with the seconds-based threshold.
            if (remainingTime > 0 && remainingTime <= kNCOnlineStatusSubscribeExpiryThreshold) {
                [resubscribeList addObject:event.userId];
                NCLogD(@"User %@ has raw remaining time %.0f (threshold: %ld), needs resubscription",
                       event.userId, remainingTime, (long)kNCOnlineStatusSubscribeExpiryThreshold);
            }
        }
    }
    return [resubscribeList copy];
}

/// Calculates the subscription recovery plan.
/// - Parameters:
///   - allSubscribedEvents: All current online-status subscription records.
///   - nonFriendUserIds: Candidate IDs ordered by priority.
/// - Returns: A recovery plan.
- (NCSubscriptionPlan *)calculateSubscriptionStrategy:(NSArray<NCSubscriptionStatusInfo *> *)allSubscribedEvents
                                      nonFriendUserIds:(NSArray<NSString *> *)nonFriendUserIds {
    // Extract subscribed user IDs.
    NSMutableArray<NSString *> *allSubscribedUserIds = [NSMutableArray array];
    for (NCSubscriptionStatusInfo *event in allSubscribedEvents) {
        if (event.userId && event.userId.length > 0) {
            [allSubscribedUserIds addObject:event.userId];
        }
    }
    
    __block NSArray<NSString *> *usersToKeep = nil;
    __block NSArray<NSString *> *usersToUnsubscribe = nil;
    __block NSArray<NSString *> *usersToSubscribe = nil;
    __block NSArray<NSString *> *usersToResubscribe = nil;
    
    [self performOnCacheQueueSyncSafe:^{
        // 1. Truncate the priority list to the maximum subscription count.
        NSInteger maxCount = kNCOnlineStatusMaxSubscribeCount;
        usersToKeep = nonFriendUserIds.count > maxCount
                    ? [nonFriendUserIds subarrayWithRange:NSMakeRange(0, maxCount)]
                    : nonFriendUserIds;
        
        // 2. Unsubscribe current IDs that are outside the retained priority list.
        NSSet *keepSet = [NSSet setWithArray:usersToKeep];
        NSMutableArray *unsubscribeList = [NSMutableArray array];
        
        for (NSString *subscribedUserId in allSubscribedUserIds) {
            if (![keepSet containsObject:subscribedUserId]) {
                [unsubscribeList addObject:subscribedUserId];
            }
        }
        usersToUnsubscribe = [unsubscribeList copy];
        
        // 3. Select current subscriptions that match the raw remaining-time threshold.
        usersToResubscribe = [self findUsersNeedResubscribe:allSubscribedEvents];
        
        // 4. Subscribe retained IDs that are not currently subscribed.
        NSSet *subscribedSet = [NSSet setWithArray:allSubscribedUserIds];
        NSMutableArray *subscribeList = [NSMutableArray array];
        
        for (NSString *userId in usersToKeep) {
            if (![subscribedSet containsObject:userId]) {
                [subscribeList addObject:userId];
            }
        }
        usersToSubscribe = [subscribeList copy];
        
        NCLogD(@"Priority-based handling - keep: %@, unsubscribe: %@, subscribe: %@, resubscribe: %@, limit: %ld",
            usersToKeep, usersToUnsubscribe, usersToSubscribe, usersToResubscribe, (long)maxCount);
    }];
    
    // 5. Merge new subscription and resubscription candidates.
    NSMutableSet *allUsersToSubscribeSet = [NSMutableSet set];
    if (usersToSubscribe) {
        [allUsersToSubscribeSet addObjectsFromArray:usersToSubscribe];
    }
    if (usersToResubscribe) {
        [allUsersToSubscribeSet addObjectsFromArray:usersToResubscribe];
    }

    // Derive retained IDs that require no subscription mutation.
    NSMutableArray *keepUserIds = [NSMutableArray arrayWithArray:usersToKeep];
    [keepUserIds removeObjectsInArray:usersToUnsubscribe];
    [keepUserIds removeObjectsInArray:usersToSubscribe];
    
    NCSubscriptionPlan *plan = [[NCSubscriptionPlan alloc] init];
    plan.keepUserIds = keepUserIds;
    plan.unsubscribeUserIds = usersToUnsubscribe;
    plan.subscribeUserIds = [allUsersToSubscribeSet allObjects];

    return plan;
}

- (void)executeSubscriptionPlan:(NCSubscriptionPlan *)plan {
    if (plan.keepUserIds.count > 0) {
        NCLogD(@"Refreshing keep users:%@", plan.keepUserIds);
        [self getSubscribeUsersOnlineStatus:plan.keepUserIds];
    }
    // Return when the plan has no subscription mutations.
    if (plan.unsubscribeUserIds.count == 0 && plan.subscribeUserIds.count == 0) {
        NCLogD(@"No users to unsubscribe or subscribe, completed");
        return;
    }
    
    void (^handleSubscribe)(void) = ^{
        NCLogD(@"handleSubscribe");
        if (plan.subscribeUserIds.count > 0) {
            NCLogD(@"Subscribing users:%@", plan.subscribeUserIds);
            [self subscribeUsers:plan.subscribeUserIds pageSize:kNCOnlineStatusSubscribeMinBatchSize processSubscribeLimit:NO];
        } else {
            NCLogD(@"No users to subscribe, completed");
        }
    };
    
    // Unsubscribe first, then subscribe new and resubscription candidates.
    if (plan.unsubscribeUserIds.count > 0) {
        // 1. Remove obsolete subscriptions.
        [self unsubscribeUsers:plan.unsubscribeUserIds completion:^(NCChatUIErrorCode status, NSArray<NSString *> * _Nullable failedUserIds) {
            if (status == NCChatUIErrorCodeSuccess) {
                // 2. Subscribe the plan's new and resubscription candidates.
                handleSubscribe();
            } else {
                NCLogD(@"Unsubscribe failed, cannot subscribe new users");
            }
        }];
    } else {
        NCLogD(@"No users to unsubscribe");
        handleSubscribe();
    }
}

/// Queries all current online-status subscription records.
- (void)getAllSubscribedEvents:(void (^)(NSArray<NCSubscriptionStatusInfo *> * _Nullable events))completion {
    NCGetSubscribeEventParams *params = [[NCGetSubscribeEventParams alloc] init];
    params.subscribeType = NCSubscribeTypeOnlineStatus;
    params.userIds = @[];
    [[NCEngine userModule] getSubscribeEventWithParams:params completion:^(NSArray<NCSubscriptionStatusInfo *> * _Nullable events, NCError * _Nullable error) {
        NSInteger statusCode = error ? error.code : NCChatUIErrorCodeSuccess;
        if (statusCode == NCChatUIErrorCodeSuccess) {
            NCLogD(@"querySubscribeEvent finished fetching all subscribed events, total: %lu",
                   (unsigned long)events.count);
            if (completion) {
                completion(events ?: @[]);
            }
        } else if (statusCode == NCChatUIErrorCodeRequestOverFrequency) {
            NCLogD(@"querySubscribeEvent over frequency");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kNCOnlineStatusBatchRetryDelay), dispatch_get_main_queue(), ^{
                [self getAllSubscribedEvents:completion];
            });
        } else {
            NCLogD(@"querySubscribeEvent failed, status: %ld", (long)statusCode);
            if (completion) {
                completion(nil);
            }
        }
    }];
}

/// Processes items in sequential batches.
- (void)processQueueItems:(NSArray *)items
                batchSize:(NSInteger)batchSize
                  context:(id)context
                 executor:(NCBatchExecutorBlock)executor
               completion:(void (^)(NCChatUIErrorCode status))completion {
    if (!items || items.count == 0) {
        if (completion) {
            completion(NCChatUIErrorCodeSuccess);
        }
        return;
    }
    
    NSInteger safeBatchSize = batchSize > 0 ? batchSize : items.count;
    NSArray *fullItems = [items copy];
    // Drive batches on a serial queue and keep execution on a consistent context.
    dispatch_queue_t workerQueue = dispatch_queue_create("ai.nexconn.batch.queue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(workerQueue, ^{
        [self executeBatchItems:fullItems
                       batchSize:safeBatchSize
                       startIndex:0
                         context:context
                        executor:executor
                      completion:completion
                     workerQueue:workerQueue];
    });
}

- (void)executeBatchItems:(NSArray *)fullItems
                batchSize:(NSInteger)batchSize
                startIndex:(NSInteger)startIndex
                  context:(id)context
                 executor:(NCBatchExecutorBlock)executor
               completion:(void (^)(NCChatUIErrorCode status))completion
              workerQueue:(dispatch_queue_t)workerQueue {
    if (startIndex >= fullItems.count) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NCChatUIErrorCodeSuccess);
            });
        }
        return;
    }
    // Extract a contiguous batch beginning at startIndex.
    NSInteger remainingCount = fullItems.count - startIndex;
    NSInteger currentBatchSize = MIN(batchSize, remainingCount);
    // Retain the current range for advancing or retrying this batch.
    NSRange batchRange = NSMakeRange(startIndex, currentBatchSize);
    NSArray *batch = [fullItems subarrayWithRange:batchRange];
    
    // Expose a snapshot of items remaining from the current start index.
    NCBatchPendingSnapshotBlock snapshotBlock = ^{
        NSRange snapshotRange = NSMakeRange(startIndex, fullItems.count - startIndex);
        return [[fullItems subarrayWithRange:snapshotRange] copy];
    };
    
    [self runBatchItems:batch
              fullItems:fullItems
             batchRange:batchRange
              batchSize:batchSize
                context:context
       snapshotProvider:snapshotBlock
               executor:executor
             completion:completion
            workerQueue:workerQueue];
}

- (void)runBatchItems:(NSArray *)currentItems
            fullItems:(NSArray *)fullItems
           batchRange:(NSRange)batchRange
            batchSize:(NSInteger)batchSize
              context:(id)context
     snapshotProvider:(NCBatchPendingSnapshotBlock)snapshotBlock
             executor:(NCBatchExecutorBlock)executor
           completion:(void (^)(NCChatUIErrorCode status))completion
          workerQueue:(dispatch_queue_t)workerQueue {
    executor(currentItems, context, snapshotBlock, ^{
        dispatch_async(workerQueue, ^{
            NSInteger nextStartIndex = NSMaxRange(batchRange);
            [self executeBatchItems:fullItems
                           batchSize:batchSize
                           startIndex:nextStartIndex
                             context:context
                            executor:executor
                          completion:completion
                         workerQueue:workerQueue];
        });
    }, ^(NSArray *retryItems) {
        dispatch_async(workerQueue, ^{
            if (retryItems.count > 0) {
                // Retry an explicit subset immediately; nil retries are rate-limited below.
                [self runBatchItems:retryItems
                           fullItems:fullItems
                          batchRange:batchRange
                           batchSize:batchSize
                             context:context
                    snapshotProvider:snapshotBlock
                            executor:executor
                          completion:completion
                         workerQueue:workerQueue];
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kNCOnlineStatusBatchRetryDelay), workerQueue, ^{
                    [self runBatchItems:currentItems
                                  fullItems:fullItems
                                 batchRange:batchRange
                                 batchSize:batchSize
                                   context:context
                          snapshotProvider:snapshotBlock
                                  executor:executor
                                completion:completion
                               workerQueue:workerQueue];
                });
            }
        });
    }, ^(NCChatUIErrorCode status) { // fail block
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(status);
            });
        }
    });
}

/// Returns whether the current execution context is cacheQueue.
- (BOOL)isOnCacheQueue {
    return dispatch_get_specific(kNCOnlineStatusCacheQueueKey) != NULL;
}

/// Executes synchronously on cacheQueue, or inline when already on the queue.
- (void)performOnCacheQueueSyncSafe:(dispatch_block_t)block {
    if (!block) return;
    if ([self isOnCacheQueue]) {
        block();
    } else {
        dispatch_sync(self.cacheQueue, block);
    }
}

@end
