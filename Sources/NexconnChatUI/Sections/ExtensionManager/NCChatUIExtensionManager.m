//
//  NCChatUIExtensionManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIExtensionManager.h"
#import "NCImageView.h"
#import "NCExtensionKit.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUI.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

@interface NCChatUIExtensionManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<NCChatUIExtensionMessageCellInfo *> *> *messageCellDict;

@end

@implementation NCChatUIExtensionManager

+ (instancetype)sharedManager {
    static NCChatUIExtensionManager *pDefaultManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (pDefaultManager == nil) {
            pDefaultManager = [[NCChatUIExtensionManager alloc] init];
        }
    });
    return pDefaultManager;
}

#pragma mark - Dynamic Module Manager
- (void)loadAllExtensionModules {
    [[NCChatUIExtensionService sharedService] loadAllExtensionModules];
}

- (void)initWithAppKey:(NSString *)appkey {
    [[NCChatUIExtensionService sharedService] initWithAppKey:appkey];
}

- (void)didConnect:(NSString *)userId {
    [[NCChatUIExtensionService sharedService] didConnect:userId];
}

- (void)didDisconnect {
    [[NCChatUIExtensionService sharedService] didDisconnect];
}

- (void)didCurrentUserInfoUpdated:(NCChatUIUserInfo *)userInfo {
    [[NCChatUIExtensionService sharedService] didCurrentUserInfoUpdated:userInfo];
}

- (void)forwardMessageToExtensions:(NCMessage *)message {
    if (!message) {
        return;
    }
    [[NCChatUIExtensionService sharedService] onMessageReceived:message];
}

- (BOOL)handleAlertForMessageReceived:(NCMessage *)message {
    return [[NCChatUIExtensionService sharedService] handleAlertForMessageReceived:message];
}

- (BOOL)handleNotificationForMessageReceived:(NCMessage *)message
                                        from:(NSString *)fromName
                                    userInfo:(NSDictionary *)userInfo {
    return [[NCChatUIExtensionService sharedService] handleNotificationForMessageReceived:message
                                                                               from:fromName
                                                                           userInfo:userInfo];
}

- (BOOL)onOpenUrl:(NSURL *)url {
    return [[NCChatUIExtensionService sharedService] onOpenUrl:url];
}

- (void)setScheme:(NSString *)scheme forModule:(NSString *)moduleName {
    [[NCChatUIExtensionService sharedService] setScheme:scheme forModule:moduleName];
}

#pragma mark - Cell UI
- (NSArray<NCChatUIExtensionMessageCellInfo *> *)getMessageCellInfoList:(NCChannelType)channelType
                                                         channelId:(NSString *)channelId {
    self.messageCellDict = [[NSMutableDictionary alloc] init];

    for (id<NCChatUISDKExtensionModule> module in [[NCChatUIExtensionService sharedService] getAllExtensionModules]) {
        if ([module respondsToSelector:@selector(getMessageCellInfoList:channelId:)]) {
            [self.messageCellDict setValue:[module getMessageCellInfoList:channelType channelId:channelId]
                                    forKey:NSStringFromClass([module class])];
        }
    }
    NSMutableArray<NCChatUIExtensionMessageCellInfo *> *result = [NSMutableArray<NCChatUIExtensionMessageCellInfo *> new];
    [self.messageCellDict
        enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSArray<NCChatUIExtensionMessageCellInfo *> *_Nonnull obj,
                                            BOOL *_Nonnull stop) {
            [result addObjectsFromArray:obj];
        }];

    return result;
}

- (void)didTapMessageCell:(NCMessageModel *)messageModel {
    NSString *messageType = messageModel.objectName;
    if (messageType.length == 0) {
        messageType = [NCMessageContent messageTypeForContent:messageModel.content];
    }
    if (messageType.length == 0) {
        return;
    }

    [self.messageCellDict
        enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSArray<NCChatUIExtensionMessageCellInfo *> *_Nonnull obj,
                                            BOOL *_Nonnull stop) {
            for (NCChatUIExtensionMessageCellInfo *info in obj) {
                if (![info.messageType isEqualToString:messageType]) {
                    continue;
                }
                for (id<NCChatUISDKExtensionModule> module in
                     [[NCChatUIExtensionService sharedService] getAllExtensionModules]) {
                    if ([NSStringFromClass([module class]) isEqualToString:key]) {
                        if ([module respondsToSelector:@selector(didTapMessageCell:)]) {
                            [module didTapMessageCell:messageModel];
                        }
                        break;
                    }
                }
                *stop = YES;
            }
        }];
}

#pragma mark - NCChatUIExtensionServiceDelegate
- (UIColor *)navigationBarTintColor {
    return NCChatUIConfigCenter.ui.globalNavigationBarTintColor;
}

- (void)extensionViewWillAppear:(NCChannelType)channelType
                       channelId:(NSString *)channelId
                  extensionView:(UIView *)extensionView {
    for (id<NCChatUISDKExtensionModule> module in [[NCChatUIExtensionService sharedService] getAllExtensionModules]) {
        if ([module respondsToSelector:@selector(extensionViewWillAppear:channelId:extensionView:)]) {
            [module extensionViewWillAppear:channelType channelId:channelId extensionView:extensionView];
        }
    }
}

- (void)extensionViewWillDisappear:(NCChannelType)channelType channelId:(NSString *)channelId {
    for (id<NCChatUISDKExtensionModule> module in [[NCChatUIExtensionService sharedService] getAllExtensionModules]) {
        if ([module respondsToSelector:@selector(extensionViewWillDisappear:channelId:)]) {
            [module extensionViewWillDisappear:channelType channelId:channelId];
        }
    }
}

- (void)containerViewWillDestroy:(NCChannelType)channelType channelId:(NSString *)channelId {
    for (id<NCChatUISDKExtensionModule> module in [[NCChatUIExtensionService sharedService] getAllExtensionModules]) {
        if ([module respondsToSelector:@selector(containerViewWillDestroy:channelId:)]) {
            [module containerViewWillDestroy:channelType channelId:channelId];
        }
    }
}

@end
