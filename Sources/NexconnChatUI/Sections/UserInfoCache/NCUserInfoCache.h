//
//  NCUserInfoCache.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIUserInfo.h"
#import <Foundation/Foundation.h>

@protocol NCUserInfoUpdateDelegate <NSObject>

- (void)onUserInfoUpdate:(NCChatUIUserInfo *)userInfo;

@end

@interface NCUserInfoCache : NSObject

@property (nonatomic, weak) id<NCUserInfoUpdateDelegate> updateDelegate;

+ (instancetype)sharedCache;

- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId;

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo forUserId:(NSString *)userId;

- (void)clearUserInfoNetworkCacheOnly:(NSString *)userId;

- (void)clearUserInfo:(NSString *)userId;

- (void)clearAllUserInfo;

@end
