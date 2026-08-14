//
//  NCEditInputBarControl.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCEditInputBarControl.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIExtensionService.h"
#import "NCInputStateManager.h"
#import "NCInputKeyboardManager.h"

const CGFloat Height_EmojiBoardView = 223.5f; // Emoji panel height.

// Keyboard notification name.
extern NSString *const NCUIKeyboardWillShowNotification;

@interface NCEditInputBarControl () <NCInputStateManagerDelegate, NCInputKeyboardManagerDelegate>

/// Edit input container.
@property (nonatomic, strong) NCEditInputContainerView *editInputContainer;

/// Emoji panel.
@property (nonatomic, strong, nullable) NCEmojiBoardView *emojiBoardView;

/// Keyboard state manager.
@property (nonatomic, strong) NCInputKeyboardManager *keyboardManager;

/// Current bottom-bar state.
@property (nonatomic, assign) KBottomBarStatus currentBottomBarStatus;

@property (nonatomic, assign) CGRect savedFrame; // Frame saved before hiding.

@property (nonatomic, assign) BOOL isFullScreen;

/// Whether message editing is currently allowed.
@property (nonatomic, assign) BOOL canEdit;

/// Input state manager for mentions and referenced-message metadata.
@property (nonatomic, strong) NCInputStateManager *inputStateManager;

@end

@implementation NCEditInputBarControl

#pragma mark - Overrides

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (self.isVisible && !self.hidden && [self.delegate respondsToSelector:@selector(editInputBarControl:shouldChangeFrame:)]) {
        [self.delegate editInputBarControl:self shouldChangeFrame:frame];
    }
}

#pragma mark - Initialization

- (instancetype)initWithIsFullScreen:(BOOL)isFullScreen {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _isFullScreen = isFullScreen;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self setupUI];
    _canEdit = YES;
}

- (void)dealloc {
    // Stop keyboard monitoring; the manager removes its observers.
    [_keyboardManager stopMonitoring];
    
    // Detach the emoji panel delegate.
    [_emojiBoardView removeFromSuperview];
    _emojiBoardView = nil;
}

#pragma mark - UI Setup

- (void)setupUI {
    self.backgroundColor = NCDynamicColor(@"common_background_color");
    self.hidden = YES;
    self.isVisible = NO;
    self.currentBottomBarStatus = KBottomBarDefaultStatus;
    [self addSubview:self.editInputContainer];
    // Configure the edit container constraints.
    [self setupViewConstraints];
}

- (void)setupViewConstraints {
    // Fill this control with the edit container.
    self.editInputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.editInputContainer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.editInputContainer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.editInputContainer.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.editInputContainer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
}

#pragma mark - Public Methods

- (void)showWithConfig:(NCEditInputBarConfig *)config {
    self.inputBarConfig = config;
    if (!self.isVisible) {
        // Reveal the control before presenting content.
        self.isVisible = YES;
        self.hidden = NO;
    }
    // Reset input state whenever a new edit is shown.
    [self.editInputContainer setInputText:@""];
    
    // Populate the editable text.
    [self.editInputContainer setInputText:config.textContent ?: @""];
    
    // Populate referenced-message metadata.
    if (config.referencedSenderName.length > 0 || config.referencedContent.length > 0) {
        [self setReferenceInfo:config.referencedSenderName content:config.referencedContent];
    } else {
        [self.editInputContainer clearReferencedMessage];
    }
    
    if (config.mentionedRangeInfo) {
        [self.inputStateManager setupMentionedRangeInfo:config.mentionedRangeInfo];
    }
    if (self.canEdit) {
        BOOL enable = self.editInputContainer.getInputText.length > 0;
        [self.editInputContainer setEditEnabled:enable withStatusMessage:nil];
    }
}

- (void)exitWithAnimation:(BOOL)animated completion:(void (^)(void))completion {
    [self hideBottomPanelsWithAnimation:animated completion:^{
        [self.editInputContainer setEditEnabled:YES withStatusMessage:@""];
        self.hidden = YES;
        self.isVisible = NO;
        if (completion) {
            completion();
        }
    }];
}

- (void)hideEditInputBar:(BOOL)hidden {
    if (self.hidden == hidden) {
        return;
    }
    if (hidden) {
        [self hideBottomPanelsWithAnimation:YES completion:nil];
        self.savedFrame = self.frame;
    }
    // Calculate the target visibility state.
    CGRect targetFrame = [self calculateTargetFrame:hidden];
    self.hidden = hidden;
    // Notify the delegate of the frame change.
    [self notifyFrameChange:targetFrame];
}
    
- (void)resetEditInputBar {
    self.editInputContainer.inputTextView.text = @"";
    [self.editInputContainer clearReferencedMessage];
    [self restoreEditStatus];
    [self.inputStateManager clearAllStates];
}

/// Calculates the frame for a visibility state.
/// @param hidden Whether the control should be hidden.
/// @return The target frame.
- (CGRect)calculateTargetFrame:(BOOL)hidden {
    if (hidden) {
        // Move a hidden control below the screen so it occupies no visible space.
        CGRect frame = self.savedFrame;
        frame.origin.y = [NCInputKeyboardManager screenBottomY];
        return frame;
    } else {
        // Restore the saved visible frame.
        return self.savedFrame;
    }
}

/// Notifies the delegate that the frame changed.
/// @param frame The new frame.
- (void)notifyFrameChange:(CGRect)frame {
    if ([self.delegate respondsToSelector:@selector(editInputBarControl:shouldChangeFrame:)]) {
        [self.delegate editInputBarControl:self shouldChangeFrame:frame];
    }
}

#pragma mark - Helpers

- (NSString *)currentEditText {
    return [self.editInputContainer getInputText];
}

- (void)setEditText:(NSString *)text {
    [self.editInputContainer setInputText:text];
}

#pragma mark - Bottom-Bar Animation

- (float)getBoardViewBottomOriginY {
    return [NCInputKeyboardManager screenBottomY];
}

- (float)getSafeAreaExtraBottomHeight {
    return [NCChatUIUtility getWindowSafeAreaInsets].bottom;
}

- (void)layoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus
                         animated:(BOOL)animated
                       completion:(void (^ _Nullable)())completion {
    [self layoutBottomBarWithStatus:bottomBarStatus
                                    animated:animated
                                 forceUpdate:NO
                                  completion:completion];
}

- (void)layoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus
                         animated:(BOOL)animated
                      forceUpdate:(BOOL)forceUpdate
                       completion:(void (^ _Nullable)())completion {
    if (self.currentBottomBarStatus == bottomBarStatus && !forceUpdate) {
        if (completion) {
            completion();
        }
        return;
    }
    if (animated) {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self layoutBottomBarWithStatus:bottomBarStatus];
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    } else {
        [self layoutBottomBarWithStatus:bottomBarStatus];
        if (completion) {
            completion();
        }
    }
}


- (void)layoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus {
    self.currentBottomBarStatus = bottomBarStatus;
    
    // Calculate the input bar position for the requested state.
    CGRect editBarRect = self.frame;
    float bottomY = [self getBoardViewBottomOriginY];
    CGFloat changedHeight = 0;
    switch (bottomBarStatus) {
        case KBottomBarDefaultStatus: {
            [self hiddenEmojiBoardView];
            [self.editInputContainer resignInputViewFirstResponder];
            changedHeight = 0;
            break;
        }
        case KBottomBarEmojiStatus: {
            [self showEmojiBoardView];
            [self.editInputContainer resignInputViewFirstResponder];
            changedHeight = self.emojiBoardView.bounds.size.height;
            break;
        }
        case KBottomBarKeyboardStatus: {
            [self hiddenEmojiBoardView];
            [self.editInputContainer becomeInputViewFirstResponder];
            changedHeight = self.keyboardManager.currentKeyboardHeight - [NCChatUIUtility getWindowSafeAreaInsets].bottom;
            break;
        }
        default:
            break;
    }
    editBarRect.origin.y = bottomY - self.bounds.size.height - changedHeight;
    if (self.isFullScreen) {
        if ([self.delegate respondsToSelector:@selector(editInputBarControl:shouldChangeFrame:)]) {
            [self.delegate editInputBarControl:self shouldChangeFrame:CGRectMake(0, 0, 0, changedHeight)];
        }
    } else {
        // Apply the input bar position.
        self.frame = editBarRect;
        
        if ([self.delegate respondsToSelector:@selector(editInputBarControl:shouldChangeFrame:)]) {
            [self.delegate editInputBarControl:self shouldChangeFrame:editBarRect];
        }
    }
}

- (void)showEmojiBoardView {
    // Reposition the emoji panel below the input bar.
    if (self.bottomPanelsContainerView && self.emojiBoardView.superview != self.bottomPanelsContainerView) {
        self.emojiBoardView.hidden = NO;
        self.emojiBoardView.frame = CGRectMake(0, 0, self.bottomPanelsContainerView.bounds.size.width, Height_EmojiBoardView);
        
        [self.bottomPanelsContainerView addSubview:self.emojiBoardView];
    } else if (self.emojiBoardView.superview != self.superview) {
        CGFloat bottomY = [self getBoardViewBottomOriginY];
        CGFloat topY = bottomY - Height_EmojiBoardView;
        self.emojiBoardView.hidden = NO;
        self.emojiBoardView.frame = CGRectMake(0, topY, self.superview.bounds.size.width, Height_EmojiBoardView);
        
        [self.superview addSubview:self.emojiBoardView];
    }
}

- (void)hiddenEmojiBoardView {
    if (self.emojiBoardView.hidden) {
        return;
    }
    if (self.emojiBoardView) {
        self.emojiBoardView.hidden = YES;
        [self.emojiBoardView removeFromSuperview];
    }
}

#pragma mark - NCInputKeyboardManagerDelegate

- (BOOL)keyboardManagerShouldHandleKeyboardEvent:(NCInputKeyboardManager *)manager {
    BOOL shouldHandle = self.isVisible && !self.isHidden;
    return shouldHandle;
}

- (void)keyboardManager:(NCInputKeyboardManager *)manager
     willShowWithHeight:(CGFloat)height
                  frame:(CGRect)frame
      animationDuration:(NSTimeInterval)duration
         animationCurve:(UIViewAnimationCurve)curve {
    // Match layout changes to the system keyboard animation.
    // Switching layouts while the keyboard is visible can also trigger willShow.
    NSInteger animationCurveOption = (curve << 16);
    [UIView animateWithDuration:duration delay:0.0 options:animationCurveOption animations:^{
        [self layoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:NO forceUpdate:YES completion:nil];
    } completion:^(BOOL finished) {
        // Publish the final keyboard frame after layout completes.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.editInputContainer.textViewBeginEditing) {
                // Forward the keyboard frame through the Chat UI notification used by input observers.
                [[NSNotificationCenter defaultCenter] postNotificationName:NCUIKeyboardWillShowNotification
                                                                    object:self
                                                                  userInfo:@{@"endFrame": [NSValue valueWithCGRect:frame]}];
            }
        });

    }];
}

- (void)keyboardManagerWillHide:(NCInputKeyboardManager *)manager {
    if (self.currentBottomBarStatus == KBottomBarKeyboardStatus) {
        [self layoutBottomBarWithStatus:KBottomBarDefaultStatus animated:NO completion:nil];
    }
}

#pragma mark - NCEditInputContainerViewDelegate

- (void)editInputContainerViewRequestFullScreenEdit:(NCEditInputContainerView *)editContainerView {
    if ([self.delegate respondsToSelector:@selector(editInputBarControlRequestFullScreenEdit:)]) {
        [self.delegate editInputBarControlRequestFullScreenEdit:self];
    }
}

- (void)editInputContainerViewCollapseFromFullScreenEdit:(NCEditInputContainerView *)editContainerView {
    if ([self.delegate respondsToSelector:@selector(editInputBarControlCollapseFromFullScreenEdit:)]) {
        [self.delegate editInputBarControlCollapseFromFullScreenEdit:self];
    }
}

- (void)editInputContainerViewEditConfirm:(NCEditInputContainerView *)editContainerView withText:(NSString *)text {
    if ([self.delegate respondsToSelector:@selector(editInputBarControl:didConfirmWithText:)]) {
        [self.delegate editInputBarControl:self didConfirmWithText:text];
    }
}

- (void)editInputContainerViewEditCancel:(NCEditInputContainerView *)editContainerView {
    if ([self.delegate respondsToSelector:@selector(editInputBarControlDidCancel:)]) {
        [self.delegate editInputBarControlDidCancel:self];
    }
}

- (void)editInputContainerViewEditEmojiButtonClicked:(NCEditInputContainerView *)editContainerView {
    // Handle the emoji button in edit mode.
    // Tapping again leaves an already visible emoji panel open.
    if (self.currentBottomBarStatus != KBottomBarEmojiStatus) {
        [self layoutBottomBarWithStatus:KBottomBarEmojiStatus animated:YES completion:nil];
    }
}

- (void)editInputContainerView:(NCEditInputContainerView *)editContainerView didChangeFrame:(CGRect)frame {
    // Resize the input bar when the edit container height changes.
    CGRect vRect = self.frame;
    vRect.size.height = frame.size.height;
    vRect.origin.y += self.frame.size.height - vRect.size.height;
    self.frame = vRect;
    
    // Notify the delegate of the updated frame.
    if ([self.delegate respondsToSelector:@selector(editInputBarControl:shouldChangeFrame:)]) {
        [self.delegate editInputBarControl:self shouldChangeFrame:vRect];
    }
}

- (void)editInputContainerView:(NCEditInputContainerView *)editContainerView inputTextViewDidChange:(UITextView *)textView {
    // Text changes do not re-enable an edit that is currently disabled.
    if (!self.canEdit) {
        return;
    }
    // Keep the confirm button disabled for empty input.
    NSString *trimmedText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [self.editInputContainer setEditEnabled:trimmedText.length > 0 withStatusMessage:nil];
}

- (BOOL)editInputContainerView:(NCEditInputContainerView *)editContainerView
                 inputTextView:(UITextView *)textView
       shouldChangeTextInRange:(NSRange)range
               replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        NSString *trimmedText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmedText.length == 0) {
            textView.text = @"";
            [self.editInputContainer setInputText:@""];
            [self.editInputContainer setEditEnabled:NO withStatusMessage:nil];
            return NO;
        }
        if ([self.delegate respondsToSelector:@selector(editInputBarControl:didConfirmWithText:)]) {
            [self.delegate editInputBarControl:self didConfirmWithText:textView.text];
        }
        return NO;
    }
    
    // Let the input state manager process mentions.
    BOOL shouldChange = [self.inputStateManager handleTextChange:text inRange:range];
    
    return shouldChange;
}

#pragma mark - NCEmojiViewDelegate

- (void)didTouchEmojiView:(NCEmojiBoardView *)emojiView touchedEmoji:(NSString *)string {
    UITextView *textView = self.editInputContainer.inputTextView;
    
    if (nil == string) {
        // 删除操作
        NSUInteger textLength = textView.textStorage.length;
        NSUInteger cursorLocation = textView.selectedRange.location;
        if (textLength == 0 || cursorLocation == 0 || cursorLocation == NSNotFound || cursorLocation > textLength) {
            return;
        }
        NSRange range = NSMakeRange(cursorLocation - 1, 1);
        if ([textView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            BOOL shouldChange = [textView.delegate textView:textView shouldChangeTextInRange:range replacementText:@""];
            if (shouldChange) {
                [textView deleteBackward];
            }
        }
    } else {
        // Insert the selected emoji token.
        NSString *replaceString = string;
        if (replaceString.length < 5000) {
            NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:replaceString];
            [attStr addAttribute:NSFontAttributeName
                           value:textView.font
                           range:NSMakeRange(0, replaceString.length)];
            UIColor *foreColor = NCDynamicColor(@"text_primary_color");
            if (foreColor) {
                [attStr addAttribute:NSForegroundColorAttributeName
                               value:foreColor
                               range:NSMakeRange(0, replaceString.length)];
            }
            
            NSInteger cursorPosition;
            if (textView.selectedTextRange) {
                cursorPosition = textView.selectedRange.location;
            } else {
                cursorPosition = 0;
            }
            
            // Read the current cursor position.
            if (cursorPosition > textView.textStorage.length)
                cursorPosition = textView.textStorage.length;
            
            [textView.textStorage insertAttributedString:attStr atIndex:cursorPosition];
            
            // Notify observers because emoji insertion mutates the text storage directly.
            if ([textView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                BOOL shouldChange = [textView.delegate textView:textView shouldChangeTextInRange:textView.selectedRange replacementText:string];
                if (shouldChange) {
                    if ([textView.delegate respondsToSelector:@selector(textViewDidChange:)]) {
                        [textView.delegate textViewDidChange:textView];
                    }
                }
            }
            
            // Move the cursor after the inserted emoji.
            NSRange range;
            range.location = textView.selectedRange.location + string.length;
            range.length = 0;
            textView.selectedRange = range;
        }
    }
    
    // Keep the cursor visible after insertion.
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height - (textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top);
    if (overflow > 0) {
        // Scroll just enough to reveal the cursor.
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 7; // Keep a 7-point margin.
        [UIView animateWithDuration:.2 animations:^{
            [textView setContentOffset:offset];
        }];
    }
}

- (void)didSendButtonEvent:(NCEmojiBoardView *)emojiView sendButton:(UIButton *)sendButton {
    NSString *sendText = [self.editInputContainer getInputText];
    NSString *formatString = [sendText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (0 == [formatString length]) {
        // Empty text cannot be submitted.
        return;
    }
    
    // Ask the delegate to confirm the edit.
    if ([self.delegate respondsToSelector:@selector(editInputBarControl:didConfirmWithText:)]) {
        [self.delegate editInputBarControl:self didConfirmWithText:sendText];
    }
}

#pragma mark - Edit Status Management

- (void)setEditStatus:(BOOL)canEdit reason:(nullable NSString *)reason {
    self.canEdit = canEdit;
    
    // Apply the enabled state to the edit container.
    [self.editInputContainer setEditEnabled:canEdit withStatusMessage:reason];
}

- (void)markEditAsExpired {
    [self setEditStatus:NO reason:NCUILocalizedString(@"message_edit_expired")];
}

- (void)restoreEditStatus {
    [self setEditStatus:YES reason:nil];
}

- (void)restoreFocus {
    // Restore focus only when the appropriate editor is visible.
    if ((!self.isVisible && !self.isFullScreen) || self.hidden) {
        return;
    }
    if (!self.editInputContainer.superview) {
        return;
    }
    // Delay the responder transition to avoid competing first-responder changes.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.editInputContainer becomeInputViewFirstResponder];
    });
}

- (void)hideBottomPanelsWithAnimation:(BOOL)animated completion:(void (^ _Nullable)(void))completion {
    if (self.currentBottomBarStatus == KBottomBarDefaultStatus) {
        if (completion) {
            completion();
        };
        return;
    }
    [self layoutBottomBarWithStatus:KBottomBarDefaultStatus animated:animated completion:completion];
}

- (void)setIsMentionedEnabled:(BOOL)isMentionedEnabled {
    _isMentionedEnabled = isMentionedEnabled;
    if (self.inputStateManager) {
        self.inputStateManager.isMentionedEnabled = isMentionedEnabled;
    }
}

- (NCMentionedInfo *)mentionedInfo {
    return self.inputStateManager.mentionedInfo;
}

- (void)addMentionedUser:(NCChatUIUserInfo *)userInfo symbolRequest:(BOOL)symbolRequest {
    [self.inputStateManager insertMentionedUser:userInfo symbolRequest:symbolRequest];
}

#pragma mark - NCInputStateManagerDelegate

- (void)inputStateManager:(NCInputStateManager *)manager
         showUserSelector:(void (^)(NCChatUIUserInfo *))completion
                   cancel:(void (^)(void))cancelBlock {
    // Forward mention user selection to the external delegate.
    if ([self.delegate respondsToSelector:@selector(editInputBarControl:showUserSelector:cancel:)]) {
        [self.delegate editInputBarControl:self showUserSelector:completion cancel:cancelBlock];
    }
}

- (nullable NCChatUIUserInfo *)inputStateManager:(NCInputStateManager *)manager
                        getUserInfoForUserId:(NSString *)userId {
    // Forward user lookup to the external data source.
    if ([self.dataSource respondsToSelector:@selector(editInputBarControl:getUserInfo:)]) {
        return [self.dataSource editInputBarControl:self getUserInfo:userId];
    }
    return nil;
}

#pragma mark - Referenced Message Management

/// Sets referenced-message display information.
/// @param senderName The referenced message sender name.
/// @param content The referenced message content.
- (void)setReferenceInfo:(NSString *)senderName content:(NSString *)content {
    
    // Update the input container preview at the same time.
    if ([self.editInputContainer respondsToSelector:@selector(setReferencedContentWithSenderName:content:)]) {
        [self.editInputContainer setReferencedContentWithSenderName:senderName content:content];
    }
}

- (BOOL)hasContent {
    return self.inputStateManager.hasContent;
}

#pragma mark - Cursor Position

- (NSRange)getCurrentCursorPosition {
    if (self.editInputContainer && self.editInputContainer.inputTextView) {
        return self.editInputContainer.inputTextView.selectedRange;
    }
    return NSMakeRange(NSNotFound, 0);
}

- (void)setCursorPosition:(NSRange)range {
    if (self.editInputContainer && self.editInputContainer.inputTextView) {
        UITextView *textView = self.editInputContainer.inputTextView;
        NSUInteger textLength = textView.text.length;
        
        // Apply only a cursor location within the current text.
        if (range.location != NSNotFound && range.location <= textLength) {
            // if (range.location + range.length > textLength) {
            //     range.length = textLength - range.location;
            // }
            // This API restores a cursor location, not a text selection.
            range.length = 0;
            
            // Restore the cursor asynchronously after the text is loaded.
            dispatch_async(dispatch_get_main_queue(), ^{
                textView.selectedRange = range;
            });
        }
    }
}

- (void)setIsVisible:(BOOL)isVisible {
    _isVisible = isVisible;
    if (isVisible) {
        [self.keyboardManager startMonitoring];
    } else {
        [self.keyboardManager stopMonitoring];
    }
}

#pragma mark - Getter Methods

- (NCEditInputBarConfig *)inputBarConfig {
    if (!_inputBarConfig) {
        _inputBarConfig = [[NCEditInputBarConfig alloc] init];
    }
    _inputBarConfig.textContent = self.editInputContainer.getInputText;
    _inputBarConfig.mentionedRangeInfo = self.inputStateManager.mentionedRangeInfo;
    return _inputBarConfig;
}


- (NCEditInputContainerView *)editInputContainer {
    if (!_editInputContainer) {
        // Create the edit input container for the current height mode.
        NCEditHeightMode mode = self.isFullScreen ? NCEditHeightModeExpanded : NCEditHeightModeNormal;
        _editInputContainer = [[NCEditInputContainerView alloc] initWithHeightMode:mode];
        _editInputContainer.delegate = self;
        _editInputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _editInputContainer;
}

- (NCInputStateManager *)inputStateManager {
    if (!_inputStateManager) {
        _inputStateManager = [[NCInputStateManager alloc]
                              initWithTextView:self.editInputContainer.inputTextView
                              delegate:self];
        _inputStateManager.isMentionedEnabled = self.isMentionedEnabled;
    }
    return _inputStateManager;
}

- (NCInputKeyboardManager *)keyboardManager {
    if (!_keyboardManager) {
        _keyboardManager = [[NCInputKeyboardManager alloc] init];
        _keyboardManager.delegate = self;
    }
    return _keyboardManager;
}

- (NCEmojiBoardView *)emojiBoardView {
    if (!_emojiBoardView) {
        _emojiBoardView = [[NCEmojiBoardView alloc]
                           initWithFrame:CGRectMake(0, 0, self.frame.size.width, Height_EmojiBoardView)
                           delegate:self];
        _emojiBoardView.hidden = YES;
    }
    return _emojiBoardView;
}

@end
