//
//  NCGroupMemberHeaderCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIConfig.h"
#import "NCChatUICommonDefine.h"
#import "NCGroupMemberHeaderCell.h"

NSString  * const NCGroupMemberHeaderCellIdentifier = @"NCGroupMemberHeaderCellIdentifier";

#define NCGroupMemberHeaderCellPortraitSize 48
#define NCGroupMemberHeaderCellNameHeight 15
#define NCGroupMemberHeaderCellNameFont 12
@implementation NCGroupMemberHeaderCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
        [self setupViewConstraints];
    }
    return self;
}

- (void)setupViewConstraints {
    [NSLayoutConstraint activateConstraints:@[
           [self.portraitImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
           [self.portraitImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
           [self.portraitImageView.heightAnchor constraintEqualToConstant:NCGroupMemberHeaderCellPortraitSize],
           [self.portraitImageView.widthAnchor constraintEqualToConstant:NCGroupMemberHeaderCellPortraitSize],
           
           [self.nameLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
           [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
           [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
       ]];
}

- (void)setupView {
    [self.contentView addSubview:self.portraitImageView];
    [self.contentView addSubview:self.nameLabel];
}

#pragma mark - getter
- (NCImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[NCImageView alloc] init];
        _portraitImageView.layer.masksToBounds = YES;
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
        if (NCChatUIConfigCenter.ui.globalConversationAvatarStyle == NC_USER_AVATAR_CYCLE &&
            NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = NCGroupMemberHeaderCellPortraitSize / 2;
        }else{
            _portraitImageView.layer.cornerRadius = 5.f;
        }
    }
    return _portraitImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _nameLabel.font = [UIFont systemFontOfSize:NCGroupMemberHeaderCellNameFont];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _nameLabel;
}
@end
