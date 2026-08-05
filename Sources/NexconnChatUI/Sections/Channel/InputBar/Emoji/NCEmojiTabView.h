//
//  NCEmojiTabView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol NCEmojiTabViewDelegate;
@interface NCEmojiTabView : UIView

@property (nonatomic, weak) id<NCEmojiTabViewDelegate> delegate;

- (void)showAddButton:(BOOL)showAddButton showSettingButton:(BOOL)showSettingButton;

- (void)reloadTabView:(NSArray *)emotionsListData;

- (void)showEmotion:(int)index;
@end

@protocol NCEmojiTabViewDelegate <NSObject>

- (void)emojiTabView:(NCEmojiTabView *)emojiTabView didClickSendButton:(UIButton *)button;

- (void)emojiTabView:(NCEmojiTabView *)emojiTabView didClickSettingButton:(UIButton *)button;

- (void)emojiTabView:(NCEmojiTabView *)emojiTabView didClickAddButton:(UIButton *)button;

- (void)emojiTabView:(NCEmojiTabView *)emojiTabView didSelectEmotion:(int)index;
@end

NS_ASSUME_NONNULL_END
