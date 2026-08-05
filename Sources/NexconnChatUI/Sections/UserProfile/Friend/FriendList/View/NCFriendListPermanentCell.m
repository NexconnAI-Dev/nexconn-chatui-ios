//
//  NCFriendListPermanentCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFriendListPermanentCell.h"
#import "NCOnlineStatusView.h"
#import "NCImageView.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
NSString  * const NCFriendListPermanentCellIdentifier = @"NCFriendListPermanentCellIdentifier";
NSInteger const NCFriendListPermanentCellPortraitWidth = 32;

@implementation NCFriendListPermanentCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.onlineStatusView reset];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setupView {
    [super setupView];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Add online status and name to the stack view.
    UIView *portraitContainerView = [self portraitContainerView];
    [self.contentStackView addArrangedSubview:portraitContainerView];
    [self.contentStackView addArrangedSubview:self.onlineStatusView];
    [self.contentStackView addArrangedSubview:self.labName];
}

- (UIView *)portraitContainerView {
    UIView *view = [UIView new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setContentHuggingPriority:UILayoutPriorityRequired
                            forAxis:UILayoutConstraintAxisHorizontal];
    [view addSubview:self.portraitImageView];
    [NSLayoutConstraint activateConstraints:@[
            [self.portraitImageView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
            [self.portraitImageView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-8],
            [self.portraitImageView.centerYAnchor constraintEqualToAnchor:view.centerYAnchor],
            [self.portraitImageView.widthAnchor constraintEqualToConstant:NCFriendListPermanentCellPortraitWidth],
            [self.portraitImageView.heightAnchor constraintEqualToConstant:NCFriendListPermanentCellPortraitWidth],
        ]];
    return view;
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:NCUserManagementImageCellLineLeading
                           trailing:-NCUserManagementImageCellLineTrailing];
}

- (void)showPortraitByImage:(UIImage *)image {
    [self.portraitImageView setImage:image];
}

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [NCImageView new];
        if (NCChatUIConfigCenter.ui.globalConversationAvatarStyle == NC_USER_AVATAR_CYCLE &&
            NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = NCFriendListPermanentCellPortraitWidth/2;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_portraitImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
    }
    return _portraitImageView;
}

- (NCOnlineStatusView *)onlineStatusView {
    if (!_onlineStatusView) {
        _onlineStatusView = [[NCOnlineStatusView alloc] init];
        [_onlineStatusView setContentHuggingPriority:UILayoutPriorityRequired
                                forAxis:UILayoutConstraintAxisHorizontal];
        _onlineStatusView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _onlineStatusView;
}

- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        lab.textColor = NCDynamicColor(@"text_primary_color"); 
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisHorizontal];
        _labName = lab;
    }
    return _labName;
}
@end
