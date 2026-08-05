//
//  NCUserProfileHeaderCell.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUserProfileHeaderCell.h"
#import "NCOnlineStatusView.h"
#import "NCChatUIConfig.h"
#import "NCChatUICommonDefine.h"

#define NCUserProfileHeaderCellSize 60
#define NCUserProfileHeaderCellNameFont 11
#define NCUserProfileHeaderCellRemarkFont 17
#define NCUserProfileHeaderCellPortraitLeft 15
#define NCUserProfileHeaderCellPortraitTop 11
#define NCUserProfileHeaderCellRemarkLeadingSpace 17
#define NCUserProfileHeaderCellRemarkTop 21

NSString  * const NCUserProfileHeaderCellIdentifier = @"NCUserProfileHeaderCellIdentifier";

@interface NCUserProfileHeaderCell ()
@property (nonatomic, strong) UIStackView *labelStackView; // Vertical stack: remarkStackView and name.
@property (nonatomic, strong) UIStackView *remarkStackView; // Horizontal stack: online status and remark.
@end

@implementation NCUserProfileHeaderCell

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.onlineStatusView reset];
}

- (void)setupView {
    [super setupView];

    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.labelStackView];
    self.paddingContainerView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    // Add online status and remark to the horizontal stack.
    [self.remarkStackView addArrangedSubview:self.onlineStatusView];
    [self.remarkStackView addArrangedSubview:self.remarkLabel];
    
    // Add remarkStackView and nameLabel to the vertical stack.
    [self.labelStackView addArrangedSubview:self.remarkStackView];
    [self.labelStackView addArrangedSubview:self.nameLabel];

}

- (void)setupConstraints {
    [super setupConstraints];
    
    self.portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.labelStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.remarkLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                           forAxis:UILayoutConstraintAxisHorizontal];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.portraitImageView.widthAnchor constraintEqualToConstant:NCUserProfileHeaderCellSize],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:NCUserProfileHeaderCellSize],
    ]];
}

- (void)hiddenNameLabel:(BOOL)hidden {
    self.nameLabel.hidden = hidden;
}

- (void)hiddenOnlineStatusView:(BOOL)hidden {
    self.onlineStatusView.hidden = hidden;
}

- (void)updateOnlineStatus:(BOOL)isOnline {
    self.onlineStatusView.online = isOnline;
}

#pragma mark - getter

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[NCImageView alloc] init];
        if (NCChatUIConfigCenter.ui.globalConversationAvatarStyle == NC_USER_AVATAR_CYCLE &&
            NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = NCUserProfileHeaderCellSize/2;
        }else{
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
    }
    return _portraitImageView;
}

- (UIStackView *)labelStackView {
    if (!_labelStackView) {
        _labelStackView = [[UIStackView alloc] init];
        _labelStackView.axis = UILayoutConstraintAxisVertical;
        _labelStackView.alignment = UIStackViewAlignmentLeading;
        _labelStackView.distribution = UIStackViewDistributionFill;
        _labelStackView.spacing = 5;
    }
    return _labelStackView;
}

- (UIStackView *)remarkStackView {
    if (!_remarkStackView) {
        _remarkStackView = [[UIStackView alloc] init];
        _remarkStackView.axis = UILayoutConstraintAxisHorizontal;
        _remarkStackView.alignment = UIStackViewAlignmentCenter;
        _remarkStackView.distribution = UIStackViewDistributionFill;
        _remarkStackView.spacing = 5;
    }
    return _remarkStackView;
}

- (NCOnlineStatusView *)onlineStatusView {
    if (!_onlineStatusView) {
        _onlineStatusView = [[NCOnlineStatusView alloc] init];
        _onlineStatusView.hidden = YES;
    }
    return _onlineStatusView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = NCDynamicColor(@"text_primary_color");
        _nameLabel.font = [UIFont systemFontOfSize:NCUserProfileHeaderCellNameFont];
    }
    return _nameLabel;
}

- (UILabel *)remarkLabel {
    if (!_remarkLabel) {
        _remarkLabel = [[UILabel alloc] init];
        _remarkLabel.textColor =NCDynamicColor(@"text_primary_color");
        _remarkLabel.font = [UIFont systemFontOfSize:NCUserProfileHeaderCellRemarkFont];
    }
    return _remarkLabel;
}


@end
