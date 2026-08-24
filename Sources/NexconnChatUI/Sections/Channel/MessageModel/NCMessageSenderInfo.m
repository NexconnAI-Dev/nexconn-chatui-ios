//
//  NCMessageSenderInfo.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 27/5/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageSenderInfo.h"
#import "NCChatUIUserInfo.h"
#import "NCChatUIUtility.h"
#import "NCUserInfoCacheManager.h"

@implementation NCMessageSenderInfo

+ (instancetype)infoWithUserInfo:(NCChatUIUserInfo *)userInfo {
    NCMessageSenderInfo *info = [NCMessageSenderInfo new];
    info.userId = userInfo.userId;
    info.name = [NCChatUIUtility getDisplayName:userInfo];
    info.avatarUrl = userInfo.avatarUrl;
    info.userInfo = userInfo;
    return info;
}

@end

@interface NCMessageSenderUserInfoResolver ()

+ (NCChatUIUserInfo *)cachedUserInfoForChannelType:(NCChannelType)channelType
                                         channelId:(NSString *)channelId
                                      senderUserId:(NSString *)senderUserId;
+ (NCChatUIUserInfo *)groupUserInfoWithUserId:(NSString *)userId groupId:(NSString *)groupId;
+ (NCChatUIUserInfo *)groupDisplayUserInfoWithGroupMemberUserInfo:
                          (NCChatUIUserInfo *)groupMemberUserInfo
                                                     baseUserInfo:(NCChatUIUserInfo *)baseUserInfo
                                                           userId:(NSString *)userId;
+ (NCChatUIUserInfo *)userInfoFromSenderUserInfo:(NCUserInfo *)senderUserInfo
                                    senderUserId:(NSString *)senderUserId;

@end

@implementation NCMessageSenderUserInfoResolver

+ (NSString *)resolvedSenderUserIdWithMessageSenderUserId:(NSString *)senderUserId
                                           senderUserInfo:(NCUserInfo *)senderUserInfo {
    if (senderUserId.length > 0) {
        return senderUserId;
    }
    return senderUserInfo.userId;
}

+ (NCChatUIUserInfo *)userInfoForChannelType:(NCChannelType)channelType
                                   channelId:(NSString *)channelId
                                senderUserId:(NSString *)senderUserId
                              senderUserInfo:(NCUserInfo *)senderUserInfo {
    NSString *resolvedSenderUserId =
        [self resolvedSenderUserIdWithMessageSenderUserId:senderUserId
                                           senderUserInfo:senderUserInfo];
    NCChatUIUserInfo *userInfo = [self cachedUserInfoForChannelType:channelType
                                                          channelId:channelId
                                                       senderUserId:resolvedSenderUserId];
    if (!userInfo) {
        userInfo = [self userInfoFromSenderUserInfo:senderUserInfo
                                       senderUserId:resolvedSenderUserId];
    }
    return userInfo;
}

+ (NCChatUIUserInfo *)cachedUserInfoForChannelType:(NCChannelType)channelType
                                         channelId:(NSString *)channelId
                                      senderUserId:(NSString *)senderUserId {
    if (senderUserId.length == 0) {
        return nil;
    }
    if (channelType == NCChannelTypeGroup) {
        return [self groupUserInfoWithUserId:senderUserId groupId:channelId];
    }
    return [[NCUserInfoCacheManager sharedManager] getUserInfo:senderUserId];
}

+ (NCChatUIUserInfo *)groupUserInfoWithUserId:(NSString *)userId groupId:(NSString *)groupId {
    if (userId.length == 0 || groupId.length == 0) {
        return nil;
    }
    NCChatUIUserInfo *groupMemberUserInfo =
        [[NCUserInfoCacheManager sharedManager] getUserInfo:userId inGroupId:groupId];
    NCChatUIUserInfo *baseUserInfo = [[NCUserInfoCacheManager sharedManager] getUserInfo:userId];
    if (!groupMemberUserInfo) {
        return baseUserInfo;
    }
    return [self groupDisplayUserInfoWithGroupMemberUserInfo:groupMemberUserInfo
                                                baseUserInfo:baseUserInfo
                                                      userId:userId];
}

+ (NCChatUIUserInfo *)groupDisplayUserInfoWithGroupMemberUserInfo:
                          (NCChatUIUserInfo *)groupMemberUserInfo
                                                     baseUserInfo:(NCChatUIUserInfo *)baseUserInfo
                                                           userId:(NSString *)userId {
    NCChatUIUserInfo *displayUserInfo = [NCChatUIUserInfo new];
    NCGroupMemberInfo *groupMemberInfo = groupMemberUserInfo.memberInfo;
    if (groupMemberInfo) {
        displayUserInfo.memberInfo = groupMemberInfo;
        displayUserInfo.name = groupMemberInfo.name;
        displayUserInfo.alias =
            baseUserInfo.alias.length > 0 ? baseUserInfo.alias : groupMemberInfo.nickname;
    } else {
        displayUserInfo.userId = groupMemberUserInfo.userId;
        displayUserInfo.name = groupMemberUserInfo.name;
        displayUserInfo.alias =
            baseUserInfo.alias.length > 0 ? baseUserInfo.alias : groupMemberUserInfo.alias;
        displayUserInfo.avatarUrl = groupMemberUserInfo.avatarUrl;
        displayUserInfo.extra = groupMemberUserInfo.extra;
    }
    if (displayUserInfo.userId.length == 0) {
        displayUserInfo.userId =
            groupMemberUserInfo.userId.length > 0 ? groupMemberUserInfo.userId : userId;
    }
    if (displayUserInfo.name.length == 0) {
        displayUserInfo.name =
            groupMemberUserInfo.name.length > 0 ? groupMemberUserInfo.name : baseUserInfo.name;
    }
    if (displayUserInfo.alias.length == 0) {
        displayUserInfo.alias =
            groupMemberUserInfo.alias.length > 0 ? groupMemberUserInfo.alias : baseUserInfo.alias;
    }
    if (displayUserInfo.avatarUrl.length == 0) {
        displayUserInfo.avatarUrl = groupMemberUserInfo.avatarUrl.length > 0
                                        ? groupMemberUserInfo.avatarUrl
                                        : baseUserInfo.avatarUrl;
    }
    if (displayUserInfo.extra.length == 0) {
        displayUserInfo.extra =
            groupMemberUserInfo.extra.length > 0 ? groupMemberUserInfo.extra : baseUserInfo.extra;
    }
    return displayUserInfo;
}

+ (NCChatUIUserInfo *)userInfoFromSenderUserInfo:(NCUserInfo *)senderUserInfo
                                    senderUserId:(NSString *)senderUserId {
    if (!senderUserInfo) {
        return nil;
    }
    if (senderUserId.length > 0 && senderUserInfo.userId.length > 0 &&
        ![senderUserId isEqualToString:senderUserInfo.userId]) {
        return nil;
    }
    NCChatUIUserInfo *userInfo = [NCChatUIUserInfo new];
    userInfo.userId = senderUserInfo.userId;
    userInfo.name = senderUserInfo.name;
    userInfo.avatarUrl = senderUserInfo.portraitUri;
    userInfo.alias = senderUserInfo.alias;
    userInfo.extra = senderUserInfo.extra;
    return userInfo;
}

@end
