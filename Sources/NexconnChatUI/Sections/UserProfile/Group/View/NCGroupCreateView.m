//
//  NCGroupCreateView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupCreateView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#define NCGroupCreateViewPortraitSize 70
#define NCGroupCreateViewNameTopSpace 20
#define NCGroupCreateViewCreateLeading 16
#define NCGroupCreateViewCreateBottom 40
#define NCGroupCreateViewCreateHeight 42

@interface NCGroupCreateView ()

@end

@implementation NCGroupCreateView

- (void)setupConstraints {
    [super setupConstraints];
    [NSLayoutConstraint activateConstraints:@[
        [self.portraitImageView.topAnchor constraintEqualToAnchor:self.topAnchor
                                                         constant:NCGroupCreateViewNameTopSpace],
        [self.portraitImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.portraitImageView.widthAnchor
            constraintEqualToConstant:NCGroupCreateViewPortraitSize],
        [self.portraitImageView.heightAnchor
            constraintEqualToConstant:NCGroupCreateViewPortraitSize],

        [self.nameEditView.topAnchor constraintEqualToAnchor:self.portraitImageView.bottomAnchor
                                                    constant:NCGroupCreateViewNameTopSpace],
        [self.nameEditView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.nameEditView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.nameEditView.heightAnchor
            constraintEqualToConstant:NCGroupCreateViewPortraitSize * 2],

        [self.createButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor
                                                       constant:-NCGroupCreateViewCreateBottom],
        [self.createButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor
                                                        constant:NCGroupCreateViewCreateLeading],
        [self.createButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor
                                                         constant:-NCGroupCreateViewCreateLeading],
        [self.createButton.heightAnchor constraintEqualToConstant:NCGroupCreateViewCreateHeight]
    ]];
}
#pragma mark-- private

- (void)setupView {
    [super setupView];
    self.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    [self addSubview:self.portraitImageView];
    [self addSubview:self.nameEditView];
    [self addSubview:self.createButton];
    UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    // Require a single tap.
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
    self.userInteractionEnabled = YES;
}

- (void)handleTap {
    if ([self.nameEditView.textField isFirstResponder]) {
        [self.nameEditView.textField resignFirstResponder];
    }
}

- (void)portraitImageViewTapped {
    [self.delegate portaitImageViewDidClick];
}

#pragma mark - getter

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[NCImageView alloc] init];
        if (NCChatUIConfigCenter.ui.globalConversationAvatarStyle == NC_USER_AVATAR_CYCLE &&
            NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = NCGroupCreateViewPortraitSize / 2;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView
            setPlaceholderImage:NCDynamicImage(@"channel-list_cell_group_portrait_img")];
        _portraitImageView.userInteractionEnabled = YES;

        // Add the tap gesture recognizer.
        UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(portraitImageViewTapped)];
        [_portraitImageView addGestureRecognizer:tapGesture];
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _portraitImageView;
}

- (NCNameEditView *)nameEditView {
    if (!_nameEditView) {
        _nameEditView = [[NCNameEditView alloc] init];
        _nameEditView.contentLabel.text = NCUILocalizedString(@"group_name");
        _nameEditView.textField.placeholder =
            NCUILocalizedString(@"group_name_edit_placeholder_with_limit");
        _nameEditView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _nameEditView;
}

- (NCBaseButton *)createButton {
    if (!_createButton) {
        _createButton = [[NCBaseButton alloc] init];
        [_createButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        _createButton.enabled = YES;
        [_createButton setTitle:NCUILocalizedString(@"group_create")
                       forState:(UIControlStateNormal)];
        _createButton.backgroundColor = NCDynamicColor(@"primary_color");
        _createButton.layer.cornerRadius = 5;
        _createButton.layer.masksToBounds = YES;
        _createButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _createButton;
}

@end
