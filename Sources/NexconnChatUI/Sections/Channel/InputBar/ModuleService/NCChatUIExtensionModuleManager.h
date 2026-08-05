//
//  NCChatUIExtensionModuleManager.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIExtensionModule.h"
#import "NCChatUIUserInfo.h"
#import <Foundation/Foundation.h>

@interface NCChatUIExtensionModuleManager : NSObject

+ (instancetype)sharedManager;

- (void)loadAllExtensionModules;
- (NSArray<id<NCChatUIExtensionModule>> *)getAllExtensionModules;
- (void)initWithAppKey:(NSString *)appkey;
- (void)didConnect:(NSString *)userId;
- (void)didDisconnect;
- (void)didCurrentUserInfoUpdated:(NCChatUIUserInfo *)userInfo;

- (void)onMessageReceived:(NCMessage *)message;
- (BOOL)handleAlertForMessageReceived:(NCMessage *)message;
- (BOOL)handleNotificationForMessageReceived:(NCMessage *)message
                                        from:(NSString *)fromName
                                    userInfo:(NSDictionary *)userInfo;

- (BOOL)onOpenUrl:(NSURL *)url;
- (void)setScheme:(NSString *)scheme forModule:(NSString *)moduleName;

- (NSArray<NCChatUIExtensionPluginItemInfo *> *)getPluginBoardItemInfoList:(NCChannelType)channelType
                                                            channelId:(NSString *)channelId;
- (NSArray<id<NCEmoticonTabSource>> *)getEmoticonTabList:(NCChannelType)channelType
                                                channelId:(NSString *)channelId;

- (void)emoticonTab:(NCEmojiBoardView *)emojiView
  didTouchAddButton:(UIButton *)addButton
         inInputBar:(NCChatSessionInputBarControl *)inputBarControl;

- (void)emoticonTab:(NCEmojiBoardView *)emojiView
    didTouchEmotionIconIndex:(int)index
                  inInputBar:(NCChatSessionInputBarControl *)inputBarControl
         isBlockDefaultEvent:(void (^)(BOOL isBlockDefaultEvent))block;
- (void)emoticonTab:(NCEmojiBoardView *)emojiView
    didTouchSettingButton:(UIButton *)settingButton
               inInputBar:(NCChatSessionInputBarControl *)inputBarControl;
- (void)inputTextViewDidChange:(UITextView *)inputTextView inInputBar:(NCChatSessionInputBarControl *)inputBarControl;
- (void)inputBarStatusDidChange:(KBottomBarStatus)status inInputBar:(NCChatSessionInputBarControl *)inputBarControl;

/*!
 Whether the emoticon add button should be displayed.

 - Parameter inputBarControl:  The input toolbar.
 */
- (BOOL)isEmoticonAddButtonEnabled:(NCChatSessionInputBarControl *)inputBarControl;

/*!
 Whether the emoticon setting button should be displayed.

 - Parameter inputBarControl:  The input toolbar.
 */
- (BOOL)isEmoticonSettingButtonEnabled:(NCChatSessionInputBarControl *)inputBarControl;

/// Whether the audio channel is in use.
- (BOOL)isAudioHolding;

/// Whether the camera is in use.
- (BOOL)isCameraHolding;
@end
