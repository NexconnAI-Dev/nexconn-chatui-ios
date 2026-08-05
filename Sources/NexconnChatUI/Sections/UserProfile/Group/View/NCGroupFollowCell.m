//
//  NCGroupFollowCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupFollowCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"

NSString  * const NCGroupFollowCellIdentifier = @"NCGroupFollowCellIdentifier";

NSInteger const NCGroupFollowCellPortraitLeading = 16;
NSInteger const NCGroupFollowCellPortraitSize = 32;
NSInteger const NCGroupFollowCellNameFont = 17;
NSInteger const NCGroupFollowCellNameLeadingSpace = 12;
NSInteger const NCGroupFollowCellActionButtonHeight = 24;
NSInteger const NCGroupFollowCellActionButtonSpace = 10;
NSInteger const NCGroupFollowCellActionButtonTrailingSpace = 3;
@implementation NCGroupFollowCell

- (void)setupView {
    [super setupView];
    self.contentStackView.spacing = 12;
    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.nameLabel];
    [self.contentStackView addArrangedSubview:self.actionButton];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:NCUserManagementImageCellLineLeading
                           trailing:-NCUserManagementImageCellLineTrailing];
    // Disable autoresizing-mask constraint generation.
    self.portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nameLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.actionButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [NSLayoutConstraint activateConstraints:@[
        // Fixed 32 x 32 size.
        [self.portraitImageView.widthAnchor constraintEqualToConstant:NCGroupFollowCellPortraitSize],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:NCGroupFollowCellPortraitSize],
        // Fixed height of 24.
        [self.actionButton.heightAnchor constraintEqualToConstant:NCGroupFollowCellActionButtonHeight],
        // Minimum width of 45.
    ]];
    
    
}

#pragma mark -- action

- (void)actionButtonDidTap {
    self.actionBlock();
}

#pragma mark - getter

- (NCImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[NCImageView alloc] init];
        if (NCChatUIConfigCenter.ui.globalConversationAvatarStyle == NC_USER_AVATAR_CYCLE &&
            NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = NCGroupFollowCellPortraitSize/2;
        }else{
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
    }
    return _portraitImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = NCDynamicColor(@"text_primary_color");
        _nameLabel.font = [UIFont systemFontOfSize:NCGroupFollowCellNameFont];
        [_nameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_nameLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _nameLabel;
}

- (NCButton *)actionButton {
    if (!_actionButton) {
        NCButton *btn = [NCButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:NCDynamicImage(@"group_follow_remove_btn_img")
             forState:UIControlStateNormal];
        [btn addTarget:self
                action:@selector(actionButtonDidTap)
      forControlEvents:UIControlEventTouchUpInside];
        if ([NCChatUIUtility isRTL]) {
            btn.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 22);
        } else {
            btn.contentEdgeInsets = UIEdgeInsetsMake(0, 22, 0, 0);
        }
         _actionButton = btn;
    }
    return _actionButton;
}


@end
