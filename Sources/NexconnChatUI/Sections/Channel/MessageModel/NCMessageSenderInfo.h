//
//  NCMessageSenderInfo.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 27/5/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

@class NCChatUIUserInfo;

NS_ASSUME_NONNULL_BEGIN

@interface NCMessageSenderInfo : NSObject

@property (nonatomic, copy, nullable) NSString *userId;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *avatarUrl;
@property (nonatomic, strong, nullable) NCChatUIUserInfo *userInfo;

+ (instancetype)infoWithUserInfo:(nullable NCChatUIUserInfo *)userInfo;

@end

@interface NCMessageSenderUserInfoResolver : NSObject

+ (nullable NSString *)resolvedSenderUserIdWithMessageSenderUserId:(nullable NSString *)senderUserId
                                                    senderUserInfo:(nullable NCUserInfo *)senderUserInfo;

+ (nullable NCChatUIUserInfo *)userInfoForChannelType:(NCChannelType)channelType
                                            channelId:(nullable NSString *)channelId
                                         senderUserId:(nullable NSString *)senderUserId
                                       senderUserInfo:(nullable NCUserInfo *)senderUserInfo;

@end

NS_ASSUME_NONNULL_END
