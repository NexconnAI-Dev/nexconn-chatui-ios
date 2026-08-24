//
//  NCEditInputContainerView.h
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

NS_ASSUME_NONNULL_BEGIN

// Edit mode height state
typedef NS_ENUM(NSInteger, NCEditHeightMode) {
    NCEditHeightModeNormal = 0,  // Normal editing
    NCEditHeightModeExpanded = 1 // Full-screen editing
};

@protocol NCEditInputContainerViewDelegate;

@interface NCEditInputContainerView : NCBaseView

#pragma mark - Core Properties

/// Text input view
@property (nonatomic, strong, readonly) NCTextView *inputTextView;

/// Edit height mode
@property (nonatomic, assign, readonly) NCEditHeightMode heightMode;

/// Maximum number of input lines for the text view
/// Valid range: 1~6. Values outside this range are automatically clamped.
@property (nonatomic, assign) NSInteger maxInputLines;

/// Delegate
@property (nonatomic, weak) id<NCEditInputContainerViewDelegate> delegate;

/// Whether the text view is being edited (used for keyboard state detection)
@property (nonatomic, assign, readonly) BOOL textViewBeginEditing;

#pragma mark - Edit Mode Buttons

/// Expand/collapse button
@property (nonatomic, strong, readonly) UIButton *editExpandButton;

/// Confirm button
@property (nonatomic, strong, readonly) UIButton *editConfirmButton;

/// Cancel button
@property (nonatomic, strong, readonly) UIButton *editCancelButton;

/// Emoji button in edit mode
@property (nonatomic, strong, readonly) UIButton *editEmojiButton;

#pragma mark - Referenced Message Support

/// Whether there is a referenced message
@property (nonatomic, assign) BOOL hasReferenceMessage;

/// Sender name of the referenced message
@property (nonatomic, copy, nullable) NSString *referencedSenderName;

/// Content of the referenced message
@property (nonatomic, copy, nullable) NSString *referencedContent;

#pragma mark - Public Methods

/// Initialization method
/// @param heightMode The height mode of the input view (normal or full-screen)
- (instancetype)initWithHeightMode:(NCEditHeightMode)heightMode;

/// Set the referenced message content
/// @param senderName The sender name
/// @param content The message content
- (void)setReferencedContentWithSenderName:(NSString *_Nullable)senderName
                                   content:(NSString *_Nullable)content;

/// Clear the referenced message
- (void)clearReferencedMessage;

/// Set the input text
/// @param text The text content
- (void)setInputText:(NSString *)text;

/// Get the input text
- (NSString *)getInputText;

/// Make the input view become the first responder
- (void)becomeInputViewFirstResponder;

/// Make the input view resign the first responder
- (void)resignInputViewFirstResponder;

/// Set the enabled state of the input container (including UI and interaction state)
/// @param enabled Whether the container is enabled
/// @param statusMessage The status message to display, or nil to hide the message
- (void)setEditEnabled:(BOOL)enabled withStatusMessage:(NSString *_Nullable)statusMessage;

@end

#pragma mark - Delegate Protocol

@protocol NCEditInputContainerViewDelegate <NSObject>

@required

/// Request expanding to full-screen edit mode
/// @param editContainerView The edit container view
- (void)editInputContainerViewRequestFullScreenEdit:(NCEditInputContainerView *)editContainerView;

/// Request collapsing from full-screen edit mode
/// @param editContainerView The edit container view
- (void)editInputContainerViewCollapseFromFullScreenEdit:
    (NCEditInputContainerView *)editContainerView;

/// Edit confirmed
/// @param editContainerView The edit container view
/// @param text The edited text
- (void)editInputContainerViewEditConfirm:(NCEditInputContainerView *)editContainerView
                                 withText:(NSString *)text;

/// Edit cancelled
/// @param editContainerView The edit container view
- (void)editInputContainerViewEditCancel:(NCEditInputContainerView *)editContainerView;

/// Emoji button tapped in edit mode
/// @param editContainerView The edit container view
- (void)editInputContainerViewEditEmojiButtonClicked:(NCEditInputContainerView *)editContainerView;

@optional

/// Container view height changed
/// @param editContainerView The edit container view
/// @param frame The new frame
- (void)editInputContainerView:(NCEditInputContainerView *)editContainerView
                didChangeFrame:(CGRect)frame;

/// Input text changed
/// @param editContainerView The edit container view
/// @param textView The text input view
- (void)editInputContainerView:(NCEditInputContainerView *)editContainerView
        inputTextViewDidChange:(UITextView *)textView;

/// Input text is about to change
/// @param editContainerView The edit container view
/// @param textView The text input view
/// @param range The range of the text to be replaced
/// @param text The replacement text
- (BOOL)editInputContainerView:(NCEditInputContainerView *)editContainerView
                 inputTextView:(UITextView *)textView
       shouldChangeTextInRange:(NSRange)range
               replacementText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
