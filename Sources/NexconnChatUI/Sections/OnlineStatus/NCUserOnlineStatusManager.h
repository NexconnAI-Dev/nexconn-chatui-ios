//
//  NCUserOnlineStatusManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Delegate Definition

@class NCUserOnlineStatusManager;

/// Online status subscription manager delegate.
///
/// Used by external modules, such as the channel list, to provide users whose online status should be displayed when the subscription limit is exceeded.
@protocol NCUserOnlineStatusManagerDelegate <NSObject>

@required

/// Gets the user ID list whose online status should be displayed.
///
/// - Parameter manager: Online status manager instance.
/// - Returns: User ID array whose online status should be displayed, sorted by priority with higher priority first.
///
/// - Note:
///   - When the subscription count exceeds the limit, the manager calls this method to get the users whose online status should be displayed.
///   - The returned list can contain friends and non-friends. The manager filters it internally because friends do not need subscriptions.
///   - The filtered list is truncated to the maximum subscription count, and extra users are not subscribed.
///   - Returning nil or an empty array means no users need online status display, and the subscription flow stops.
- (NSArray<NSString *> * _Nullable)userIdsNeedOnlineStatus:(NCUserOnlineStatusManager *)manager;

@end

@interface NCUserOnlineStatusManager : NSObject

/// Delegate object.
@property (nonatomic, weak, nullable) id<NCUserOnlineStatusManagerDelegate> delegate;

/// Gets the shared instance.
+ (instancetype)sharedManager;

/// Fetches online status for multiple users.
///
/// - Note:
///   1. Fetches the latest status from Lib.
///   2. Updates the local cache.
///   3. Posts NCChatUIUserOnlineStatusChangedNotification so all observing pages update automatically.
- (void)fetchOnlineStatus:(NSArray<NSString *> *)userIds;

/// Fetches a user's online status and optionally handles subscription limit overflow.
/// - Parameters:
///   - userId: User ID.
///   - processSubscribeLimit: Whether to handle subscription limit overflow.
/// - Note:
///   - If processSubscribeLimit is YES, subscription limit overflow is handled automatically.
///   - If processSubscribeLimit is NO, subscription limit overflow is not handled automatically and must be handled externally.
- (void)fetchOnlineStatus:(NSString *)userId processSubscribeLimit:(BOOL)processSubscribeLimit;

/// Fetches friends' online status.
///
/// - Parameter userIds: User ID array. All users must be friends.
- (void)fetchFriendOnlineStatus:(NSArray<NSString *> *)userIds;


/// Gets a user's online status from cache synchronously and returns immediately.
///
/// - Parameter userId: User ID.
/// - Returns: Online status object, or nil if the user's status is not cached.
///
/// - Note:
///   - Used for fast UI display without sending a network request.
///   - If nil is returned, call fetchOnlineStatus: to get the latest status.
- (NCSubscribeUserOnlineStatus * _Nullable)getCachedOnlineStatus:(NSString *)userId;

/// Clears all caches and resets internal state.
- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
