//
//  NCInfoManagementCache.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCChatUIUserInfo.h"
#import "NCChatUIGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCInfoManagementCache : NSObject

#pragma mark -- user

- (NCChatUIUserInfo *)getUserCache:(NSString *)userId;

- (void)cacheUser:(NCChatUIUserInfo *)useInfo;

- (void)removeUserCache:(NSString *)userId;

- (void)removeAllUserCache;

#pragma mark -- group

- (NCChatUIGroup *)getGroupCache:(NSString *)groupId;

- (void)cacheGroup:(NCChatUIGroup *)group;

- (void)removeGroupCache:(NSString *)groupId;

- (void)removeAllGroupCache;

- (NCChatUIUserInfo *)getGroupMemberCache:(NSString *)userId groupId:(NSString *)groupId;

- (void)cacheGroupMember:(NCChatUIUserInfo *)member groupId:(NSString *)groupId;

- (void)removeGroupMemberCache:(NSString *)userId groupId:(NSString *)groupId;;

- (void)removeAllGroupMemberCache;
@end

NS_ASSUME_NONNULL_END
