//
//  NCUserInfoCacheManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCChatUIUserInfo.h"
#import "NCInfoUpdateCenter.h"

@class NCChatUIGroup;

NS_ASSUME_NONNULL_BEGIN

@interface NCUserInfoCacheManager : NSObject

+ (instancetype)sharedManager;

#pragma mark - UserInfo

// Get from cache first. If missing, return nil and invoke the user info provider.
- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId;

// Get from cache and the user info provider.
- (void)getUserInfo:(NSString *)userId complete:(void (^)(NCChatUIUserInfo *userInfo))completeBlock;

// Get user info from the current cache only, without callbacks.
- (NCChatUIUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId;

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo forUserId:(NSString *)userId;

- (void)clearUserInfo:(NSString *)userId;

- (void)clearAllUserInfo;

#pragma mark - GroupUserInfo (sugar for ConversationUserInfo)

- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId inGroupId:(NSString *)groupId;

- (void)getUserInfo:(NSString *)userId
          inGroupId:(NSString *)groupId
           complete:(void (^)(NCChatUIUserInfo *userInfo))completeBlock;

- (NCChatUIUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId inGroupId:(NSString *)groupId;

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo forUserId:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearGroupUserInfo:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearAllGroupUserInfo;

#pragma mark - GroupInfo (sugar for ConversationInfo)

- (NCChatUIGroup *)getGroupInfo:(NSString *)groupId;

- (void)getGroupInfo:(NSString *)groupId complete:(void (^)(NCChatUIGroup *groupInfo))completeBlock;

- (NCChatUIGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId;

- (void)updateGroupInfo:(NCChatUIGroup *)groupInfo;

- (void)clearGroupInfo:(NSString *)groupId;

- (void)clearAllGroupInfo;

#pragma mark - preload

/// Preloads user info. Uses cache first and automatically requests missing entries.
/// @param userIds User ID array.
- (void)preloadUserInfos:(NSArray<NSString *> *)userIds;

/// Preloads group member info. Uses cache first and automatically requests missing entries.
- (void)preloadGroupMembers:(NSArray<NSString *> *)userIds
                    inGroup:(NSString *)groupId;

/// Preloads group info. Uses cache first and automatically requests missing entries.
/// @param groupIds Group ID array.
- (void)preloadGroupInfos:(NSArray<NSString *> *)groupIds;

@end

NS_ASSUME_NONNULL_END
