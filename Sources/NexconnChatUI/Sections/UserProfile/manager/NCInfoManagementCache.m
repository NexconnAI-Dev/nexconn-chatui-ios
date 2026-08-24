//
//  NCInfoManagementCache.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCInfoManagementCache.h"
#import "NCChatUIGroup.h"
#import "NCChatUIUserInfo.h"
#import "NCReadWriteLock.h"
#import "NCThreadSafeMutableDictionary.h"
#import "NSMutableArray+NCOperation.h"
#import "NSMutableDictionary+NCOperation.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

#define NCInfoManagementCacheMaxSize 1000

@interface NCInfoManagementCache ()

@property (nonatomic, strong) NCThreadSafeMutableDictionary *userCache;

@property (nonatomic, strong) NSMutableArray *cacheUserIds;

@property (nonatomic, strong) NCReadWriteLock *userThreadLock;

@property (nonatomic, strong) NCThreadSafeMutableDictionary *groupCache;

@property (nonatomic, strong) NSMutableArray *cacheGroupIds;

@property (nonatomic, strong) NCReadWriteLock *groupThreadLock;

@property (nonatomic, strong) NCThreadSafeMutableDictionary *memberCache;

@property (nonatomic, strong) NSMutableArray *cacheMemberIds;

@property (nonatomic, strong) NCReadWriteLock *memberThreadLock;

@end

@implementation NCInfoManagementCache

#pragma mark-- user

- (NCChatUIUserInfo *)getUserCache:(NSString *)userId {
    NCChatUIUserInfo *info = [self.userCache objectForKey:userId];
    if (!info) {
        return nil;
    }
    return [self copyUserInfo:info];
}

- (void)cacheUser:(NCChatUIUserInfo *)useInfo {
    NCChatUIUserInfo *copyInfo = [self copyUserInfo:useInfo];
    if (copyInfo.userId.length == 0) {
        return;
    }
    [self.userCache nc_setObject:copyInfo forKey:copyInfo.userId];
    [self.userThreadLock performWriteLockBlock:^{
      if ([self.cacheUserIds containsObject:copyInfo.userId]) {
          return;
      }
      [self.cacheUserIds nc_addObject:copyInfo.userId];
      if (self.cacheUserIds.count > NCInfoManagementCacheMaxSize) {
          NSString *userId = self.cacheUserIds.firstObject;
          [self.cacheUserIds removeObject:userId];
          [self.userCache nc_removeObjectForKey:userId];
      }
    }];
}

- (void)removeUserCache:(NSString *)userId {
    [self.userCache nc_removeObjectForKey:userId];
    [self.userThreadLock performWriteLockBlock:^{
      [self.cacheUserIds removeObject:userId];
    }];
}

- (void)removeAllUserCache {
    [self.userCache removeAllObjects];
    [self.userThreadLock performWriteLockBlock:^{
      [self.cacheUserIds removeAllObjects];
    }];
}

#pragma mark-- group

- (NCChatUIGroup *)getGroupCache:(NSString *)groupId {
    NCChatUIGroup *info = [self.groupCache objectForKey:groupId];
    if (!info) {
        return nil;
    }
    return [self copyGroup:info];
}

- (void)cacheGroup:(NCChatUIGroup *)group {
    NCChatUIGroup *copyInfo = [self copyGroup:group];
    if (copyInfo.groupId.length == 0) {
        return;
    }
    [self.groupCache nc_setObject:copyInfo forKey:copyInfo.groupId];
    [self.groupThreadLock performWriteLockBlock:^{
      if ([self.cacheGroupIds containsObject:copyInfo.groupId]) {
          return;
      }
      [self.cacheGroupIds nc_addObject:copyInfo.groupId];
      if (self.cacheGroupIds.count > NCInfoManagementCacheMaxSize) {
          NSString *groupId = self.cacheGroupIds.firstObject;
          [self.cacheGroupIds removeObject:groupId];
          [self.groupCache nc_removeObjectForKey:groupId];
      }
    }];
}

- (void)removeGroupCache:(NSString *)groupId {
    [self.groupCache nc_removeObjectForKey:groupId];
    [self.groupThreadLock performWriteLockBlock:^{
      [self.cacheGroupIds removeObject:groupId];
    }];
}

- (void)removeAllGroupCache {
    [self.groupCache removeAllObjects];
    [self.groupThreadLock performWriteLockBlock:^{
      [self.cacheGroupIds removeAllObjects];
    }];
}

- (NCChatUIUserInfo *)getGroupMemberCache:(NSString *)userId groupId:(NSString *)groupId {
    NSString *key = [self groupMemberCacheKeyWithUserId:userId groupId:groupId];
    if (key.length == 0) {
        return nil;
    }
    NCChatUIUserInfo *info = [self.memberCache objectForKey:key];
    if (!info) {
        return nil;
    }
    return [self copyUserInfo:info];
}

- (void)cacheGroupMember:(NCChatUIUserInfo *)member groupId:(NSString *)groupId {
    NCChatUIUserInfo *copyInfo = [self copyUserInfo:member];
    NSString *key = [self groupMemberCacheKeyWithUserId:copyInfo.userId groupId:groupId];
    if (key.length == 0) {
        return;
    }
    [self.memberCache nc_setObject:copyInfo forKey:key];
    [self.memberThreadLock performWriteLockBlock:^{
      if ([self.cacheMemberIds containsObject:key]) {
          return;
      }
      [self.cacheMemberIds nc_addObject:key];
      if (self.cacheMemberIds.count > NCInfoManagementCacheMaxSize) {
          NSString *value = self.cacheMemberIds.firstObject;
          [self.cacheMemberIds removeObject:value];
          [self.memberCache nc_removeObjectForKey:value];
      }
    }];
}

- (void)removeGroupMemberCache:(NSString *)userId groupId:(NSString *)groupId {
    NSString *key = [self groupMemberCacheKeyWithUserId:userId groupId:groupId];
    if (key.length == 0) {
        return;
    }
    [self.memberCache nc_removeObjectForKey:key];
    [self.memberThreadLock performWriteLockBlock:^{
      [self.cacheMemberIds removeObject:key];
    }];
}

- (void)removeGroupMemberCacheForGroupId:(NSString *)groupId {
    if (groupId.length == 0) {
        return;
    }
    NSString *prefix = [NSString stringWithFormat:@"%@_", groupId];
    [self.memberThreadLock performWriteLockBlock:^{
      NSMutableArray<NSString *> *keysToRemove = [NSMutableArray array];
      for (NSString *key in self.cacheMemberIds) {
          if ([key hasPrefix:prefix]) {
              [keysToRemove nc_addObject:key];
          }
      }
      for (NSString *key in keysToRemove) {
          [self.memberCache nc_removeObjectForKey:key];
      }
      [self.cacheMemberIds removeObjectsInArray:keysToRemove];
    }];
}

- (void)removeAllGroupMemberCache {
    [self.memberCache removeAllObjects];
    [self.memberThreadLock performWriteLockBlock:^{
      [self.cacheMemberIds removeAllObjects];
    }];
}

#pragma mark-- private

- (NCUserProfile *)copyProfile:(NCUserProfile *)profile {
    if (!profile) {
        return nil;
    }
    NCUserProfile *copyProfile = [NCUserProfile new];
    copyProfile.userId = profile.userId;
    if (profile.extProfile.count > 0) {
        copyProfile.extProfile = [NSDictionary dictionaryWithDictionary:profile.extProfile];
    }
    copyProfile.name = profile.name;
    copyProfile.avatarUrl = profile.avatarUrl;
    copyProfile.uniqueId = profile.uniqueId;
    copyProfile.email = profile.email;
    copyProfile.birthday = profile.birthday;
    copyProfile.gender = profile.gender;
    copyProfile.location = profile.location;
    copyProfile.role = profile.role;
    copyProfile.level = profile.level;
    return copyProfile;
}

- (NCFriendInfo *)copyFriendInfo:(NCFriendInfo *)friendInfo {
    if (!friendInfo) {
        return nil;
    }
    NCFriendInfo *copyFriendInfo = [NCFriendInfo new];
    copyFriendInfo.userId = friendInfo.userId;
    copyFriendInfo.name = friendInfo.name;
    copyFriendInfo.avatarUrl = friendInfo.avatarUrl;
    copyFriendInfo.remark = friendInfo.remark;
    copyFriendInfo.extProfile = friendInfo.extProfile.count > 0
                                    ? [NSDictionary dictionaryWithDictionary:friendInfo.extProfile]
                                    : @{};
    return copyFriendInfo;
}

- (NCGroupMemberInfo *)copyMemberInfo:(NCGroupMemberInfo *)memberInfo {
    if (!memberInfo) {
        return nil;
    }
    NCGroupMemberInfo *copyMemberInfo = [NCGroupMemberInfo new];
    copyMemberInfo.userId = memberInfo.userId;
    copyMemberInfo.avatarUrl = memberInfo.avatarUrl;
    copyMemberInfo.name = memberInfo.name;
    copyMemberInfo.nickname = memberInfo.nickname;
    copyMemberInfo.extra = memberInfo.extra;
    copyMemberInfo.joinedTime = memberInfo.joinedTime;
    copyMemberInfo.role = memberInfo.role;
    copyMemberInfo.isRobot = memberInfo.isRobot;
    return copyMemberInfo;
}

- (NCGroupInfo *)copyGroupInfo:(NCGroupInfo *)groupInfo {
    if (!groupInfo) {
        return nil;
    }
    NCGroupInfo *copyGroupInfo = [NCGroupInfo new];
    copyGroupInfo.groupId = groupInfo.groupId;
    copyGroupInfo.extProfile = groupInfo.extProfile.count > 0
                                   ? [NSDictionary dictionaryWithDictionary:groupInfo.extProfile]
                                   : @{};
    copyGroupInfo.creatorId = groupInfo.creatorId;
    copyGroupInfo.ownerId = groupInfo.ownerId;
    copyGroupInfo.createTime = groupInfo.createTime;
    copyGroupInfo.membersCount = groupInfo.membersCount;
    copyGroupInfo.joinedTime = groupInfo.joinedTime;
    copyGroupInfo.role = groupInfo.role;
    copyGroupInfo.groupName = groupInfo.groupName;
    copyGroupInfo.avatarUrl = groupInfo.avatarUrl;
    copyGroupInfo.introduction = groupInfo.introduction;
    copyGroupInfo.notice = groupInfo.notice;
    copyGroupInfo.joinPermission = groupInfo.joinPermission;
    copyGroupInfo.removeMemberPermission = groupInfo.removeMemberPermission;
    copyGroupInfo.invitePermission = groupInfo.invitePermission;
    copyGroupInfo.inviteHandlePermission = groupInfo.inviteHandlePermission;
    copyGroupInfo.groupInfoEditPermission = groupInfo.groupInfoEditPermission;
    copyGroupInfo.memberInfoEditPermission = groupInfo.memberInfoEditPermission;
    return copyGroupInfo;
}

- (NCChatUIUserInfo *)copyUserInfo:(NCChatUIUserInfo *)userInfo {
    if (!userInfo) {
        return nil;
    }
    NCChatUIUserInfo *copyUser = [NCChatUIUserInfo new];
    copyUser.userId = userInfo.userId;
    copyUser.name = userInfo.name;
    copyUser.avatarUrl = userInfo.avatarUrl;
    copyUser.alias = userInfo.alias;
    copyUser.extra = userInfo.extra;
    if (userInfo.profile) {
        copyUser.profile = [self copyProfile:userInfo.profile];
    }
    if (userInfo.friendInfo) {
        copyUser.friendInfo = [self copyFriendInfo:userInfo.friendInfo];
    }
    if (userInfo.memberInfo) {
        copyUser.memberInfo = [self copyMemberInfo:userInfo.memberInfo];
    }
    return copyUser;
}

- (NCChatUIGroup *)copyGroup:(NCChatUIGroup *)groupInfo {
    if (!groupInfo) {
        return nil;
    }
    NCChatUIGroup *copyGroup = [NCChatUIGroup new];
    copyGroup.groupId = groupInfo.groupId;
    copyGroup.groupName = groupInfo.groupName;
    copyGroup.avatarUrl = groupInfo.avatarUrl;
    copyGroup.extra = groupInfo.extra;
    copyGroup.notice = groupInfo.notice;
    return copyGroup;
}

- (NSString *)groupMemberCacheKeyWithUserId:(NSString *)userId groupId:(NSString *)groupId {
    if (userId.length == 0 || groupId.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@_%@", groupId, userId];
}

#pragma mark-- getter
- (NCThreadSafeMutableDictionary *)userCache {
    if (!_userCache) {
        _userCache =
            [[NCThreadSafeMutableDictionary alloc] initWithCapacity:NCInfoManagementCacheMaxSize];
    }
    return _userCache;
}

- (NCThreadSafeMutableDictionary *)groupCache {
    if (!_groupCache) {
        _groupCache =
            [[NCThreadSafeMutableDictionary alloc] initWithCapacity:NCInfoManagementCacheMaxSize];
    }
    return _groupCache;
}

- (NCThreadSafeMutableDictionary *)memberCache {
    if (!_memberCache) {
        _memberCache =
            [[NCThreadSafeMutableDictionary alloc] initWithCapacity:NCInfoManagementCacheMaxSize];
    }
    return _memberCache;
}

- (NSMutableArray *)cacheUserIds {
    if (!_cacheUserIds) {
        _cacheUserIds = [NSMutableArray new];
    }
    return _cacheUserIds;
}

- (NSMutableArray *)cacheGroupIds {
    if (!_cacheGroupIds) {
        _cacheGroupIds = [NSMutableArray new];
    }
    return _cacheGroupIds;
}

- (NSMutableArray *)cacheMemberIds {
    if (!_cacheMemberIds) {
        _cacheMemberIds = [NSMutableArray new];
        ;
    }
    return _cacheMemberIds;
}

- (NCReadWriteLock *)userThreadLock {
    if (!_userThreadLock) {
        _userThreadLock = [NCReadWriteLock new];
    }
    return _userThreadLock;
}

- (NCReadWriteLock *)groupThreadLock {
    if (!_groupThreadLock) {
        _groupThreadLock = [NCReadWriteLock new];
    }
    return _groupThreadLock;
}

- (NCReadWriteLock *)memberThreadLock {
    if (!_memberThreadLock) {
        _memberThreadLock = [NCReadWriteLock new];
    }
    return _memberThreadLock;
}
@end
