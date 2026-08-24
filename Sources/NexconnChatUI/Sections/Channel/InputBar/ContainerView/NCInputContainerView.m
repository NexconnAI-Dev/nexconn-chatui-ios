//
//  NCInputContainerView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCInputContainerView.h"
#import "NCChatSessionInputBarControl.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIExtensionService.h"
#define TextViewLineHeight 20.f              // Text height per input line
#define TextViewSpaceHeight_LessThanMax 17.f // Vertical padding below the maximum line count
#define TextViewSpaceHeight 13.f             // Vertical padding at or above the maximum line count
#define TextViewRectY 7
#define TextViewMaxInputLines 6 // Maximum input line count
#define TextViewMinInputLines 1 // Minimum input line count
@interface NCInputContainerView () <UITextViewDelegate, NCTextViewDelegate> {
    BOOL _hideEmojiButton;
}
@property (nonatomic, strong) NSMutableArray *inputContainerSubViewConstraints;
@property (nonatomic, assign) BOOL textViewBeginEditing;
@property (nonatomic, assign) NCChatSessionInputBarControlStyle style;
@end
@implementation NCInputContainerView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self nc_commonInit];
    }
    return self;
}

- (void)nc_commonInit {
    self.maxInputLines = 4;
}

- (BOOL)hideEmojiButton {
    return _hideEmojiButton;
}

- (void)setHideEmojiButton:(BOOL)hideEmojiButton {
    if (hideEmojiButton != _hideEmojiButton) {
        _hideEmojiButton = hideEmojiButton;
        [self resetInputContainerView];
        [self setupSubViews];
        [self setLayoutForInputContainerView:self.style];
    }
}
#pragma mark - Public API
- (void)setInputBarStyle:(NCChatSessionInputBarControlStyle)style {
    self.style = style;
    [self resetInputContainerView];
    [self setupSubViews];
    [self setLayoutForInputContainerView:style];
}

- (void)setBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus {
    _currentBottomBarStatus = bottomBarStatus;
    switch (bottomBarStatus) {
    case KBottomBarRecordStatus: {
        [self inputTextViewBecomeFirstResponder:NO];
        [self switchToRecord];
    } break;
    case KBottomBarKeyboardStatus: {
        [self inputTextViewBecomeFirstResponder:YES];
        [self showInputTextView];
    } break;
    case KBottomBarDefaultStatus:
    case KBottomBarPluginStatus:
    case KBottomBarEmojiStatus:
    default:
        [self inputTextViewBecomeFirstResponder:NO];
        [self showInputTextView];
        break;
    }
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text {
    BOOL isShould = [self.delegate inputTextView:textView
                         shouldChangeTextInRange:range
                                 replacementText:text];
    if ([text isEqualToString:@"\n"]) {
        self.inputTextView.text = @"";
        [self textViewDidChange:textView];
    } else {
        [self changeInputTextViewRange];
    }

    [[NCChatUIExtensionService sharedService]
        inputTextViewDidChange:textView
                    inInputBar:(NCChatSessionInputBarControl *)self.superview];
    return isShould;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    NCLogD(@"%s, %@", __FUNCTION__, textView);
    self.textViewBeginEditing = YES;
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    NCLogD(@"%s, %@", __FUNCTION__, textView.text);
    self.textViewBeginEditing = NO;
    // filter the space
}

- (void)textViewDidChange:(UITextView *)textView {
    [self inputTextViewDidChange:textView];
}

#pragma mark - NCTextViewDelegate
- (void)nctextView:(NCTextView *)textView textDidChange:(NSString *)text {
    [self.inputTextView layoutIfNeeded];
    [self inputTextViewDidChange:textView];
}

#pragma mark - Target Action
- (void)switchInputBoxOrRecord {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(inputContainerViewSwitchButtonClicked:)]) {
        [self.delegate inputContainerViewSwitchButtonClicked:self];
    }
}

- (void)voiceRecordButtonTouchDown:(UIButton *)sender {
    sender.backgroundColor = NCDynamicColor(@"auxiliary_background_2_color");
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchDown];
    }
}

- (void)voiceRecordButtonTouchUpInside:(UIButton *)sender {
    sender.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)voiceRecordButtonTouchCancel:(UIButton *)sender {
    sender.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchCancel];
    }
}

- (void)voiceRecordButtonTouchDragExit:(UIButton *)sender {
    sender.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchDragExit];
    }
}

- (void)voiceRecordButtonTouchDragEnter:(UIButton *)sender {

    sender.backgroundColor = NCDynamicColor(@"auxiliary_background_2_color");
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchDragEnter];
    }
}

- (void)voiceRecordButtonTouchUpOutside:(UIButton *)sender {
    sender.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(inputContainerView:forControlEvents:)]) {
        [self.delegate inputContainerView:self forControlEvents:UIControlEventTouchUpOutside];
    }
}

- (void)didTouchEmojiDown:(UIButton *)sender {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(inputContainerViewEmojiButtonClicked:)]) {
        [self.delegate inputContainerViewEmojiButtonClicked:self];
    }
}

- (void)didTouchAddtionalDown:(UIButton *)sender {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(inputContainerViewAdditionalButtonClicked:)]) {
        [self.delegate inputContainerViewAdditionalButtonClicked:self];
    }
}

#pragma mark - Private Methods
- (void)inputTextViewDidChange:(UITextView *)textView {
    [self changeInputTextViewRange];
    [[NCChatUIExtensionService sharedService]
        inputTextViewDidChange:textView
                    inInputBar:(NCChatSessionInputBarControl *)self.superview];
    if ([self.delegate respondsToSelector:@selector(inputTextViewDidChange:)]) {
        [self.delegate inputTextViewDidChange:textView];
    }
}

- (void)inputTextViewBecomeFirstResponder:(BOOL)isBecome {
    if (isBecome && ![self.inputTextView isFirstResponder]) {
        [self.inputTextView becomeFirstResponder];
    }
    if (!isBecome && [self.inputTextView isFirstResponder]) {
        [self.inputTextView resignFirstResponder];
    }
}

#pragma mark - UI
- (void)setupSubViews {
    [self addSubview:self.switchButton];
    [self addSubview:self.inputTextView];
    [self addSubview:self.recordButton];
    [self addSubview:self.emojiButton];
    [self addSubview:self.additionalButton];
}

- (void)showInputTextView {
    [self layoutInputBoxUIIfNeed];
    [self updateButtonImage];
}

- (void)switchToRecord {
    [self layoutInputBoxUIIfNeed];
    [self updateButtonImage];
}

- (void)updateButtonImage {
    if (self.currentBottomBarStatus != KBottomBarEmojiStatus) {
        [self.emojiButton setImage:NCDynamicImage(@"channel_input_bar_emoji_img")
                          forState:UIControlStateNormal];
    } else {
        [self.emojiButton setImage:NCDynamicImage(@"channel_input_bar_keyboard_img")
                          forState:UIControlStateNormal];
    }

    NSString *iconKey = self.recordButton.hidden ? @"channel_input_bar_voice_img"
                                                 : @"channel_input_bar_keyboard_img";
    [self.switchButton setImage:NCDynamicImage(iconKey) forState:UIControlStateNormal];
}

- (void)layoutInputBoxUIIfNeed {
    CGFloat changedBeforeHeight = self.frame.size.height;
    CGRect rectFrame = self.frame;
    if (self.currentBottomBarStatus == KBottomBarRecordStatus) {
        self.inputTextView.hidden = YES;
        self.recordButton.hidden = NO;
        rectFrame.size.height = NC_ChatSessionInputBar_Height;
    } else {
        self.recordButton.hidden = YES;
        self.inputTextView.hidden = NO;

        self.inputTextView.frame = [self getInputTextViewFrame];
        rectFrame.size.height =
            NC_ChatSessionInputBar_Height +
            (self.inputTextView.frame.size.height - [self getTextViewHeightWithLines:1]);
    }

    if (changedBeforeHeight != rectFrame.size.height) {
        self.frame = rectFrame;
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(inputContainerView:didChangeFrame:)]) {
            [self.delegate inputContainerView:self didChangeFrame:self.frame];
        }
    }
}

- (void)changeInputTextViewRange {
    CGFloat changedBeforeHeight = self.frame.size.height;
    [self layoutInputBoxUIIfNeed];
    if (changedBeforeHeight != self.frame.size.height && self.inputTextView.text > 0) {
        [UIView
            animateWithDuration:0.5
                     animations:^{
                       [self.inputTextView scrollRangeToVisible:[self.inputTextView selectedRange]];
                     }];
    }
}

- (CGRect)getInputTextViewFrame {
    CGFloat inputTextview_height = [self getTextViewHeightWithLines:1];
    if (self.inputTextView.contentSize.height > [self getTextViewHeightWithLines:1] &&
        self.inputTextView.contentSize.height <=
            [self getTextViewHeightWithLines:self.maxInputLines - 1]) {
        inputTextview_height = self.inputTextView.contentSize.height;
    }
    if (self.inputTextView.contentSize.height >
        [self getTextViewHeightWithLines:self.maxInputLines - 1]) {
        inputTextview_height = [self getTextViewHeightWithLines:self.maxInputLines];
    }
    CGRect inputTextRect = self.inputTextView.frame;
    inputTextRect.size.height = inputTextview_height;
    inputTextRect.origin.y = TextViewRectY;
    return inputTextRect;
}

- (CGFloat)getTextViewHeightWithLines:(NSInteger)lines {
    CGFloat totalHeight = lines * TextViewLineHeight + TextViewSpaceHeight_LessThanMax;
    if (lines >= self.maxInputLines) {
        totalHeight = lines * TextViewLineHeight + TextViewSpaceHeight;
    }
    return totalHeight;
}

- (void)resetInputContainerView {
    if (self.inputContainerSubViewConstraints.count > 0) {
        [self removeConstraints:self.inputContainerSubViewConstraints];
        [self.inputContainerSubViewConstraints removeAllObjects];
    }

    if (self.switchButton) {
        [self.switchButton removeFromSuperview];
        self.switchButton = nil;
    }
    if (self.recordButton) {
        [self.recordButton removeFromSuperview];
        self.recordButton = nil;
    }
    if (self.inputTextView) {
        [self.inputTextView removeFromSuperview];
        if (self.inputTextView.text.length <= 0) {
            self.inputTextView = nil;
        }
    }
    if (self.emojiButton) {
        [self.emojiButton removeFromSuperview];
        self.emojiButton = nil;
    }
    if (self.additionalButton) {
        [self.additionalButton removeFromSuperview];
        self.additionalButton = nil;
    }
}

- (void)setLayoutForInputContainerView:(NCChatSessionInputBarControlStyle)style {
    self.switchButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.recordButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.emojiButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.additionalButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputTextView.translatesAutoresizingMaskIntoConstraints = NO;

    NSDictionary *_bindingViews = NSDictionaryOfVariableBindings(
        _switchButton, _inputTextView, _recordButton, _emojiButton, _additionalButton);

    NSString *format;

    switch (style) {
    case NC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION:
        format = @"H:|-8-[_switchButton(BUTTONWIDTH)]-8-[_recordButton]-8-[_emojiButton("
                 @"EMOJIBUTTONWIDTH)]-8-[_additionalButton(BUTTONWIDTH)]-8-|";
        break;
    case NC_CHAT_INPUT_BAR_STYLE_EXTENTION_CONTAINER_SWITCH:
        format = @"H:|-8-[_additionalButton(BUTTONWIDTH)]-8-[_recordButton]-8-[_"
                 @"emojiButton(EMOJIBUTTONWIDTH)]-8-[_switchButton(BUTTONWIDTH)]-8-|";
        break;
    case NC_CHAT_INPUT_BAR_STYLE_CONTAINER_SWITCH_EXTENTION:
        format = @"H:|-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-[_switchButton("
                 @"BUTTONWIDTH)]-8-[_additionalButton(BUTTONWIDTH)]-8-|";
        break;
    case NC_CHAT_INPUT_BAR_STYLE_CONTAINER_EXTENTION_SWITCH:
        format = @"H:|-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-[_"
                 @"additionalButton(BUTTONWIDTH)]-8-[_switchButton(BUTTONWIDTH)]-8-|";
        break;
    case NC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER:
        format = @"H:|-8-[_switchButton(BUTTONWIDTH)]-8-[_recordButton]-8-[_emojiButton("
                 @"EMOJIBUTTONWIDTH)]-8-[_additionalButton(0)]-8-|";
        break;
    case NC_CHAT_INPUT_BAR_STYLE_CONTAINER_SWITCH:
        format = @"H:|-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-[_switchButton("
                 @"BUTTONWIDTH)]-8-[_additionalButton(0)]-8-|";
        break;
    case NC_CHAT_INPUT_BAR_STYLE_EXTENTION_CONTAINER:
        format = @"H:|-8-[_additionalButton(BUTTONWIDTH)]-8-[_recordButton]-8-[_"
                 @"emojiButton(EMOJIBUTTONWIDTH)]-8-[_switchButton(0)]-8-|";
        break;
    case NC_CHAT_INPUT_BAR_STYLE_CONTAINER_EXTENTION:
        format = @"H:|-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)]-8-[_"
                 @"additionalButton(BUTTONWIDTH)]-8-[_switchButton(0)]-8-|";
        break;
    case NC_CHAT_INPUT_BAR_STYLE_CONTAINER:
        format = @"H:|-0-[_switchButton(0)]-8-[_recordButton]-8-[_emojiButton(EMOJIBUTTONWIDTH)"
                 @"]-8-[_additionalButton(0)]-8-|";
        break;
    default:
        break;
    }

    NSInteger emojiBtnWidth = self.hideEmojiButton ? 0 : 32;
    [self.inputContainerSubViewConstraints
        addObjectsFromArray:[NSLayoutConstraint
                                constraintsWithVisualFormat:format
                                                    options:0
                                                    metrics:@{
                                                        @"BUTTONWIDTH" : @(32),
                                                        @"EMOJIBUTTONWIDTH" : @(emojiBtnWidth)
                                                    }
                                                      views:_bindingViews]];

    [self.inputContainerSubViewConstraints
        addObjectsFromArray:[NSLayoutConstraint
                                constraintsWithVisualFormat:@"V:|-8.5-[_switchButton(BUTTONWIDTH)]"
                                                    options:0
                                                    metrics:@{@"BUTTONWIDTH" : @(32)}
                                                      views:_bindingViews]];
    [self.inputContainerSubViewConstraints
        addObjectsFromArray:[NSLayoutConstraint
                                constraintsWithVisualFormat:@"V:|-6-[_recordButton(36)]"
                                                    options:0
                                                    metrics:nil
                                                      views:_bindingViews]];

    [self.inputContainerSubViewConstraints
        addObjectsFromArray:[NSLayoutConstraint
                                constraintsWithVisualFormat:@"V:|-8.5-[_emojiButton(BUTTONWIDTH)]"
                                                    options:kNilOptions
                                                    metrics:@{@"BUTTONWIDTH" : @(32)}
                                                      views:_bindingViews]];

    [self.inputContainerSubViewConstraints
        addObjectsFromArray:
            [NSLayoutConstraint
                constraintsWithVisualFormat:@"V:|-8.5-[_additionalButton(BUTTONWIDTH)]"
                                    options:kNilOptions
                                    metrics:@{@"BUTTONWIDTH" : @(32)}
                                      views:_bindingViews]];

    [self.inputContainerSubViewConstraints
        addObjectsFromArray:@[ [NSLayoutConstraint
                                constraintWithItem:self.recordButton
                                         attribute:NSLayoutAttributeLeft
                                         relatedBy:(NSLayoutRelationEqual)toItem:self.inputTextView
                                         attribute:NSLayoutAttributeLeft
                                        multiplier:1
                                          constant:0] ]];

    [self.inputContainerSubViewConstraints
        addObjectsFromArray:@[ [NSLayoutConstraint
                                constraintWithItem:self.recordButton
                                         attribute:NSLayoutAttributeRight
                                         relatedBy:(NSLayoutRelationEqual)toItem:self.inputTextView
                                         attribute:NSLayoutAttributeRight
                                        multiplier:1
                                          constant:0] ]];

    [self.inputContainerSubViewConstraints
        addObjectsFromArray:@[ [NSLayoutConstraint
                                constraintWithItem:self.recordButton
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:(NSLayoutRelationEqual)toItem:self.inputTextView
                                         attribute:NSLayoutAttributeTop
                                        multiplier:1
                                          constant:0] ]];

    [self.inputContainerSubViewConstraints
        addObjectsFromArray:@[ [NSLayoutConstraint
                                constraintWithItem:self.inputTextView
                                         attribute:NSLayoutAttributeBottom
                                         relatedBy:(NSLayoutRelationEqual)toItem:self
                                         attribute:NSLayoutAttributeBottom
                                        multiplier:1
                                          constant:-6] ]];

    [self addConstraints:self.inputContainerSubViewConstraints];

    [self updateConstraintsIfNeeded];
    [self layoutIfNeeded];
}

#pragma mark - Getter & Setter
- (NCButton *)switchButton {
    if (!_switchButton) {
        _switchButton = [[NCButton alloc] initWithFrame:CGRectZero];
        [_switchButton setImage:NCDynamicImage(@"channel_input_bar_voice_img")
                       forState:UIControlStateNormal];
        [_switchButton addTarget:self
                          action:@selector(switchInputBoxOrRecord)
                forControlEvents:UIControlEventTouchUpInside];
        [_switchButton setExclusiveTouch:YES];
    }
    return _switchButton;
}

- (NCTextView *)inputTextView {
    if (!_inputTextView) {
        _inputTextView = [[NCTextView alloc] initWithFrame:CGRectZero];
        _inputTextView.delegate = self;
        _inputTextView.textChangeDelegate = self;
        UIEdgeInsets textEdge = self.inputTextView.textContainerInset;
        textEdge.left = 5;
        textEdge.right = 5;

        _inputTextView.textContainerInset = textEdge;
        [_inputTextView setExclusiveTouch:YES];
        UIColor *textColor = NCDynamicColor(@"text_primary_color");
        [_inputTextView setTextColor:textColor];
        [_inputTextView setFont:[[NCChatUIConfig defaultConfig].font fontOfSecondLevel]];
        [_inputTextView setReturnKeyType:UIReturnKeySend];
        _inputTextView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        _inputTextView.enablesReturnKeyAutomatically = YES;
        _inputTextView.layer.cornerRadius = 8;
        _inputTextView.layer.masksToBounds = YES;
        [_inputTextView setAccessibilityLabel:@"chat_input_textView"];
    }
    return _inputTextView;
}

- (NCButton *)recordButton {
    if (!_recordButton) {
        _recordButton = [[NCButton alloc] initWithFrame:CGRectZero];
        [_recordButton setExclusiveTouch:YES];
        [_recordButton setHidden:YES];
        [_recordButton setTitle:NCUILocalizedString(@"hold_to_talk_title")
                       forState:UIControlStateNormal];
        _recordButton.titleLabel.font = [[NCChatUIConfig defaultConfig].font fontOfGuideLevel];
        [_recordButton setTitle:NCUILocalizedString(@"release_to_send_title")
                       forState:UIControlStateHighlighted];
        [_recordButton setTitleColor:NCDynamicColor(@"text_primary_color")
                            forState:UIControlStateNormal];
        _recordButton.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchDown:)
                forControlEvents:UIControlEventTouchDown];
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchUpInside:)
                forControlEvents:UIControlEventTouchUpInside];
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchUpOutside:)
                forControlEvents:UIControlEventTouchUpOutside];
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchDragExit:)
                forControlEvents:UIControlEventTouchDragExit];
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchDragEnter:)
                forControlEvents:UIControlEventTouchDragEnter];
        [_recordButton addTarget:self
                          action:@selector(voiceRecordButtonTouchCancel:)
                forControlEvents:UIControlEventTouchCancel];
        _recordButton.layer.cornerRadius = 8;
        _recordButton.layer.masksToBounds = YES;
    }
    return _recordButton;
}

- (NCButton *)emojiButton {
    if (!_emojiButton) {
        _emojiButton = [[NCButton alloc] initWithFrame:CGRectZero];
        [_emojiButton setImage:NCDynamicImage(@"channel_input_bar_emoji_img")
                      forState:UIControlStateNormal];
        [_emojiButton setExclusiveTouch:YES];
        [_emojiButton addTarget:self
                         action:@selector(didTouchEmojiDown:)
               forControlEvents:UIControlEventTouchUpInside];
        _emojiButton.hidden = self.hideEmojiButton;
    }
    return _emojiButton;
}

- (NCButton *)additionalButton {
    if (!_additionalButton) {
        _additionalButton = [[NCButton alloc] initWithFrame:CGRectZero];
        [_additionalButton setImage:NCDynamicImage(@"channel_input_bar_add_img")
                           forState:UIControlStateNormal];
        [_additionalButton setExclusiveTouch:YES];
        [_additionalButton addTarget:self
                              action:@selector(didTouchAddtionalDown:)
                    forControlEvents:UIControlEventTouchUpInside];
    }
    return _additionalButton;
}

- (NSMutableArray *)inputContainerSubViewConstraints {
    if (!_inputContainerSubViewConstraints) {
        _inputContainerSubViewConstraints = [[NSMutableArray alloc] init];
    }
    return _inputContainerSubViewConstraints;
}

- (void)setMaxInputLines:(NSInteger)maxInputLines {
    if (maxInputLines > TextViewMaxInputLines) {
        maxInputLines = TextViewMaxInputLines;
    }
    if (maxInputLines < TextViewMinInputLines) {
        maxInputLines = TextViewMinInputLines;
    }
    _maxInputLines = maxInputLines;
}
@end
