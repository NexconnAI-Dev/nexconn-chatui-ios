//
//  NCGroupNoticeView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupNoticeView.h"
#import "NCChatUICommonDefine.h"
#define NCGroupNoticeViewTipFont 17
#define NCGroupNoticeViewTipBottom 30
#define NCGroupNoticeViewTextTop 10
#define NCGroupNoticeViewTextHeight 200
@interface NCGroupNoticeView ()
@property (nonatomic, strong) NSLayoutConstraint *textViewHeightConstraint;
@end

@implementation NCGroupNoticeView
- (void)setupConstraints {
    [super setupConstraints];
    self.textViewHeightConstraint =
        [self.textView.heightAnchor constraintEqualToConstant:NCGroupNoticeViewTextHeight];
    [NSLayoutConstraint activateConstraints:@[
        [self.textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor
                                                    constant:NCUserManagementViewPadding],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor
                                                     constant:-NCUserManagementViewPadding],
        [self.textView.topAnchor constraintEqualToAnchor:self.topAnchor
                                                constant:NCGroupNoticeViewTextTop],
        self.textViewHeightConstraint,
        [self.emptyLabel.leadingAnchor constraintEqualToAnchor:self.textView.leadingAnchor],
        [self.emptyLabel.trailingAnchor constraintEqualToAnchor:self.textView.trailingAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [self.emptyImageView.bottomAnchor constraintEqualToAnchor:self.emptyLabel.topAnchor
                                                         constant:-NCGroupNoticeViewTextTop],
        [self.emptyImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],

        [self.tipLabel.leadingAnchor constraintEqualToAnchor:self.textView.leadingAnchor],
        [self.tipLabel.trailingAnchor constraintEqualToAnchor:self.textView.trailingAnchor],
        [self.tipLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor
                                                   constant:-NCGroupNoticeViewTipBottom],
    ]];
}

- (void)showEmptylabel:(BOOL)show {
    self.textView.hidden = show;
    self.emptyLabel.hidden = !show;
    self.emptyImageView.hidden = !show;
}

- (void)updateTextViewHeight:(BOOL)canEdit {
    self.textView.editable = canEdit;
    if (!canEdit) {
        self.textView.backgroundColor = [UIColor clearColor];
        self.textViewHeightConstraint.active = NO;
        [NSLayoutConstraint activateConstraints:@[ [self.textView.bottomAnchor
                                                    constraintEqualToAnchor:self.tipLabel.topAnchor
                                                                   constant:-19] ]];
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark-- private

- (void)setupView {
    [super setupView];
    self.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    [self addSubview:self.textView];
    [self addSubview:self.tipLabel];
    [self addSubview:self.emptyImageView];
    [self addSubview:self.emptyLabel];
}

#pragma mark-- getter

- (NCPlaceholderTextView *)textView {
    if (!_textView) {
        _textView = [NCPlaceholderTextView new];
        _textView.font = [UIFont systemFontOfSize:NCGroupNoticeViewTipFont];
        _textView.placeholder = NCUILocalizedString(@"group_notice_edit_placeholder");
        _textView.placeholderColor = NCDynamicColor(@"disabled_color");
        [_textView setTextColor:NCDynamicColor(@"text_primary_color")];
        _textView.backgroundColor = NCDynamicColor(@"common_background_color");
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _textView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _tipLabel.font = [UIFont systemFontOfSize:12];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.numberOfLines = 0;
        _tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _tipLabel;
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] init];
        _emptyLabel.textColor = NCDynamicColor(@"text_primary_color");
        _emptyLabel.font = [UIFont systemFontOfSize:NCGroupNoticeViewTipFont];
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.numberOfLines = 0;
        _emptyLabel.text = NCUILocalizedString(@"group_notice_is_empty");
        _emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _emptyLabel;
}

- (UIImageView *)emptyImageView {
    if (!_emptyImageView) {
        _emptyImageView = [UIImageView new];
        _emptyImageView.image = NCDynamicImage(@"channel-list_no_message_img");
        _emptyImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_emptyImageView sizeToFit];
        _emptyImageView.hidden = YES;
    }
    return _emptyImageView;
}
@end
