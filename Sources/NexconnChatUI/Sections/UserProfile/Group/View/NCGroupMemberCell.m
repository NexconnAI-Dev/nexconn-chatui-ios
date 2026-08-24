//
//  NCGroupMemberCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupMemberCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCSemanticContext.h"

NSString *const NCGroupMemberCellIdentifier = @"NCGroupMemberCellIdentifier";

#define NCGroupMemberCellPortraitSize 40
#define NCGroupMemberCellNameFont 17
#define NCGroupMemberCellViewSpace 12
#define NCGroupMemberCellArrowWidth 8
#define NCGroupMemberCellArrowHeight 14

@interface NCGroupMemberCell ()
@end

@implementation NCGroupMemberCell

- (void)setupView {
    [super setupView];
    self.contentStackView.spacing = NCGroupMemberCellViewSpace;
    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.nameLabel];
    [self.contentStackView addArrangedSubview:self.roleLabel];
    [self.contentStackView addArrangedSubview:self.arrowView];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:60 trailing:-10];

    [NSLayoutConstraint activateConstraints:@[
        [self.arrowView.widthAnchor constraintEqualToConstant:NCGroupMemberCellArrowWidth],
        [self.arrowView.heightAnchor constraintEqualToConstant:NCGroupMemberCellArrowHeight],
        [self.portraitImageView.widthAnchor
            constraintEqualToConstant:NCGroupMemberCellPortraitSize],
        [self.portraitImageView.heightAnchor
            constraintEqualToConstant:NCGroupMemberCellPortraitSize]
    ]];
}

- (void)hiddenArrow:(BOOL)hiddenArrow {
    self.arrowView.hidden = hiddenArrow;
}

#pragma mark - getter

- (NCImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[NCImageView alloc] init];
        if (NCChatUIConfigCenter.ui.globalConversationAvatarStyle == NC_USER_AVATAR_CYCLE &&
            NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = NCGroupMemberCellPortraitSize / 2;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_portraitImageView
            setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
    }
    return _portraitImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = NCDynamicColor(@"text_primary_color");
        _nameLabel.font = [UIFont systemFontOfSize:NCGroupMemberCellNameFont];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_nameLabel setContentHuggingPriority:UILayoutPriorityDefaultLow
                                      forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _nameLabel;
}

- (UILabel *)roleLabel {
    if (!_roleLabel) {
        _roleLabel = [[UILabel alloc] init];
        _roleLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _roleLabel.font = [UIFont systemFontOfSize:NCGroupMemberCellNameFont];
        _roleLabel.textAlignment = NSTextAlignmentRight;
        _roleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_roleLabel setContentHuggingPriority:UILayoutPriorityRequired
                                      forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _roleLabel;
}

- (NCBaseImageView *)arrowView {
    if (!_arrowView) {
        UIImage *image = NCDynamicImage(@"cell_right_arrow_img");
        _arrowView =
            [[NCBaseImageView alloc] initWithImage:[NCSemanticContext imageflippedForRTL:image]];
        _arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _arrowView;
}

@end
