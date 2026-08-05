//
//  NCEditInputContainerView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCEditInputContainerView.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"

#define TextViewLineHeight 20.f              // Text height per input line.
#define TextViewSpaceHeight_LessThanMax 17.f // Vertical padding below the maximum line count.
#define TextViewSpaceHeight 13.f             // Vertical padding at or above the maximum line count.
#define TextViewMaxInputLines 6              // Maximum visible input lines.
#define TextViewMinInputLines 1              // Minimum visible input lines.

@interface NCEditInputContainerView () <UITextViewDelegate, NCTextViewDelegate>

// Private UI components.
@property (nonatomic, strong) UIView *topBorderView;                    // Top separator.
@property (nonatomic, strong) UIView *inputContainerBackgroundView;     // Input container background.
@property (nonatomic, strong) UILabel *referencedLabel;                 // Referenced-message label.
@property (nonatomic, strong) UIView *editStatusView;                   // Edit status container.
@property (nonatomic, strong) UIImageView *editStatusImageView;         // Edit status image.
@property (nonatomic, strong) UILabel *editStatusLabel;                 // Edit status label.
@property (nonatomic, strong) NCTextView *inputTextView;                // Text input view.
@property (nonatomic, strong) UIButton *editExpandButton;               // Expand/collapse button.
@property (nonatomic, strong) UIButton *editConfirmButton;              // Confirm button.
@property (nonatomic, strong) UIButton *editCancelButton;               // Cancel button.
@property (nonatomic, strong) UIButton *editEmojiButton;                // Emoji button for edit mode.

@property (nonatomic, assign) NCEditHeightMode heightMode;

// Constraint management.
@property (nonatomic, strong) NSMutableArray *editConstraints;          // Active edit-mode constraints.
@property (nonatomic, strong) NSLayoutConstraint *inputTextViewHeightConstraint; // Input height constraint.

// Keyboard state management.
@property (nonatomic, assign) BOOL textViewBeginEditing;                // Whether text editing has begun.

@end

@implementation NCEditInputContainerView {
    BOOL _didSetupConstraints;
}

#pragma mark - Initialization

- (instancetype)initWithHeightMode:(NCEditHeightMode)heightMode {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _heightMode = heightMode;
        [self setupEditContainer];
    }
    return self;
}

- (void)updateConstraints {
    if (!_didSetupConstraints) {
        [self setupViewConstraints];
        _didSetupConstraints = YES;
    }
    [super updateConstraints];
}

- (void)setupEditContainer {
    // Configure the initial state.
    self.maxInputLines = 4;
    self.hasReferenceMessage = NO;
    
    // Create storage for active constraints.
    self.editConstraints = [NSMutableArray array];
    
    // Apply the container background color.
    self.backgroundColor = NCDynamicColor(@"common_background_color");
    
    // Create and attach subviews.
    [self setupSubviews];
}

- (void)setupSubviews {
    [self addSubview:self.topBorderView];
    
    // Add the input container background.
    [self addSubview:self.inputContainerBackgroundView];
    
    // Add the text view and expand button to the input container.
    [self.inputContainerBackgroundView addSubview:self.inputTextView];
    
    if (self.heightMode == NCEditHeightModeNormal) {
        [self.inputContainerBackgroundView addSubview:self.editExpandButton];
    } else {
        [self addSubview:self.editExpandButton];
    }
    
    [self addSubview:self.referencedLabel];
    
    // Add the bottom action row.
    [self addSubview:self.editEmojiButton];
    [self addSubview:self.editCancelButton];
    [self addSubview:self.editConfirmButton];

    [self addSubview:self.editStatusView];
    [self.editStatusView addSubview:self.editStatusImageView];
    [self.editStatusView addSubview:self.editStatusLabel];
}

#pragma mark - Constraint Setup

- (void)setupViewConstraints {
    // Disable autoresizing-mask constraints for managed subviews.
    self.topBorderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.referencedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.editStatusView.translatesAutoresizingMaskIntoConstraints = NO;
    self.editStatusImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.editStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputContainerBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.editExpandButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editConfirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editCancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editEmojiButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self updateEditConstraints];
}

- (void)updateEditConstraints {
    // Remove constraints from the previous height mode.
    [self removeConstraints:self.editConstraints];
    [self.editConstraints removeAllObjects];
    
    NSMutableArray *constraints = [NSMutableArray array];
    
    if (self.heightMode == NCEditHeightModeExpanded) {
        // Use the expanded layout.
        [self setupFullScreenConstraints:constraints];
    } else {
        // Use the normal layout.
        [self setupNormalModeConstraints:constraints];
    }
    
    // Add constraints for the bottom action row.
    [self setupBottomButtonRowConstraints:constraints];
    
    // Retain all active constraints for the next mode change.
    [self.editConstraints addObjectsFromArray:constraints];
    [self addConstraints:self.editConstraints];
    
    [self updateExpandButtonIcon];
    
    // Recalculate the container height.
    if (self.heightMode == NCEditHeightModeNormal) {
        [self updateContainerHeight];
    }
    
//    // Apply layout changes immediately.
//    [self setNeedsUpdateConstraints];
//    [self updateConstraintsIfNeeded];
//    [self setNeedsLayout];
//    [self layoutIfNeeded];
}

#pragma mark - Layout Constraints

- (void)setupNormalModeConstraints:(NSMutableArray *)constraints {
    // Configure the compact editing layout.
    [constraints addObjectsFromArray:@[
        [self.topBorderView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.topBorderView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.topBorderView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.topBorderView.heightAnchor constraintEqualToConstant:0.5]
    ]];
    
    if (self.hasReferenceMessage) {
        self.referencedLabel.hidden = NO;
        
        [constraints addObjectsFromArray:@[
            [self.referencedLabel.topAnchor constraintEqualToAnchor:self.topBorderView.bottomAnchor constant:10],
            [self.referencedLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
            [self.referencedLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
            [self.referencedLabel.heightAnchor constraintEqualToConstant:20],
            
            [self.inputContainerBackgroundView.topAnchor constraintEqualToAnchor:self.referencedLabel.bottomAnchor constant:10],
        ]];
    } else {
        self.referencedLabel.hidden = YES;
        
        [constraints addObjectsFromArray:@[
            [self.inputContainerBackgroundView.topAnchor constraintEqualToAnchor:self.topBorderView.bottomAnchor constant:9],
        ]];
    }
    
    [constraints addObjectsFromArray:@[
        [self.inputContainerBackgroundView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.inputContainerBackgroundView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12]
    ]];
    
    // Constrain the input container height.
    CGFloat inputHeight = [self calculateInputTextViewHeight];
    self.inputTextViewHeightConstraint = [self.inputContainerBackgroundView.heightAnchor constraintEqualToConstant:inputHeight];
    [constraints addObject:self.inputTextViewHeightConstraint];
    
    // Position the text view inside the input container.
    [constraints addObjectsFromArray:@[
        [self.inputTextView.topAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.topAnchor],
        [self.inputTextView.leadingAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.leadingAnchor],
        [self.inputTextView.bottomAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.bottomAnchor],
        [self.inputTextView.trailingAnchor constraintEqualToAnchor:self.editExpandButton.leadingAnchor constant:-5]
    ]];
    
    // Position the expand button inside the input container.
    [constraints addObjectsFromArray:@[
        [self.editExpandButton.topAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.topAnchor constant:5],
        [self.editExpandButton.trailingAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.trailingAnchor constant:-8],
        [self.editExpandButton.widthAnchor constraintEqualToConstant:28],
        [self.editExpandButton.heightAnchor constraintEqualToConstant:28]
    ]];
}

- (void)setupFullScreenConstraints:(NSMutableArray *)constraints {
    // Read safe-area insets for the expanded layout.
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    }
    
    // The expanded layout does not display the top separator.
    self.topBorderView.hidden = YES;
    
    // The expanded layout lets the text view fill available height.
    self.inputTextViewHeightConstraint = nil;
    
    // Reserve the referenced-message row in expanded mode.
    [constraints addObjectsFromArray:@[
        // Place the collapse button at the trailing edge of the reference row.
        [self.editExpandButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:6],
        [self.editExpandButton.widthAnchor constraintEqualToConstant:28],
        [self.editExpandButton.heightAnchor constraintEqualToConstant:28],
        [self.editExpandButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        
        // Place the input container below the reference row.
        [self.inputContainerBackgroundView.topAnchor constraintEqualToAnchor:self.editExpandButton.bottomAnchor constant:6],
        [self.inputContainerBackgroundView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.inputContainerBackgroundView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        [self.inputContainerBackgroundView.bottomAnchor constraintEqualToAnchor:self.editEmojiButton.topAnchor constant:-16],
    ]];

    [constraints addObjectsFromArray:@[
        [self.referencedLabel.centerYAnchor constraintEqualToAnchor:self.editExpandButton.centerYAnchor],
        [self.referencedLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.referencedLabel.heightAnchor constraintGreaterThanOrEqualToConstant:20], // Keep a minimum row height.
        [self.referencedLabel.trailingAnchor constraintEqualToAnchor:self.editExpandButton.leadingAnchor constant:-10]
    ]];
    
    // Fill the expanded input container with the text view.
    [constraints addObjectsFromArray:@[
        [self.inputTextView.topAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.topAnchor constant:12],
        [self.inputTextView.leadingAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.leadingAnchor constant:12],
        [self.inputTextView.trailingAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.trailingAnchor constant:-12],
        [self.inputTextView.bottomAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.bottomAnchor constant:-12]
    ]];
}

- (void)setupBottomButtonRowConstraints:(NSMutableArray *)constraints {
    [constraints addObjectsFromArray:@[
        // Configure the emoji button size; callers provide its horizontal position.
        [self.editEmojiButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.editEmojiButton.topAnchor constraintEqualToAnchor:self.inputContainerBackgroundView.bottomAnchor constant:10],
        [self.editEmojiButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
        [self.editEmojiButton.widthAnchor constraintEqualToConstant:26],
        [self.editEmojiButton.heightAnchor constraintEqualToConstant:26],
        
        // Constrain the edit status view.
        [self.editStatusView.trailingAnchor constraintEqualToAnchor:self.editCancelButton.leadingAnchor constant:-12],
        [self.editStatusView.centerYAnchor constraintEqualToAnchor:self.editCancelButton.centerYAnchor],
        [self.editStatusView.heightAnchor constraintEqualToConstant:20],
        
        // Constrain the edit status label.
        [self.editStatusLabel.trailingAnchor constraintEqualToAnchor:self.editStatusView.trailingAnchor constant:-12], 
        [self.editStatusLabel.centerYAnchor constraintEqualToAnchor:self.editStatusView.centerYAnchor],

        // Constrain the edit status image.
        [self.editStatusImageView.trailingAnchor constraintEqualToAnchor:self.editStatusLabel.leadingAnchor constant:-2],
        [self.editStatusImageView.centerYAnchor constraintEqualToAnchor:self.editStatusView.centerYAnchor],
        [self.editStatusImageView.widthAnchor constraintEqualToConstant:16],
        [self.editStatusImageView.heightAnchor constraintEqualToConstant:16],
        
        // Position the cancel button on the right.
        [self.editCancelButton.trailingAnchor constraintEqualToAnchor:self.editConfirmButton.leadingAnchor constant:-12],
        [self.editCancelButton.centerYAnchor constraintEqualToAnchor:self.editEmojiButton.centerYAnchor],
        [self.editCancelButton.widthAnchor constraintEqualToConstant:50],
        [self.editCancelButton.heightAnchor constraintEqualToConstant:28],
        
        // Position the confirm button at the trailing edge.
        [self.editConfirmButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
        [self.editConfirmButton.centerYAnchor constraintEqualToAnchor:self.editEmojiButton.centerYAnchor],
        [self.editConfirmButton.widthAnchor constraintEqualToConstant:50],
        [self.editConfirmButton.heightAnchor constraintEqualToConstant:28]
    ]];
}

#pragma mark - Height Calculation

- (CGFloat)calculateInputTextViewHeight {
    CGFloat minHeight = [self getTextViewHeightWithLines:1];
    
    if (!self.inputTextView.text || self.inputTextView.text.length == 0) {
        return minHeight;
    }
    
    CGSize targetSize = CGSizeMake(self.inputTextView.frame.size.width, CGFLOAT_MAX);
    CGSize fittingSize = [self.inputTextView sizeThatFits:targetSize];
    CGFloat calculatedHeight = fittingSize.height;
    
    // Clamp the text view between its minimum and maximum heights.
    CGFloat maxHeight = [self getTextViewHeightWithLines:self.maxInputLines];
    CGFloat finalHeight = MAX(minHeight, MIN(calculatedHeight, maxHeight));
    
    return finalHeight;
}

- (CGFloat)getTextViewHeightWithLines:(NSInteger)lines {
    CGFloat totalHeight = lines * TextViewLineHeight + TextViewSpaceHeight_LessThanMax;
    if (lines >= self.maxInputLines) {
        totalHeight = lines * TextViewLineHeight + TextViewSpaceHeight;
    }
    return totalHeight;
}

- (void)updateContainerHeight {
    // Calculate the total compact container height.
    CGFloat padding = 8;
    CGFloat buttonRowHeight = 28;
    CGFloat rowSpacing = 8;
    CGFloat referenceHeight = self.hasReferenceMessage ? 27 : 0;
    CGFloat bottomPadding = self.hasReferenceMessage ? 4 : 12;
    
    CGFloat totalHeight = padding; // Top padding.
    
    if (self.hasReferenceMessage) {
        totalHeight += referenceHeight + rowSpacing; // Reference row and spacing.
    }
    
    totalHeight += [self calculateInputTextViewHeight]; // Text input height.
    totalHeight += rowSpacing; // Space above the action row.
    totalHeight += buttonRowHeight; // Action row height.
    totalHeight += bottomPadding; // Bottom padding.
    
    // Update the container frame.
    CGRect newFrame = self.frame;
    newFrame.size.height = totalHeight;
    self.frame = newFrame;
    
    // Notify the delegate of the new height.
    if ([self.delegate respondsToSelector:@selector(editInputContainerView:didChangeFrame:)]) {
        [self.delegate editInputContainerView:self didChangeFrame:self.frame];
    }
}

- (void)updateTextViewScrollBehavior {
    if (self.heightMode == NCEditHeightModeExpanded) {
        // Scrolling is always enabled in expanded mode.
        self.inputTextView.scrollEnabled = YES;
    } else {
        // In compact mode, enable scrolling only beyond the visible line limit.
        CGFloat maxHeight = [self getTextViewHeightWithLines:self.maxInputLines];
        CGFloat currentHeight = [self calculateInputTextViewHeight];
        BOOL shouldEnableScroll = currentHeight >= maxHeight;
        
        self.inputTextView.scrollEnabled = shouldEnableScroll;
    }
}

#pragma mark - Text Changes

- (void)handleTextChange {
    // Update text view scrolling for the current content height.
    [self updateTextViewScrollBehavior];
    
    if (self.heightMode == NCEditHeightModeNormal) {
        // Update the compact text view height constraint.
        CGFloat newHeight = [self calculateInputTextViewHeight];
        if (self.inputTextViewHeightConstraint) {
            self.inputTextViewHeightConstraint.constant = newHeight;
        }
        
        // Recalculate the compact container height.
        [self updateContainerHeight];
        
        // Animate the resulting layout change.
        [UIView animateWithDuration:0.2 animations:^{
            [self layoutIfNeeded];
        }];
    }
    // Expanded mode uses a fixed container layout.
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // Forward the text change to the delegate.
    if ([self.delegate respondsToSelector:@selector(editInputContainerView:inputTextView:shouldChangeTextInRange:replacementText:)]) {
        return [self.delegate editInputContainerView:self inputTextView:textView shouldChangeTextInRange:range replacementText:text];
    }
    
    return YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.textViewBeginEditing = YES;
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.textViewBeginEditing = NO;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self handleTextChange];
    
    // Forward return-key handling to the delegate.
    if ([self.delegate respondsToSelector:@selector(editInputContainerView:inputTextViewDidChange:)]) {
        [self.delegate editInputContainerView:self inputTextViewDidChange:textView];
    }
}

#pragma mark - NCTextViewDelegate

- (void)nctextView:(NCTextView *)textView textDidChange:(NSString *)text {
    [self handleTextChange];
}

#pragma mark - Button Actions

- (void)editExpandButtonTapped:(UIButton *)sender {
    if (self.heightMode == NCEditHeightModeNormal) {
        // Expand to full-screen editing.
        if ([self.delegate respondsToSelector:@selector(editInputContainerViewRequestFullScreenEdit:)]) {
            [self.delegate editInputContainerViewRequestFullScreenEdit:self];
        }
    } else {
        // Collapse to compact editing.
        if ([self.delegate respondsToSelector:@selector(editInputContainerViewCollapseFromFullScreenEdit:)]) {
            [self.delegate editInputContainerViewCollapseFromFullScreenEdit:self];
        }
    }
}

- (void)editConfirmButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(editInputContainerViewEditConfirm:withText:)]) {
        [self.delegate editInputContainerViewEditConfirm:self withText:self.inputTextView.text];
    }
}

- (void)editCancelButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(editInputContainerViewEditCancel:)]) {
        [self.delegate editInputContainerViewEditCancel:self];
    }
}

- (void)editEmojiButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(editInputContainerViewEditEmojiButtonClicked:)]) {
        [self.delegate editInputContainerViewEditEmojiButtonClicked:self];
    }
}

#pragma mark - Public Methods

- (void)setReferencedContentWithSenderName:(NSString *)senderName content:(NSString *)content {
    self.referencedSenderName = senderName;
    self.referencedContent = content;
    self.hasReferenceMessage = (senderName.length > 0 || content.length > 0);
    
    if (self.hasReferenceMessage) {
        
        [self updateReferencedContent];
    }
    self.referencedLabel.hidden = !self.hasReferenceMessage;
    
    // Rebuild constraints only in compact mode; expanded mode always reserves the reference row.
    if (self.heightMode == NCEditHeightModeNormal) {
        [self updateEditConstraints];
    }
}

- (void)clearReferencedMessage {
    [self setReferencedContentWithSenderName:nil content:nil];
}

- (void)setInputText:(NSString *)text {
    self.inputTextView.text = text;
    [self handleTextChange];
}

- (NSString *)getInputText {
    return self.inputTextView.text ?: @"";
}

- (void)becomeInputViewFirstResponder {
    // Avoid redundant first-responder transitions that can disturb input state.
    if (![self.inputTextView isFirstResponder]) {
        [self.inputTextView becomeFirstResponder];
    }
}

- (void)resignInputViewFirstResponder {
    // Avoid a redundant responder transition.
    if ([self.inputTextView isFirstResponder]) {
        [self.inputTextView resignFirstResponder];
    }
}

- (void)setEditStatus:(NSString *)statusText {
    self.editStatusLabel.text = statusText ?: @"";
    self.editStatusView.hidden = (statusText.length == 0);
}

- (void)setEditEnabled:(BOOL)enabled withStatusMessage:(nullable NSString *)statusMessage {
    // Apply the edit status message.
    [self setEditStatus:statusMessage];
    
    // Update the confirm button state.
    self.editConfirmButton.enabled = enabled;
    if (enabled) {
        self.editConfirmButton.backgroundColor = NCDynamicColor(@"primary_color");
    } else {
        self.editConfirmButton.backgroundColor = NCDynamicColor(@"disabled_color");
    }
}

#pragma mark - Private Methods

- (void)updateReferencedContent {
    if (self.hasReferenceMessage) {
        // Display the current referenced-message content.
        NSString *senderName = self.referencedSenderName ?: @"";
        NSString *messageContent = self.referencedContent ?: @"";
        self.referencedLabel.text = [NSString stringWithFormat:@"%@: %@", senderName, messageContent];
    }
}

- (void)updateExpandButtonIcon {
    NSString *icon = (self.heightMode == NCEditHeightModeExpanded) ? @"edit_collapse" : @"edit_expand";
    NSString *iconKey = (self.heightMode == NCEditHeightModeExpanded) ? @"channel_msg_edit_collapse_img" : @"channel_msg_edit_expand_img";
    [self.editExpandButton setImage:NCDynamicImage(iconKey) forState:UIControlStateNormal];
}

#pragma mark - Getter

- (UILabel *)referencedLabel {
    if (!_referencedLabel) {
        _referencedLabel = [[UILabel alloc] init];
        _referencedLabel.hidden = YES;
        _referencedLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _referencedLabel.font = [UIFont systemFontOfSize:14];
        _referencedLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _referencedLabel.numberOfLines = 1;
        _referencedLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        // Preserve the label's intrinsic height.
        [_referencedLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        [_referencedLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        
        // Allow horizontal truncation before the row collapses.
        [_referencedLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_referencedLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _referencedLabel;
}

- (UIView *)inputContainerBackgroundView {
    if (!_inputContainerBackgroundView) {
        _inputContainerBackgroundView = [[UIView alloc] init];
        _inputContainerBackgroundView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        _inputContainerBackgroundView.layer.cornerRadius = 6;
        _inputContainerBackgroundView.layer.masksToBounds = YES;
    }
    return _inputContainerBackgroundView;
}

- (NCTextView *)inputTextView {
    if (!_inputTextView) {
        _inputTextView = [[NCTextView alloc] init];
        _inputTextView.delegate = self;
        _inputTextView.textChangeDelegate = self;
        
        // Configure text container padding.
        UIEdgeInsets textEdge = _inputTextView.textContainerInset;
        textEdge.left = 5;
        textEdge.right = 5;
        _inputTextView.textContainerInset = textEdge;
        
        // Apply the input view appearance.
        _inputTextView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        _inputTextView.layer.borderWidth = 0;
        _inputTextView.layer.cornerRadius = 0;
        UIColor *textColor = NCDynamicColor(@"text_primary_color");
        [_inputTextView setTextColor:textColor];
        [_inputTextView setFont:[[NCChatUIConfig defaultConfig].font fontOfSecondLevel]];
        [_inputTextView setReturnKeyType:UIReturnKeySend];
        _inputTextView.enablesReturnKeyAutomatically = YES;
        [_inputTextView setExclusiveTouch:YES];
        [_inputTextView setAccessibilityLabel:@"edit_input_textView"];
    }
    return _inputTextView;
}

- (UIButton *)editExpandButton {
    if (!_editExpandButton) {
        _editExpandButton = [[UIButton alloc] init];
        [_editExpandButton setImage:NCDynamicImage(@"channel_msg_edit_expand_img") forState:UIControlStateNormal];
        _editExpandButton.layer.masksToBounds = YES;
        [_editExpandButton addTarget:self
                              action:@selector(editExpandButtonTapped:)
                    forControlEvents:UIControlEventTouchUpInside];
    }
    return _editExpandButton;
}

- (UIButton *)editConfirmButton {
    if (!_editConfirmButton) {
        _editConfirmButton = [[UIButton alloc] init];
        [_editConfirmButton setImage:NCDynamicImage(@"channel_msg_edit_confirm_img") forState:UIControlStateNormal];
        _editConfirmButton.backgroundColor = NCDynamicColor(@"primary_color");
        _editConfirmButton.layer.cornerRadius = 4;
        _editConfirmButton.layer.masksToBounds = YES;
        [_editConfirmButton addTarget:self
                               action:@selector(editConfirmButtonTapped:)
                     forControlEvents:UIControlEventTouchUpInside];
    }
    return _editConfirmButton;
}

- (UIButton *)editCancelButton {
    if (!_editCancelButton) {
        _editCancelButton = [[UIButton alloc] init];
        [_editCancelButton setImage:NCDynamicImage(@"channel_msg_edit_cancel_img") forState:UIControlStateNormal];
        _editCancelButton.backgroundColor = NCDynamicColor(@"common_background_color");
        _editCancelButton.layer.cornerRadius = 4;
        _editCancelButton.layer.borderWidth = 0.5;
        UIColor *borderColor = NCDynamicColor(@"line_background_color");
        _editCancelButton.layer.borderColor = borderColor.CGColor;
        _editCancelButton.layer.masksToBounds = YES;
        [_editCancelButton addTarget:self
                              action:@selector(editCancelButtonTapped:)
                    forControlEvents:UIControlEventTouchUpInside];
    }
    return _editCancelButton;
}

- (UIButton *)editEmojiButton {
    if (!_editEmojiButton) {
        _editEmojiButton = [[UIButton alloc] init];
        [_editEmojiButton setImage:NCDynamicImage(@"channel_msg_edit_emoji_img") forState:UIControlStateNormal];
        _editEmojiButton.layer.cornerRadius = 14;
        _editEmojiButton.layer.masksToBounds = YES;
        [_editEmojiButton addTarget:self
                             action:@selector(editEmojiButtonTapped:)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _editEmojiButton;
}

- (void)setMaxInputLines:(NSInteger)maxInputLines {
    if (maxInputLines > TextViewMaxInputLines) {
        maxInputLines = TextViewMaxInputLines;
    }
    if (maxInputLines < TextViewMinInputLines) {
        maxInputLines = TextViewMinInputLines;
    }
    _maxInputLines = maxInputLines;
    
    // Recalculate height after the font changes.
    [self handleTextChange];
}

- (UIView *)topBorderView {
    if (!_topBorderView) {
        _topBorderView = [[UIView alloc] init];
        _topBorderView.backgroundColor = NCDynamicColor(@"line_background_color");
    }
    return _topBorderView;
}

- (UIView *)editStatusView {
    if (!_editStatusView) {
        _editStatusView = [[UIView alloc] init];
        _editStatusView.hidden = YES;
    }
    return _editStatusView;
}

- (UIImageView *)editStatusImageView {
    if (!_editStatusImageView) {
        _editStatusImageView = [[UIImageView alloc] init];
        _editStatusImageView.image = NCDynamicImage(@"channel_msg_edit_status_expired_img");
    }
    return _editStatusImageView;
}

- (UILabel *)editStatusLabel {
    if (!_editStatusLabel) {
        _editStatusLabel = [[UILabel alloc] init];
        _editStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _editStatusLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
        _editStatusLabel.textColor = NCDynamicColor(@"hint_color"); // Use the configured hint color.
        _editStatusLabel.textAlignment = NSTextAlignmentRight;
        _editStatusLabel.numberOfLines = 1;
        _editStatusLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        // Preserve the status label's intrinsic width.
        [_editStatusLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_editStatusLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _editStatusLabel;
}

@end
