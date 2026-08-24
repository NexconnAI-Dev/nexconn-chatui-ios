//
//  NCChannelInfoCache.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelInfo.h"
#import <Foundation/Foundation.h>

@protocol NCChannelInfoUpdateDelegate <NSObject>

- (void)onConversationInfoUpdate:(NCChannelInfo *)conversationInfo;

@end

@interface NCChannelInfoCache : NSObject

@property (nonatomic, weak) id<NCChannelInfoUpdateDelegate> updateDelegate;

+ (instancetype)sharedCache;

- (NCChannelInfo *)getConversationInfo:(NCChannelType)channelType channelId:(NSString *)channelId;

- (void)updateConversationInfo:(NCChannelInfo *)conversationInfo
                   channelType:(NCChannelType)channelType
                     channelId:(NSString *)channelId;

- (void)clearConversationInfoNetworkCacheOnly:(NCChannelType)channelType
                                    channelId:(NSString *)channelId;

- (void)clearConversationInfo:(NCChannelType)channelType channelId:(NSString *)channelId;

- (void)clearAllConversationInfo;

@end
