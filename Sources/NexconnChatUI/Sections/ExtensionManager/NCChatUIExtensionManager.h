//
//  NCChatUIExtensionManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUISDKExtensionModule.h"
#import "NCChatUIUserInfo.h"
#import <Foundation/Foundation.h>

@class NCMessage;

@interface NCChatUIExtensionManager : NSObject

+ (instancetype)sharedManager;

- (void)loadAllExtensionModules;
- (void)initWithAppKey:(NSString *)appkey;
- (void)didConnect:(NSString *)userId;
- (void)didDisconnect;
- (void)didCurrentUserInfoUpdated:(NCChatUIUserInfo *)userInfo;

- (void)forwardMessageToExtensions:(NCMessage *)message;
- (BOOL)handleAlertForMessageReceived:(NCMessage *)message;
- (BOOL)handleNotificationForMessageReceived:(NCMessage *)message
                                        from:(NSString *)fromName
                                    userInfo:(NSDictionary *)userInfo;

- (BOOL)onOpenUrl:(NSURL *)url;
- (void)setScheme:(NSString *)scheme forModule:(NSString *)moduleName;

- (NSArray<NCChatUIExtensionMessageCellInfo *> *)getMessageCellInfoList:(NCChannelType)channelType
                                                              channelId:(NSString *)channelId;
- (void)didTapMessageCell:(NCMessageModel *)messageModel;

- (void)extensionViewWillAppear:(NCChannelType)channelType
                      channelId:(NSString *)channelId
                  extensionView:(UIView *)extensionView;

- (void)extensionViewWillDisappear:(NCChannelType)channelType channelId:(NSString *)channelId;

- (void)containerViewWillDestroy:(NCChannelType)channelType channelId:(NSString *)channelId;

@end
