//
//  NCInfoUpdateCenter.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIGroup.h"
#import "NCChatUIUserInfo.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NCInfoUpdateDelegate <NSObject>
@optional
- (void)onUserInfoUpdate:(NCChatUIUserInfo *)userInfo;
- (void)onGroupMemberInfoUpdate:(NCChatUIUserInfo *)userInfo groupId:(NSString *)groupId;
- (void)onGroupInfoUpdate:(NCChatUIGroup *)groupInfo;
@end

@interface NCInfoUpdateCenter : NSObject
+ (void)addInfoUpdateDelegate:(id<NCInfoUpdateDelegate>)delegate;

+ (void)removeInfoUpdateDelegate:(id<NCInfoUpdateDelegate>)delegate;

+ (void)dispatchUserInfoUpdate:(NCChatUIUserInfo *)userInfo;

+ (void)dispatchGroupMemberInfoUpdate:(NCChatUIUserInfo *)userInfo groupId:(NSString *)groupId;

+ (void)dispatchGroupInfoUpdate:(NCChatUIGroup *)groupInfo;
@end

NS_ASSUME_NONNULL_END
