//
//  NCChatUIExtensionModuleManager.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIExtensionModuleManager.h"

#define NCDisplayEmoticonConversationType                                                          \
    [NSArray arrayWithObjects:@(NCChannelTypeDirect), @(NCChannelTypeGroup),                       \
                              @(NCChannelTypeSystem), nil]

@interface NCChatUIExtensionModuleManager ()
@property (nonatomic, strong) NSMutableArray<id<NCChatUIExtensionModule>> *moduleList;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *schemeModuleDict;
@end

@implementation NCChatUIExtensionModuleManager

+ (instancetype)sharedManager {
    static NCChatUIExtensionModuleManager *pDefaultManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      if (pDefaultManager == nil) {
          pDefaultManager = [[NCChatUIExtensionModuleManager alloc] init];
          pDefaultManager.moduleList = [[NSMutableArray alloc] init];
          pDefaultManager.schemeModuleDict = [[NSMutableDictionary alloc] init];
      }
    });
    return pDefaultManager;
}

- (void)loadAllExtensionModules {
}

- (NSArray<id<NCChatUIExtensionModule>> *)getAllExtensionModules {
    return [self.moduleList copy];
}

- (void)initWithAppKey:(NSString *)appkey {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(initWithAppKey:)]) {
            [module initWithAppKey:appkey];
        }
    }
}

- (void)didConnect:(NSString *)userId {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(didConnect:)]) {
            [module didConnect:userId];
        }
    }
}

- (void)didDisconnect {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(didDisconnect)]) {
            [module didDisconnect];
        }
    }
}

- (void)didCurrentUserInfoUpdated:(NCChatUIUserInfo *)userInfo {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(didCurrentUserInfoUpdated:)]) {
            [(id)module didCurrentUserInfoUpdated:userInfo];
        }
    }
}

- (BOOL)onOpenUrl:(NSURL *)url {
    NSString *moduleName = self.schemeModuleDict[url.scheme];

    if (moduleName == nil) {
        return NO;
    }

    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([NSStringFromClass([module class]) isEqualToString:moduleName] &&
            [module respondsToSelector:@selector(onOpenUrl:)]) {
            return [module onOpenUrl:url];
        }
    }
    return NO;
}

- (void)setScheme:(NSString *)scheme forModule:(NSString *)moduleName {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([NSStringFromClass([module class]) isEqualToString:moduleName] &&
            [module respondsToSelector:@selector(setScheme:)]) {
            [module setScheme:scheme];
            [self.schemeModuleDict setObject:moduleName forKey:scheme];
            return;
        }
    }
}

- (NSArray<NCChatUIExtensionPluginItemInfo *> *)getPluginBoardItemInfoList:
                                                    (NCChannelType)channelType
                                                                 channelId:(NSString *)channelId {
    NSMutableArray<NCChatUIExtensionPluginItemInfo *> *items = [NSMutableArray new];
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(getPluginBoardItemInfoList:channelId:)]) {
            [items addObjectsFromArray:[module getPluginBoardItemInfoList:channelType
                                                                channelId:channelId]];
        }
    }
    return [items copy];
}

- (NSArray<id<NCEmoticonTabSource>> *)getEmoticonTabList:(NCChannelType)channelType
                                               channelId:(NSString *)channelId {
    NSMutableArray *tabs = [NSMutableArray new];
    if ([NCDisplayEmoticonConversationType containsObject:@(channelType)]) {
        for (id<NCChatUIExtensionModule> module in self.moduleList) {
            if ([module respondsToSelector:@selector(getEmoticonTabList:channelId:)]) {
                [tabs addObjectsFromArray:[module getEmoticonTabList:channelType
                                                           channelId:channelId]];
            }
        }
    }
    return [tabs copy];
}

- (void)onMessageReceived:(NCMessage *)message {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(onMessageReceived:)]) {
            [module onMessageReceived:message];
        }
    }
}

- (BOOL)handleAlertForMessageReceived:(NCMessage *)message {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(handleAlertForMessageReceived:)] &&
            [module handleAlertForMessageReceived:message])
            return YES;
    }
    return NO;
}

- (BOOL)handleNotificationForMessageReceived:(NCMessage *)message
                                        from:(NSString *)fromName
                                    userInfo:(NSDictionary *)userInfo {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(
                                           handleNotificationForMessageReceived:from:userInfo:)] &&
            [module handleNotificationForMessageReceived:message from:fromName userInfo:userInfo])
            return YES;
    }
    return NO;
}

- (void)emoticonTab:(NCEmojiBoardView *)emojiView
    didTouchAddButton:(UIButton *)addButton
           inInputBar:(NCChatSessionInputBarControl *)inputBarControl {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(emoticonTab:didTouchAddButton:inInputBar:)]) {
            [module emoticonTab:emojiView didTouchAddButton:addButton inInputBar:inputBarControl];
        }
    }
}

- (void)emoticonTab:(NCEmojiBoardView *)emojiView
    didTouchEmotionIconIndex:(int)index
                  inInputBar:(NCChatSessionInputBarControl *)inputBarControl
         isBlockDefaultEvent:(void (^)(BOOL isBlockDefaultEvent))block {
    if (self.moduleList.count > 0) {
        BOOL isModuleHandle = NO;
        for (id<NCChatUIExtensionModule> module in self.moduleList) {
            if ([module respondsToSelector:@selector(emoticonTab:didTouchEmotionIconIndex:
                                                     inInputBar:isBlockDefaultEvent:)]) {
                [module emoticonTab:emojiView
                    didTouchEmotionIconIndex:index
                                  inInputBar:inputBarControl
                         isBlockDefaultEvent:block];
                isModuleHandle = YES;
            }
        }
        if (!isModuleHandle) {
            block(NO);
        }
    } else {
        block(NO);
    }
}

- (void)emoticonTab:(NCEmojiBoardView *)emojiView
    didTouchSettingButton:(UIButton *)settingButton
               inInputBar:(NCChatSessionInputBarControl *)inputBarControl {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(emoticonTab:didTouchSettingButton:inInputBar:)]) {
            [module emoticonTab:emojiView
                didTouchSettingButton:settingButton
                           inInputBar:inputBarControl];
        }
    }
}

- (void)inputTextViewDidChange:(UITextView *)inputTextView
                    inInputBar:(NCChatSessionInputBarControl *)inputBarControl {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(inputTextViewDidChange:inInputBar:)]) {
            [module inputTextViewDidChange:inputTextView inInputBar:inputBarControl];
        }
    }
}

- (void)inputBarStatusDidChange:(KBottomBarStatus)status
                     inInputBar:(NCChatSessionInputBarControl *)inputBarControl {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(inputBarStatusDidChange:inInputBar:)]) {
            [module inputBarStatusDidChange:status inInputBar:inputBarControl];
        }
    }
}

/*!
 Whether to show the emoticon add button.

 @param inputBarControl The input bar.
 */
- (BOOL)isEmoticonAddButtonEnabled:(NCChatSessionInputBarControl *)inputBarControl {
    if ([NCDisplayEmoticonConversationType containsObject:@(inputBarControl.channelType)]) {
        for (id<NCChatUIExtensionModule> module in self.moduleList) {
            if ([module respondsToSelector:@selector(isEmoticonAddButtonEnabled:)] &&
                [module isEmoticonAddButtonEnabled:inputBarControl]) {
                return YES;
            }
        }
    }
    return NO;
}

/*!
 Whether to show the emoticon settings button.

 @param inputBarControl The input bar.
 */
- (BOOL)isEmoticonSettingButtonEnabled:(NCChatSessionInputBarControl *)inputBarControl {
    if ([NCDisplayEmoticonConversationType containsObject:@(inputBarControl.channelType)]) {
        for (id<NCChatUIExtensionModule> module in self.moduleList) {
            if ([module respondsToSelector:@selector(isEmoticonSettingButtonEnabled:)] &&
                [module isEmoticonSettingButtonEnabled:inputBarControl]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)isAudioHolding {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(isAudioHolding)] && [module isAudioHolding]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isCameraHolding {
    for (id<NCChatUIExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(isCameraHolding)] && [module isCameraHolding]) {
            return YES;
        }
    }
    return NO;
}

@end
