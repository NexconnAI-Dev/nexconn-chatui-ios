//
//  NCChatUIExtensionService.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatSessionInputBarControl.h"
#import "NCEmoticonTabSource.h"
#import "NCChatUIExtensionPluginItemInfo.h"
#import "NCChatUIUserInfo.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class NCMessage;

@interface NCChatUIExtensionService : NSObject

+ (instancetype)sharedService;

#pragma mark - module manager
- (void)loadAllExtensionModules;
- (NSArray *)getAllExtensionModules;
- (void)initWithAppKey:(NSString *)appkey;
- (void)didConnect:(NSString *)userId;
- (void)didDisconnect;
- (void)didCurrentUserInfoUpdated:(NCChatUIUserInfo *)userInfo;
- (void)onMessageReceived:(NCMessage *)message;
- (BOOL)handleAlertForMessageReceived:(NCMessage *)message;
- (BOOL)handleNotificationForMessageReceived:(NCMessage *)message
                                        from:(NSString *)fromName
                                    userInfo:(NSDictionary *)userInfo;

#pragma - module url
- (BOOL)onOpenUrl:(NSURL *)url;
- (void)setScheme:(NSString *)scheme forModule:(NSString *)moduleName;

#pragma mark - input bar
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

/*!
 Whether the audio channel is in use. This API can only detect usage by IMKit submodules.
 @warnning Use the API with the same name in NCChatUIUtility.
 */
- (BOOL)isAudioHolding;

/*!
 Whether the camera is in use. This API can only detect usage by IMKit submodules.
 @warnning Use the API with the same name in NCChatUIUtility.
 */
- (BOOL)isCameraHolding;
@end
