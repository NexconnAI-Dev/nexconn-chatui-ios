//
//  NCUserInfoCacheManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUserInfoCacheManager.h"
#import "NCChatUIGroup.h"
#import "NCChatUIUserInfo.h"
#import "NCInfoManagement.h"
#import "NCInfoProvider.h"

@interface NCUserInfoCacheManager ()

@end

@implementation NCUserInfoCacheManager

+ (instancetype)sharedManager {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - UserInfo

// Return the cached value when available. On a miss, return nil and request it from the user info
// provider.
- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        return [[NCInfoManagement sharedInstance] getUserInfo:userId];
    } else {
        return [[NCInfoProvider sharedManager] getUserInfo:userId];
    }
}

// Resolve the value from the cache or the user info provider.
- (void)getUserInfo:(NSString *)userId
           complete:(void (^)(NCChatUIUserInfo *userInfo))completeBlock {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] getUserInfo:userId complete:completeBlock];
    } else {
        [[NCInfoProvider sharedManager] getUserInfo:userId complete:completeBlock];
    }
}

// Return user info from the current cache without invoking the provider.
- (NCChatUIUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        return [[NCInfoManagement sharedInstance] getUserInfoFromCacheOnly:userId];
    } else {
        return [[NCInfoProvider sharedManager] getUserInfoFromCacheOnly:userId];
    }
}

// This cache-only path avoids overloading the hosted user-info provider.
- (void)preloadUserInfos:(NSArray<NSString *> *)userIds {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] loadUserInfos:userIds];
    }
}

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo forUserId:(NSString *)userId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] refreshUserInfo:userInfo];
    } else {
        [[NCInfoProvider sharedManager] updateUserInfo:userInfo forUserId:userId];
    }
}

- (void)clearUserInfo:(NSString *)userId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] clearUserInfo:userId];
    } else {
        [[NCInfoProvider sharedManager] clearUserInfo:userId];
    }
}

- (void)clearAllUserInfo {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] clearAllUserInfo];
    } else {
        [[NCInfoProvider sharedManager] clearAllUserInfo];
    }
}

#pragma mark - GroupUserInfo (sugar for ConversationUserInfo)

- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId inGroupId:(NSString *)groupId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        return [[NCInfoManagement sharedInstance] getGroupMember:userId withGroupId:groupId];
    } else {
        return [[NCInfoProvider sharedManager] getUserInfo:userId inGroupId:groupId];
    }
}

- (void)getUserInfo:(NSString *)userId
          inGroupId:(NSString *)groupId
           complete:(void (^)(NCChatUIUserInfo *userInfo))completeBlock {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] getGroupMember:userId
                                              withGroupId:groupId
                                                 complete:completeBlock];
    } else {
        [[NCInfoProvider sharedManager] getUserInfo:userId
                                          inGroupId:groupId
                                           complete:completeBlock];
    }
}

- (NCChatUIUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId inGroupId:(NSString *)groupId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        return [[NCInfoManagement sharedInstance] getGroupMemberFromCacheOnly:userId
                                                                  withGroupId:groupId];
    } else {
        return [[NCInfoProvider sharedManager] getUserInfoFromCacheOnly:userId inGroupId:groupId];
    }
}

// This cache-only path avoids overloading the hosted user-info provider.
- (void)preloadGroupMembers:(NSArray<NSString *> *)userIds inGroup:(NSString *)groupId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] preloadGroupMembers:userIds inGroup:groupId];
    }
}

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo
             forUserId:(NSString *)userId
               inGroup:(NSString *)groupId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] refreshGroupMember:userInfo withGroupId:groupId];
    } else {
        [[NCInfoProvider sharedManager] updateUserInfo:userInfo forUserId:userId inGroup:groupId];
    }
}

- (void)clearGroupUserInfo:(NSString *)userId inGroup:(NSString *)groupId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] clearGroupMember:userId inGroup:groupId];
    } else {
        [[NCInfoProvider sharedManager] clearGroupUserInfo:userId inGroup:groupId];
    }
}

- (void)clearAllGroupUserInfo {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] clearAllGroupMember];
    } else {
        [[NCInfoProvider sharedManager] clearAllGroupUserInfo];
    }
}

#pragma mark - GroupInfo (sugar for ConversationInfo)

- (NCChatUIGroup *)getGroupInfo:(NSString *)groupId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        return [[NCInfoManagement sharedInstance] getGroupInfo:groupId];
    } else {
        return [[NCInfoProvider sharedManager] getGroupInfo:groupId];
    }
}

- (void)getGroupInfo:(NSString *)groupId
            complete:(void (^)(NCChatUIGroup *groupInfo))completeBlock {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] getGroupInfo:groupId complete:completeBlock];
    } else {
        [[NCInfoProvider sharedManager] getGroupInfo:groupId complete:completeBlock];
    }
}

- (NCChatUIGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        return [[NCInfoManagement sharedInstance] getGroupInfoFromCacheOnly:groupId];
    } else {
        return [[NCInfoProvider sharedManager] getGroupInfoFromCacheOnly:groupId];
    }
}

// This cache-only path avoids overloading the hosted user-info provider.
- (void)preloadGroupInfos:(NSArray<NSString *> *)groupIds {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] preloadGroupInfos:groupIds];
    }
}

- (void)updateGroupInfo:(NCChatUIGroup *)groupInfo {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] refreshGroupInfoCache:groupInfo];
    } else {
        [[NCInfoProvider sharedManager] updateGroupInfo:groupInfo forGroupId:nil];
    }
}

- (void)clearGroupInfo:(NSString *)groupId {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] clearGroupInfo:groupId];
    } else {
        [[NCInfoProvider sharedManager] clearGroupInfo:groupId];
    }
}

- (void)clearAllGroupInfo {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] clearAllGroupInfo];
    } else {
        [[NCInfoProvider sharedManager] clearAllGroupInfo];
    }
}

@end
