//
//  NCUserInfoCacheDBHelper.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelInfo.h"
#import "NCChatUIUserInfo.h"
#import "NCFMDatabase.h"
#import <Foundation/Foundation.h>

@interface NCUserInfoCacheDBHelper : NSObject

- (instancetype)initWithPath:(NSString *)storagePath;

- (void)createDBTableIfNeed;

- (void)closeDBIfNeed;

#pragma mark - ConversationInfo DB

- (NCChannelInfo *)selectConversationInfoFromDB:(NCChannelType)channelType
                                      channelId:(NSString *)channelId;

- (NSArray *)selectAllConversationInfoFromDB;

- (void)replaceConversationInfoFromDB:(NCChannelInfo *)conversationInfo
                          channelType:(NCChannelType)channelType
                            channelId:(NSString *)channelId;

- (void)deleteConversationInfoFromDB:(NCChannelType)channelType channelId:(NSString *)channelId;

- (void)deleteAllConversationInfoFromDB;

#pragma mark - ConversationUserInfo DB

- (NCChatUIUserInfo *)selectUserInfoFromDB:(NSString *)userId
                               channelType:(NCChannelType)channelType
                                 channelId:(NSString *)channelId;

- (NSArray *)selectAllConversationUserInfoFromDB;

- (void)replaceUserInfoFromDB:(NCChatUIUserInfo *)userInfo
                    forUserId:(NSString *)userId
                  channelType:(NCChannelType)channelType
                    channelId:(NSString *)channelId;

- (void)deleteConversationUserInfoFromDB:(NSString *)userId
                             channelType:(NCChannelType)channelType
                               channelId:(NSString *)channelId;

- (void)deleteAllConversationUserInfoFromDB;

#pragma mark - UserInfo DB

- (NCChatUIUserInfo *)selectUserInfoFromDB:(NSString *)userId;

- (NSArray *)selectAllUserInfoFromDB;

- (void)replaceUserInfoFromDB:(NCChatUIUserInfo *)userInfo forUserId:(NSString *)userId;

- (void)deleteUserInfoFromDB:(NSString *)userId;

- (void)deleteAllUserInfoFromDB;

@end
