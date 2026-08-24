//
//  NCInputContainerView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"
#import "NCButton.h"
#import "NCChatSessionInputBarDefine.h"
#import "NCTextView.h"
#import <UIKit/UIKit.h>
@protocol NCInputContainerViewDelegate;

@interface NCInputContainerView : NCBaseView
/// Button to switch between voice and text input.
@property (strong, nonatomic) NCButton *switchButton;

/// Button for recording voice messages.
@property (nonatomic, strong) NCButton *recordButton;

/// Text input view.
@property (nonatomic, strong) NCTextView *inputTextView;

/// Emoji button.
@property (nonatomic, strong) NCButton *emojiButton;

/// Additional (extension) input button.
@property (nonatomic, strong) NCButton *additionalButton;

@property (nonatomic, assign) KBottomBarStatus currentBottomBarStatus;

/// Maximum number of input lines.
///
/// Valid range: 1~6. Values outside this range are clamped to the boundary.
@property (nonatomic, assign) NSInteger maxInputLines;

// Hide the emoji button.
@property (nonatomic, assign) BOOL hideEmojiButton;

@property (nonatomic, weak) id<NCInputContainerViewDelegate> delegate;

- (void)setInputBarStyle:(NCChatSessionInputBarControlStyle)style;

- (void)setBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus;

@end

@protocol NCInputContainerViewDelegate <NSObject>

- (void)inputContainerViewSwitchButtonClicked:(NCInputContainerView *)inputContainerView;

- (void)inputContainerViewEmojiButtonClicked:(NCInputContainerView *)inputContainerView;

- (void)inputContainerViewAdditionalButtonClicked:(NCInputContainerView *)inputContainerView;

- (void)inputContainerView:(NCInputContainerView *)inputContainerView
          forControlEvents:(UIControlEvents)controlEvents;

- (void)inputContainerView:(NCInputContainerView *)inputContainerView didChangeFrame:(CGRect)frame;

- (BOOL)inputTextView:(UITextView *)inputTextView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text;

- (void)inputTextViewDidChange:(UITextView *)textView;
@end
