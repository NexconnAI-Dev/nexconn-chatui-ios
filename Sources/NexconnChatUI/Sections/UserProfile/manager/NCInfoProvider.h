//
//  NCInfoProvider.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelInfoCache.h"
#import "NCChatUI.h"
#import "NCConversationUserInfoCache.h"
#import "NCUserInfoCache.h"
#import "NCUserInfoCacheDBHelper.h"
#import <Foundation/Foundation.h>

@class NCChatUIGroup;

// Message dispatch.

#define ncUserInfoWriteDBHelper ([NCInfoProvider sharedManager].writeDBHelper)
#define ncUserInfoReadDBHelper ([NCInfoProvider sharedManager].readDBHelper)
#define ncUserInfoDBQueue ([NCInfoProvider sharedManager].dbQueue)

NS_ASSUME_NONNULL_BEGIN

// Original NCUserInfoCacheManager contents.
@interface NCInfoProvider : NSObject

@property (nonatomic, strong, nullable) NCUserInfoCacheDBHelper *writeDBHelper;
@property (nonatomic, strong, nullable) NCUserInfoCacheDBHelper *readDBHelper;
@property (nonatomic, strong) dispatch_queue_t dbQueue;

+ (instancetype)sharedManager;

// appkey, token, and userId determine the DB storage path.
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *currentUserId;

#pragma mark - UserInfo

// Get from cache first. If missing, return nil and invoke the user info provider.
- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId;

// Get from cache and the user info provider.
- (void)getUserInfo:(NSString *)userId complete:(void (^)(NCChatUIUserInfo *userInfo))completeBlock;

// Get user info from the current cache only, without callbacks.
- (NCChatUIUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId;

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo forUserId:(NSString *)userId;

- (void)clearUserInfoNetworkCacheOnly:(NSString *)userId;

- (void)clearUserInfo:(NSString *)userId;

- (void)clearAllUserInfo;

#pragma mark - GroupUserInfo (sugar for ConversationUserInfo)

@property (nonatomic, assign) BOOL groupUserInfoEnabled;

- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId inGroupId:(NSString *)groupId;

- (void)getUserInfo:(NSString *)userId
          inGroupId:(NSString *)groupId
           complete:(void (^)(NCChatUIUserInfo *userInfo))completeBlock;

- (NCChatUIUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId inGroupId:(NSString *)groupId;

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo
             forUserId:(NSString *)userId
               inGroup:(NSString *)groupId;

- (void)clearGroupUserInfoNetworkCacheOnly:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearGroupUserInfo:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearAllGroupUserInfo;

#pragma mark - GroupInfo (sugar for ConversationInfo)

- (NCChatUIGroup *)getGroupInfo:(NSString *)groupId;

- (void)getGroupInfo:(NSString *)groupId complete:(void (^)(NCChatUIGroup *groupInfo))completeBlock;

- (NCChatUIGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId;

- (void)updateGroupInfo:(NCChatUIGroup *)groupInfo forGroupId:(NSString *)groupId;

- (void)clearGroupInfoNetworkCacheOnly:(NSString *)groupId;

- (void)clearGroupInfo:(NSString *)groupId;

- (void)clearAllGroupInfo;

@end

NS_ASSUME_NONNULL_END
