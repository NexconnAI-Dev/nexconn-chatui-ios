//
//  NCInfoProvider.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCInfoProvider.h"
#import "NCChatUILog.h"
#import "NCUserInfoCacheManager.h"
#import "NCInfoUpdateCenter.h"
#import "NCChatUIUserInfo.h"
#import "NCChatUIGroup.h"

@interface NCInfoProvider () <NCUserInfoUpdateDelegate, NCChannelUserInfoUpdateDelegate,
                                      NCChannelInfoUpdateDelegate>

@property (nonatomic, strong) dispatch_queue_t requestQueue;

@end

@implementation NCInfoProvider

+ (instancetype)sharedManager {
    static NCInfoProvider *defaultManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!defaultManager) {
            defaultManager = [[NCInfoProvider alloc] init];
            defaultManager.groupUserInfoEnabled = NO;
            defaultManager.requestQueue = dispatch_queue_create("ai.nexconn.userInfoRequsetQueue", NULL);
            defaultManager.dbQueue = dispatch_queue_create("ai.nexconn.userInfoDBQueue", NULL);
            [NCUserInfoCache sharedCache].updateDelegate = defaultManager;
            [NCConversationUserInfoCache sharedCache].updateDelegate = defaultManager;
            [NCChannelInfoCache sharedCache].updateDelegate = defaultManager;
        }
    });
    return defaultManager;
}

- (void)setCurrentUserId:(NSString *)currentUserId {
    if ([NCChatUI shared].enablePersistentUserInfoCache && ![currentUserId isEqualToString:_currentUserId]) {
        dispatch_async(self.dbQueue, ^{
            NSString *libraryPath =
                NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
            libraryPath = [[[libraryPath stringByAppendingPathComponent:@"Nexconn"]
                stringByAppendingPathComponent:self.appKey] stringByAppendingPathComponent:currentUserId];
            if (![[NSFileManager defaultManager] fileExistsAtPath:libraryPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:libraryPath
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:nil];
            }
            NSString *libraryStoragePath = [libraryPath stringByAppendingPathComponent:@"ChatUIUserInfoCache"];
            if (self.writeDBHelper) {
                [self.writeDBHelper closeDBIfNeed];
                self.writeDBHelper = nil;
            }
            self.writeDBHelper = [[NCUserInfoCacheDBHelper alloc] initWithPath:libraryStoragePath];

            if (self.readDBHelper) {
                [self.readDBHelper closeDBIfNeed];
                self.readDBHelper = nil;
            }
            self.readDBHelper = [[NCUserInfoCacheDBHelper alloc] initWithPath:libraryStoragePath];
        });
    }

    _currentUserId = [currentUserId copy];
}

- (void)dealloc {
    [self.writeDBHelper closeDBIfNeed];
    self.writeDBHelper = nil;
    [self.readDBHelper closeDBIfNeed];
    self.readDBHelper = nil;
}

#pragma mark - UserInfo
- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId {
    if (userId) {
        NCChatUIUserInfo *cacheUserInfo = [[NCUserInfoCache sharedCache] getUserInfo:userId];
        if (!cacheUserInfo) {
            if (![NCChatUI shared].userInfoDataSource) {
                NCLogReleaseW(@"User info provider is nil. Set [NCChatUI shared].userInfoDataSource "
                      @"and retain the assigned object because [NCChatUI shared].userInfoDataSource is a weak "
                      @"property...................");
                return nil;
            }
            if ([NCChatUI shared].userInfoDataSource &&
                [[NCChatUI shared]
                        .userInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:completion:)]) {
                dispatch_async(self.requestQueue, ^{
                    [[NCChatUI shared]
                            .userInfoDataSource
                        getUserInfoWithUserId:userId
                                   completion:^(NCChatUIUserInfo *userInfo) {
                                       if (userInfo == nil || userInfo.name.length == 0) {
                                           NCLogE(@"getUserInfo:error;;;getUserInfoDataSource:userId=%@", userId);
                                       }
                                       [self updateUserInfo:userInfo forUserId:userId];
                                   }];
                });
            }
        }
        return cacheUserInfo;
    } else {
        NCLogE(@"getUserInfo:error;;;useId is nil");
        return nil;
    }
}

- (void)getUserInfo:(NSString *)userId complete:(void (^)(NCChatUIUserInfo *userInfo))completeBlock {
    if (userId) {
        NCChatUIUserInfo *cacheUserInfo = [[NCUserInfoCache sharedCache] getUserInfo:userId];
        if (cacheUserInfo) {
            if (completeBlock) {
                completeBlock(cacheUserInfo);
            }
        } else if ([NCChatUI shared].userInfoDataSource &&
                   [[NCChatUI shared]
                           .userInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:completion:)]) {
            dispatch_async(self.requestQueue, ^{
                [[NCChatUI shared]
                        .userInfoDataSource getUserInfoWithUserId:userId
                                                       completion:^(NCChatUIUserInfo *userInfo) {
                                                           [self updateUserInfo:userInfo forUserId:userId];
                                                                if (completeBlock) {
                                                                    completeBlock(userInfo);
                                                                }
                                                       }];
            });
        } else {
            if (completeBlock) {
                completeBlock(nil);
            }
        }
    } else {
        if (completeBlock) {
            completeBlock(nil);
        }
    }
}

- (NCChatUIUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId {
    if (userId) {
        return [[NCUserInfoCache sharedCache] getUserInfo:userId];
    } else {
        return nil;
    }
}

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo forUserId:(NSString *)userId {
    if (userId.length > 0 && !userInfo){
        [[NCUserInfoCache sharedCache] clearUserInfo:userId];
        return;
    }
    
    if (userId && userInfo) {
        [[NCUserInfoCache sharedCache] updateUserInfo:userInfo forUserId:userId];
    } else if (!userId && userInfo.userId) {
        [[NCUserInfoCache sharedCache] updateUserInfo:userInfo forUserId:userInfo.userId];
    }
}

- (void)clearUserInfoNetworkCacheOnly:(NSString *)userId {
    if (userId) {
        [[NCUserInfoCache sharedCache] clearUserInfoNetworkCacheOnly:userId];
    }
}

- (void)clearUserInfo:(NSString *)userId {
    if (userId) {
        [[NCUserInfoCache sharedCache] clearUserInfo:userId];
    }
}

- (void)clearAllUserInfo {
    [[NCUserInfoCache sharedCache] clearAllUserInfo];
}

#pragma mark - GroupUserInfo (sugar for ConversationUserInfo)

- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId inGroupId:(NSString *)groupId {
    if (!self.groupUserInfoEnabled) {
        return [self getUserInfo:userId];
    }

    if (userId && groupId) {
        NCChatUIUserInfo *cacheUserInfo = [[NCConversationUserInfoCache sharedCache] getUserInfo:userId
                                                                                 channelType:NCChannelTypeGroup
                                                                                         channelId:groupId];
        if (!cacheUserInfo && [NCChatUI shared].groupUserInfoDataSource &&
            [[NCChatUI shared]
                    .groupUserInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:inGroup:completion:)]) {
            dispatch_async(self.requestQueue, ^{
                [[NCChatUI shared]
                        .groupUserInfoDataSource
                    getUserInfoWithUserId:userId
                                  inGroup:groupId
                               completion:^(NCChatUIUserInfo *userInfo) {
                                   if (!userInfo) {
                                       userInfo = [NCChatUIUserInfo new];
                                       userInfo.userId = userId;
                                       NCLogE(@"getUserInfo:inGroupId: "
                                              @"error;;;groupUserInfoDataSource;;;groupId=%@;;;userInfo:userId=%@",
                                              groupId, userId);
                                   }
                                   [self updateUserInfo:userInfo forUserId:userId inGroup:groupId];
                               }];
            });
        }
        NCChatUIUserInfo *userInfo = [self fallBackOrdinaryUserInfo:cacheUserInfo forUserId:userId];
        if (userInfo == nil || userInfo.name.length == 0) {
            NCLogE(
                @"getUserInfo:inGroupId: error;;;groupId=%@;;;cacheUserInfo:userId=%@,userName=%@,userPortraitUri=%@",
                groupId, userInfo.userId, userInfo.name, userInfo.avatarUrl);
        }
        return userInfo;
    } else {
        NCLogE(@"getUserInfo:inGroupId:error;;;useId or groupId is nil");
        return nil;
    }
}

- (void)getUserInfo:(NSString *)userId
          inGroupId:(NSString *)groupId
           complete:(void (^)(NCChatUIUserInfo *userInfo))completeBlock {
    if (!self.groupUserInfoEnabled) {
        [self getUserInfo:userId
                 complete:^(NCChatUIUserInfo *userInfo) {
                     if (completeBlock) {
                         completeBlock(userInfo);
                     }
                 }];
    }

    if (userId && groupId) {
        NCChatUIUserInfo *cacheUserInfo = [[NCConversationUserInfoCache sharedCache] getUserInfo:userId
                                                                                 channelType:NCChannelTypeGroup
                                                                                         channelId:groupId];
        if (cacheUserInfo) {
            [self fallBackOrdinaryUserInfo:cacheUserInfo
                                 forUserId:userId
                                  complete:^(NCChatUIUserInfo *userInfo) {
                                      if (completeBlock) {
                                          completeBlock(cacheUserInfo);
                                      }
                                  }];
        } else if ([NCChatUI shared].groupUserInfoDataSource &&
                   [[NCChatUI shared]
                           .groupUserInfoDataSource
                       respondsToSelector:@selector(getUserInfoWithUserId:inGroup:completion:)]) {
            dispatch_async(self.requestQueue, ^{
                [[NCChatUI shared]
                        .groupUserInfoDataSource
                    getUserInfoWithUserId:userId
                                  inGroup:groupId
                               completion:^(NCChatUIUserInfo *userInfo) {
                                   if (!userInfo) {
                                       userInfo = [NCChatUIUserInfo new];
                                       userInfo.userId = userId;
                                   }
                                   [self updateUserInfo:userInfo forUserId:userId inGroup:groupId];
                                   [self fallBackOrdinaryUserInfo:userInfo
                                                            forUserId:userId
                                                             complete:^(NCChatUIUserInfo *userInfo) {
                                                                 if (completeBlock) {
                                                                     completeBlock(userInfo);
                                                                 }
                                                             }];
                               }];
            });
        } else {
            [self getUserInfo:userId
                     complete:^(NCChatUIUserInfo *userInfo) {
                        if (completeBlock) {
                            completeBlock(userInfo);
                        }
                     }];
        }
    } else {
        if (completeBlock) {
            completeBlock(nil);
        }
    }
}

- (NCChatUIUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId inGroupId:(NSString *)groupId {
    if (!self.groupUserInfoEnabled) {
        return [self getUserInfoFromCacheOnly:userId];
    }

    if (userId && groupId) {
        NCChatUIUserInfo *cacheUserInfo = [[NCConversationUserInfoCache sharedCache] getUserInfo:userId
                                                                                 channelType:NCChannelTypeGroup
                                                                                         channelId:groupId];
        return [self fallBackOrdinaryUserInfoFromCacheOnly:cacheUserInfo forUserId:userId];
    } else {
        return nil;
    }
}

// Synchronous fallback.
- (NCChatUIUserInfo *)fallBackOrdinaryUserInfo:(NCChatUIUserInfo *)tempUserInfo forUserId:(NSString *)userId {
    if (!tempUserInfo) {
        return [self getUserInfo:userId];
    }

    if ([tempUserInfo.name length] <= 0 || [tempUserInfo.avatarUrl length] <= 0) {
        NCChatUIUserInfo *ordinaryUserInfo = [self getUserInfo:userId];
        if ([tempUserInfo.name length] <= 0) {
            tempUserInfo.name = ordinaryUserInfo.name;
        }
        if ([tempUserInfo.avatarUrl length] <= 0) {
            tempUserInfo.avatarUrl = ordinaryUserInfo.avatarUrl;
        }
    }
    return tempUserInfo;
}

- (NCChatUIUserInfo *)fallBackOrdinaryUserInfoFromCacheOnly:(NCChatUIUserInfo *)tempUserInfo forUserId:(NSString *)userId {
    if (!tempUserInfo) {
        return [self getUserInfoFromCacheOnly:userId];
    }

    if ([tempUserInfo.name length] <= 0 || [tempUserInfo.avatarUrl length] <= 0) {
        NCChatUIUserInfo *ordinaryUserInfo = [self getUserInfo:userId];
        if ([tempUserInfo.name length] <= 0) {
            tempUserInfo.name = ordinaryUserInfo.name;
        }
        if ([tempUserInfo.avatarUrl length] <= 0) {
            tempUserInfo.avatarUrl = ordinaryUserInfo.avatarUrl;
        }
    }
    return tempUserInfo;
}

// Asynchronous fallback.
- (void)fallBackOrdinaryUserInfo:(NCChatUIUserInfo *)tempUserInfo
                       forUserId:(NSString *)userId
                        complete:(void (^)(NCChatUIUserInfo *userInfo))completeBlock {
    if (!tempUserInfo) {
        [self getUserInfo:userId
                 complete:^(NCChatUIUserInfo *userInfo) {
                    if (completeBlock) {
                        completeBlock(userInfo);
                    }
                     
                 }];
    }

    if (!tempUserInfo.name || !tempUserInfo.avatarUrl) {
        [self getUserInfo:userId
                 complete:^(NCChatUIUserInfo *userInfo) {
                     if (!tempUserInfo.name) {
                         tempUserInfo.name = userInfo.name;
                     }
                     if (!tempUserInfo.avatarUrl) {
                         tempUserInfo.avatarUrl = userInfo.avatarUrl;
                     }
                    if (completeBlock) {
                        completeBlock(tempUserInfo);
                    }
                     
                 }];
    }
}

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo forUserId:(NSString *)userId inGroup:(NSString *)groupId {
    if (groupId) {
        if (userId.length > 0 && !userInfo){
            [[NCConversationUserInfoCache sharedCache] clearConversationUserInfo:userId channelType:NCChannelTypeGroup channelId:groupId];
            return;
        }

        if (userId && userInfo) {
            [[NCConversationUserInfoCache sharedCache] updateUserInfo:userInfo
                                                            forUserId:userId
                                                     channelType:NCChannelTypeGroup
                                                             channelId:groupId];
        } else if (!userId && userInfo.userId) {
            [[NCConversationUserInfoCache sharedCache] updateUserInfo:userInfo
                                                            forUserId:userInfo.userId
                                                     channelType:NCChannelTypeGroup
                                                             channelId:groupId];
        }
    }
}

- (void)clearGroupUserInfoNetworkCacheOnly:(NSString *)userId inGroup:(NSString *)groupId {
    if (userId && groupId) {
        [[NCConversationUserInfoCache sharedCache] clearConversationUserInfoNetworkCacheOnly:userId
                                                                            channelType:NCChannelTypeGroup
                                                                                    channelId:groupId];
    }
}

- (void)clearGroupUserInfo:(NSString *)userId inGroup:(NSString *)groupId {
    if (userId && groupId) {
        [[NCConversationUserInfoCache sharedCache] clearConversationUserInfo:userId
                                                            channelType:NCChannelTypeGroup
                                                                    channelId:groupId];
    }
}

- (void)clearAllGroupUserInfo {
    [[NCConversationUserInfoCache sharedCache] clearAllConversationUserInfo];
}

#pragma mark - GroupInfo (sugar for ConversationInfo)

- (NCChatUIGroup *)getGroupInfo:(NSString *)groupId {
    if (groupId) {
        NCChannelInfo *cacheConversationInfo =
            [[NCChannelInfoCache sharedCache] getConversationInfo:NCChannelTypeGroup channelId:groupId];
        if (!cacheConversationInfo && [NCChatUI shared].groupInfoDataSource &&
            [[NCChatUI shared].groupInfoDataSource respondsToSelector:@selector(getGroupInfoWithGroupId:completion:)]) {
            dispatch_async(self.requestQueue, ^{
                [[NCChatUI shared]
                        .groupInfoDataSource
                    getGroupInfoWithGroupId:groupId
                                 completion:^(NCChatUIGroup *groupInfo) {
                                     NCLogI(@"getUserInfo:;;;getGroupInfoDataSource:groupId=%@,groupName=%@,"
                                            @"groupPortraitUri=%@,extra=%@",
                                            groupInfo.groupId, groupInfo.groupName, groupInfo.avatarUrl, groupInfo.extra);
                                     [self updateGroupInfo:groupInfo forGroupId:groupId];
                                 }];
            });
        }
        NCChatUIGroup *groupInfo = [cacheConversationInfo translateToGroupInfo];
        NCLogI(@"getGroupInfo:;;;cacheGroupInfo:groupId=%@,groupName=%@,groupPortraitUri=%@,extra=%@", groupInfo.groupId,
               groupInfo.groupName, groupInfo.avatarUrl, groupInfo.extra);
        return groupInfo;
    } else {
        NCLogI(@"getGroupInfo:;;;groupId = nil");
        return nil;
    }
}

- (void)getGroupInfo:(NSString *)groupId complete:(void (^)(NCChatUIGroup *groupInfo))completeBlock {
    if (groupId) {
        NCChannelInfo *cacheConversationInfo =
            [[NCChannelInfoCache sharedCache] getConversationInfo:NCChannelTypeGroup channelId:groupId];
        if (cacheConversationInfo) {
            if (completeBlock) {
                completeBlock([cacheConversationInfo translateToGroupInfo]);
            }
        } else if ([NCChatUI shared].groupInfoDataSource &&
                   [[NCChatUI shared]
                           .groupInfoDataSource respondsToSelector:@selector(getGroupInfoWithGroupId:completion:)]) {
            dispatch_async(self.requestQueue, ^{
                [[NCChatUI shared]
                        .groupInfoDataSource getGroupInfoWithGroupId:groupId
                                                          completion:^(NCChatUIGroup *groupInfo) {
                                                              [self updateGroupInfo:groupInfo
                                                                         forGroupId:groupId];
                                                              if (completeBlock) {
                                                                  completeBlock(groupInfo);
                                                              }
                                                              
                                                          }];
            });
        } else {
            if (completeBlock) {
                completeBlock(nil);
            }
        }
    } else {
        if (completeBlock) {
            completeBlock(nil);
        }
        
    }
}

- (NCChatUIGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId {
    if (groupId) {
        NCChannelInfo *cacheConversationInfo =
            [[NCChannelInfoCache sharedCache] getConversationInfo:NCChannelTypeGroup channelId:groupId];
        return [cacheConversationInfo translateToGroupInfo];
    } else {
        return nil;
    }
}

- (void)updateGroupInfo:(NCChatUIGroup *)groupInfo forGroupId:(NSString *)groupId {
    if (groupId.length > 0 && !groupInfo){
        [[NCChannelInfoCache sharedCache] clearConversationInfo:NCChannelTypeGroup channelId:groupId];
        return;
    }
    if (groupId && groupInfo) {
        [[NCChannelInfoCache sharedCache]
            updateConversationInfo:[[NCChannelInfo alloc] initWithGroupInfo:groupInfo]
                  channelType:NCChannelTypeGroup
                          channelId:groupId];
    } else if (!groupId && groupInfo.groupId) {
        [[NCChannelInfoCache sharedCache]
            updateConversationInfo:[[NCChannelInfo alloc] initWithGroupInfo:groupInfo]
                  channelType:NCChannelTypeGroup
                          channelId:groupInfo.groupId];
    }
}

- (void)clearGroupInfoNetworkCacheOnly:(NSString *)groupId {
    if (groupId) {
        [[NCChannelInfoCache sharedCache] clearConversationInfoNetworkCacheOnly:NCChannelTypeGroup
                                                                            channelId:groupId];
    }
}

- (void)clearGroupInfo:(NSString *)groupId {
    if (groupId) {
        [[NCChannelInfoCache sharedCache] clearConversationInfo:NCChannelTypeGroup channelId:groupId];
    }
}

- (void)clearAllGroupInfo {
    [[NCChannelInfoCache sharedCache] clearAllConversationInfo];
}

#pragma mark - Post Notification
- (void)onUserInfoUpdate:(NCChatUIUserInfo *)userInfo {
    if (userInfo.userId) {
        [NCInfoUpdateCenter dispatchUserInfoUpdate:userInfo];
    }
}

- (void)onConversationUserInfoUpdate:(NCChatUIUserInfo *)userInfo
                      inConversation:(NCChannelType)channelType
                            channelId:(NSString *)channelId {
    if (channelType == NCChannelTypeGroup && userInfo.userId) {
        [NCInfoUpdateCenter dispatchGroupMemberInfoUpdate:userInfo groupId:channelId];
    }
}

- (void)onConversationInfoUpdate:(NCChannelInfo *)conversationInfo {
    if (conversationInfo.channelType == NCChannelTypeGroup && conversationInfo.channelId) {
        NCChatUIGroup *groupInfo = [conversationInfo translateToGroupInfo];
        [NCInfoUpdateCenter dispatchGroupInfoUpdate:groupInfo];
    }
}

@end
