//
//  NCGroupMemberAdditionalCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupMemberAdditionalCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"

NSString *_Nullable const NCGroupMemberAdditionalCellIdentifier =
    @"NCGroupMemberAdditionalCellIdentifier";

@implementation NCGroupMemberAdditionalCell
- (void)setupView {
    [super setupView];
    self.contentStackView.spacing = 12;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.labName];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:NCUserManagementImageCellLineLeading
                           trailing:-NCUserManagementImageCellLineTrailing];
    CGFloat portraitWidth = 32;

    [NSLayoutConstraint activateConstraints:@[
        // portraitImageView constraints.
        [self.portraitImageView.widthAnchor constraintEqualToConstant:portraitWidth],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:portraitWidth],
    ]];
}

- (void)showPortraitByImage:(UIImage *)image {
}

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [UIImageView new];
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
        if (NCChatUIConfigCenter.ui.globalConversationAvatarStyle == NC_USER_AVATAR_CYCLE &&
            NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = 16.f;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
    }
    return _portraitImageView;
}

- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        lab.textColor = NCDynamicColor(@"text_primary_color");
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        _labName = lab;
    }
    return _labName;
}
@end
