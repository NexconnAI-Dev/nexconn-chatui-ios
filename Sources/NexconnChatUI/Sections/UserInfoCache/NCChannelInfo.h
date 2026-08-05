//
//  NCChannelInfo.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

@class NCChatUIGroup;

@interface NCChannelInfo : NSObject

@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, assign) NCChannelType channelType;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *avatarUrl;
@property (nonatomic, copy) NSString *extra;
@property (nonatomic, strong, nullable) NCChatUIGroup *groupInfo;

- (instancetype)initWithConversationId:(NSString *)channelId
                      channelType:(NCChannelType)channelType
                                  name:(NSString *)name
                           avatarUrl:(NSString *)avatarUrl
                                 extra:(NSString *)extra;

- (instancetype)initWithGroupInfo:(NCChatUIGroup *)groupInfo;

- (NCChatUIGroup *)translateToGroupInfo;

+ (NSString *)getConversationGUID:(NCChannelType)channelType channelId:(NSString *)channelId;

@end
