//
//  NCChatUIExtensionService.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIExtensionService.h"
#import "NCChatUIExtensionModuleManager.h"

@implementation NCChatUIExtensionService

+ (instancetype)sharedService {
    static NCChatUIExtensionService *pDefaultService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (pDefaultService == nil) {
            pDefaultService = [[NCChatUIExtensionService alloc] init];
        }
    });
    return pDefaultService;
}

- (void)loadAllExtensionModules {
    [[NCChatUIExtensionModuleManager sharedManager] loadAllExtensionModules];
}

- (NSArray *)getAllExtensionModules {
    return [[NCChatUIExtensionModuleManager sharedManager] getAllExtensionModules];
}

- (void)initWithAppKey:(NSString *)appkey {
    [[NCChatUIExtensionModuleManager sharedManager] initWithAppKey:appkey];
}

- (void)didConnect:(NSString *)userId {
    [[NCChatUIExtensionModuleManager sharedManager] didConnect:userId];
}

- (void)didDisconnect {
    [[NCChatUIExtensionModuleManager sharedManager] didDisconnect];
}

- (void)didCurrentUserInfoUpdated:(NCChatUIUserInfo *)userInfo {
    [[NCChatUIExtensionModuleManager sharedManager] didCurrentUserInfoUpdated:userInfo];
}

- (BOOL)onOpenUrl:(NSURL *)url {
    return [[NCChatUIExtensionModuleManager sharedManager] onOpenUrl:url];
}

- (void)setScheme:(NSString *)scheme forModule:(NSString *)moduleName {
    [[NCChatUIExtensionModuleManager sharedManager] setScheme:scheme forModule:moduleName];
}

- (NSArray<NCChatUIExtensionPluginItemInfo *> *)getPluginBoardItemInfoList:(NCChannelType)channelType
                                                            channelId:(NSString *)channelId {
    return [[NCChatUIExtensionModuleManager sharedManager] getPluginBoardItemInfoList:channelType channelId:channelId];
}

- (NSArray<id<NCEmoticonTabSource>> *)getEmoticonTabList:(NCChannelType)channelType
                                                channelId:(NSString *)channelId {
    return [[NCChatUIExtensionModuleManager sharedManager] getEmoticonTabList:channelType channelId:channelId];
}

- (void)onMessageReceived:(NCMessage *)message {
    [[NCChatUIExtensionModuleManager sharedManager] onMessageReceived:message];
}

- (BOOL)handleAlertForMessageReceived:(NCMessage *)message {
    return [[NCChatUIExtensionModuleManager sharedManager] handleAlertForMessageReceived:message];
}

- (BOOL)handleNotificationForMessageReceived:(NCMessage *)message
                                        from:(NSString *)fromName
                                    userInfo:(NSDictionary *)userInfo {
    return [[NCChatUIExtensionModuleManager sharedManager] handleNotificationForMessageReceived:message
                                                                                     from:fromName
                                                                                 userInfo:userInfo];
}

- (void)emoticonTab:(NCEmojiBoardView *)emojiView
  didTouchAddButton:(UIButton *)addButton
         inInputBar:(NCChatSessionInputBarControl *)inputBarControl {
    [[NCChatUIExtensionModuleManager sharedManager] emoticonTab:emojiView
                                        didTouchAddButton:addButton
                                               inInputBar:inputBarControl];
}

- (void)emoticonTab:(NCEmojiBoardView *)emojiView
    didTouchEmotionIconIndex:(int)index
                  inInputBar:(NCChatSessionInputBarControl *)inputBarControl
         isBlockDefaultEvent:(void (^)(BOOL isBlockDefaultEvent))block {
    [[NCChatUIExtensionModuleManager sharedManager] emoticonTab:emojiView
                                 didTouchEmotionIconIndex:index
                                               inInputBar:inputBarControl
                                      isBlockDefaultEvent:block];
}

- (void)emoticonTab:(NCEmojiBoardView *)emojiView
    didTouchSettingButton:(UIButton *)settingButton
               inInputBar:(NCChatSessionInputBarControl *)inputBarControl {
    [[NCChatUIExtensionModuleManager sharedManager] emoticonTab:emojiView
                                    didTouchSettingButton:settingButton
                                               inInputBar:inputBarControl];
}

- (void)inputTextViewDidChange:(UITextView *)inputTextView inInputBar:(NCChatSessionInputBarControl *)inputBarControl {
    [[NCChatUIExtensionModuleManager sharedManager] inputTextViewDidChange:inputTextView inInputBar:inputBarControl];
}
- (void)inputBarStatusDidChange:(KBottomBarStatus)status inInputBar:(NCChatSessionInputBarControl *)inputBarControl {
    [[NCChatUIExtensionModuleManager sharedManager] inputBarStatusDidChange:status inInputBar:inputBarControl];
}

/*!
 Whether to show the emoticon add button.

 @param inputBarControl The input bar.
 */
- (BOOL)isEmoticonAddButtonEnabled:(NCChatSessionInputBarControl *)inputBarControl {
    return [[NCChatUIExtensionModuleManager sharedManager] isEmoticonAddButtonEnabled:inputBarControl];
}

/*!
 Whether to show the emoticon settings button.

 @param inputBarControl The input bar.
 */
- (BOOL)isEmoticonSettingButtonEnabled:(NCChatSessionInputBarControl *)inputBarControl {
    return [[NCChatUIExtensionModuleManager sharedManager] isEmoticonSettingButtonEnabled:inputBarControl];
}

- (BOOL)isAudioHolding {
    return [[NCChatUIExtensionModuleManager sharedManager] isAudioHolding];
}

- (BOOL)isCameraHolding {
    return [[NCChatUIExtensionModuleManager sharedManager] isCameraHolding];
}

@end
