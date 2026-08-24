//
//  NCInfoManagement.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIGroup.h"
#import "NCChatUIUserInfo.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCInfoManagement : NSObject

+ (instancetype)sharedInstance;

#pragma mark-- userInfo

// Get from cache first. If missing, return nil and invoke the info management interface.
- (nullable NCChatUIUserInfo *)getUserInfo:(NSString *)userId;

// Get from cache only.
- (nullable NCChatUIUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId;

- (void)getUserInfo:(NSString *)userId complete:(nullable void (^)(NCChatUIUserInfo *user))complete;

/// Loads user info. Uses cache first and automatically sends network requests for missing entries.
/// @param userIds User ID array.
/// @note Sends a notification after data is updated.
- (void)loadUserInfos:(NSArray<NSString *> *)userIds;

- (void)refreshUserInfo:(NCChatUIUserInfo *)userInfo;

- (void)clearUserInfo:(NSString *)userId;

- (void)clearAllUserInfo;

#pragma mark-- groupMember

// Get from cache only.
- (nullable NCChatUIUserInfo *)getGroupMemberFromCacheOnly:(NSString *)userId
                                               withGroupId:(NSString *)groupId;

// Get from cache first. If missing, return nil and invoke the info management interface.
- (nullable NCChatUIUserInfo *)getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId;

- (void)getGroupMember:(NSString *)userId
           withGroupId:(NSString *)groupId
              complete:(nullable void (^)(NCChatUIUserInfo *_Nullable user))complete;

/// Loads group member info. Uses cache first and automatically sends network requests for missing
/// entries.
/// @param userIds User ID array.
/// @param groupId Group ID.
/// @note Sends a notification after data is updated.
- (void)preloadGroupMembers:(NSArray<NSString *> *)userIds inGroup:(NSString *)groupId;

- (void)refreshGroupMember:(NCChatUIUserInfo *)userInfo withGroupId:(NSString *)groupId;

- (void)clearGroupMember:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearAllGroupMember;

#pragma mark-- group

// Get from cache first. If missing, return nil and invoke the info management interface.
- (nullable NCChatUIGroup *)getGroupInfo:(NSString *)groupId;

// Get from cache only.
- (nullable NCChatUIGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId;

- (void)getGroupInfo:(NSString *)groupId
            complete:(nullable void (^)(NCChatUIGroup *_Nullable group))complete;

/// Loads group info. Uses cache first and automatically sends network requests for missing entries.
/// @param groupIds Group ID array.
/// @note Sends a notification after data is updated.
- (void)preloadGroupInfos:(NSArray<NSString *> *)groupIds;

- (void)refreshGroupInfo:(NCChatUIGroup *)groupInfo;

- (void)refreshGroupInfoCache:(NCChatUIGroup *)groupInfo;

- (void)clearGroupInfo:(NSString *)groupId;

- (void)clearAllGroupInfo;

- (void)updateMyUserProfile:(NCUserProfile *)profile
                    success:(void (^)(void))successBlock
                      error:(nullable void (^)(NSInteger errorCode,
                                               NSString *_Nullable errorKey))errorBlock;

- (void)updateMyUserProfile:(NCUserProfile *)profile
               successBlock:(void (^)(void))successBlock
                 errorBlock:(nullable void (^)(NSInteger errorCode,
                                               NSArray<NSString *> *_Nullable errorKeys))errorBlock;

- (void)setFriendInfo:(NSString *)userId
               remark:(nullable NSString *)remark
           extProfile:(nullable NSDictionary<NSString *, NSString *> *)extProfile
              success:(void (^)(void))successBlock
                error:(void (^)(NSInteger errorCode))errorBlock;

- (void)setFriendInfo:(NSString *)userId
               remark:(nullable NSString *)remark
           extProfile:(nullable NSDictionary<NSString *, NSString *> *)extProfile
         successBlock:(void (^)(void))successBlock
           errorBlock:
               (void (^)(NSInteger errorCode, NSArray<NSString *> *_Nullable errorKeys))errorBlock;

- (void)updateGroupInfo:(NCGroupInfo *)groupInfo
                success:(void (^)(void))successBlock
                  error:(void (^)(NSInteger errorCode, NSString *errorKey))errorBlock;

- (void)updateGroupInfo:(NCGroupInfo *)groupInfo
           successBlock:(void (^)(void))successBlock
             errorBlock:(void (^)(NSInteger errorCode,
                                  NSArray<NSString *> *_Nullable errorKeys))errorBlock;

- (void)setGroupMemberInfo:(NSString *)groupId
                    userId:(NSString *)userId
                  nickname:(nullable NSString *)nickname
                     extra:(nullable NSString *)extra
                   success:(void (^)(void))successBlock
                     error:(void (^)(NSInteger errorCode))errorBlock;

- (void)setGroupMemberInfo:(NSString *)groupId
                    userId:(NSString *)userId
                  nickname:(nullable NSString *)nickname
                     extra:(nullable NSString *)extra
              successBlock:(void (^)(void))successBlock
                errorBlock:(void (^)(NSInteger errorCode,
                                     NSArray<NSString *> *_Nullable errorKeys))errorBlock;
@end

NS_ASSUME_NONNULL_END
