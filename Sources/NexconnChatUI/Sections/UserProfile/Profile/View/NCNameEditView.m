//
//  NCNameEditView.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCNameEditView.h"
#import "NCChatUICommonDefine.h"

#define NCNameEditViewPadding 16
#define NCNameEditViewTipFont 13.5
#define NCNameEditViewContentFont 17

@interface NCNameEditView ()

@property (nonatomic, strong) UIView *editView;

@end

@implementation NCNameEditView

#pragma mark-- private

- (void)setupView {
    [super setupView];
    self.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    [self addSubview:self.editView];
    [self addSubview:self.tipLabel];
    [self.editView addSubview:self.contentLabel];
    [self.editView addSubview:self.textField];
    UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    // Require a single tap.
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
    self.userInteractionEnabled = YES;

    if ([NCChatUIUtility isRTL]) {
        self.textField.textAlignment = NSTextAlignmentRight;
    } else {
        self.textField.textAlignment = NSTextAlignmentLeft;
    }
}

- (void)setupConstraints {
    [super setupConstraints];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor
                                                        constant:NCNameEditViewPadding],
        [self.contentLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor
                                                         constant:-NCNameEditViewPadding],
        [self.contentLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.contentLabel.bottomAnchor constraintEqualToAnchor:self.editView.topAnchor
                                                       constant:-10],

        [self.editView.leadingAnchor constraintEqualToAnchor:self.contentLabel.leadingAnchor],
        [self.editView.trailingAnchor constraintEqualToAnchor:self.contentLabel.trailingAnchor],
        [self.editView.heightAnchor constraintEqualToConstant:42],

        [self.textField.leadingAnchor constraintEqualToAnchor:self.editView.leadingAnchor
                                                     constant:12],
        [self.textField.trailingAnchor constraintEqualToAnchor:self.editView.trailingAnchor
                                                      constant:-12],
        [self.textField.centerYAnchor constraintEqualToAnchor:self.editView.centerYAnchor],

        [self.tipLabel.leadingAnchor constraintEqualToAnchor:self.editView.leadingAnchor],
        [self.tipLabel.trailingAnchor constraintEqualToAnchor:self.editView.trailingAnchor],
        [self.tipLabel.topAnchor constraintEqualToAnchor:self.editView.bottomAnchor
                                                constant:NCNameEditViewPadding]
    ]];
}

- (void)handleTap {
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
}

#pragma mark-- getter

- (UIView *)editView {
    if (!_editView) {
        _editView = [[UIView alloc] init];
        _editView.translatesAutoresizingMaskIntoConstraints = NO;
        _editView.backgroundColor = NCDynamicColor(@"common_background_color");
    }
    return _editView;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        [_textField setTextColor:NCDynamicColor(@"text_primary_color")];
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _textField;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:NCNameEditViewContentFont];
        _contentLabel.accessibilityLabel = @"contentLabel";
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contentLabel;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _tipLabel.font = [UIFont systemFontOfSize:NCNameEditViewTipFont];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.numberOfLines = 0;
        _tipLabel.accessibilityLabel = @"tipLabel";
        _tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _tipLabel;
}
@end
