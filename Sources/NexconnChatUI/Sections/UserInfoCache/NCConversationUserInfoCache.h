//
//  NCConversationUserInfoCache.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIUserInfo.h"
#import <Foundation/Foundation.h>

@protocol NCChannelUserInfoUpdateDelegate <NSObject>

- (void)onConversationUserInfoUpdate:(NCChatUIUserInfo *)userInfo
                      inConversation:(NCChannelType)channelType
                           channelId:(NSString *)channelId;

@end

@interface NCConversationUserInfoCache : NSObject

@property (nonatomic, weak) id<NCChannelUserInfoUpdateDelegate> updateDelegate;

+ (instancetype)sharedCache;

- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId
                      channelType:(NCChannelType)channelType
                        channelId:(NSString *)channelId;

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo
             forUserId:(NSString *)userId
           channelType:(NCChannelType)channelType
             channelId:(NSString *)channelId;

- (void)clearConversationUserInfoNetworkCacheOnly:(NSString *)userId
                                      channelType:(NCChannelType)channelType
                                        channelId:(NSString *)channelId;

- (void)clearConversationUserInfo:(NSString *)userId
                      channelType:(NCChannelType)channelType
                        channelId:(NSString *)channelId;

- (void)clearAllConversationUserInfo;

@end
