//
//  NCApplyFriendCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCApplyFriendCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCImageView.h"
#import <CoreText/CoreText.h>

NSString *const NCFriendApplyCellIdentifier = @"NCFriendApplyCellIdentifier";
NSInteger const NCFriendApplyCellMargin = 10;
NSInteger const NCFriendApplyCellPortraitWidth = 32;

@interface NCApplyFriendCell () <NCSizeCalculateLabelDelegate>

/// Bottom container: subtitle and btnExpan.
@property (nonatomic, strong) UIStackView *bottomStackView;

/// Right-side container: topStackView and bottomStackView.
@property (nonatomic, strong) UIStackView *rightStackView;

/// Content container: portraitImageView and rightStackView.
@property (nonatomic, strong) UIStackView *contentStackView;
@end

@implementation NCApplyFriendCell

- (void)setupView {
    [super setupView];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.paddingContainerView addSubview:self.contentStackView];

    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.rightStackView];

    [self.rightStackView addArrangedSubview:self.topStackView];
    [self.topStackView addArrangedSubview:self.labName];
    [self.topStackView addArrangedSubview:self.labStatus];

    [self.rightStackView addArrangedSubview:self.bottomStackView];
    [self.bottomStackView addArrangedSubview:self.labRemark];

    UIView *viewHolder = [UIView new];
    viewHolder.translatesAutoresizingMaskIntoConstraints = NO;
    [viewHolder addSubview:self.btnExpand];
    [NSLayoutConstraint activateConstraints:@[
        [self.btnExpand.leadingAnchor constraintEqualToAnchor:viewHolder.leadingAnchor],
        [self.btnExpand.trailingAnchor constraintEqualToAnchor:viewHolder.trailingAnchor],
        [self.btnExpand.topAnchor constraintEqualToAnchor:viewHolder.topAnchor],
        [self.btnExpand.bottomAnchor constraintEqualToAnchor:viewHolder.bottomAnchor]
    ]];
    [self.bottomStackView addArrangedSubview:viewHolder];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:NCUserManagementImageCellLineLeading
                           trailing:-NCUserManagementImageCellLineTrailing];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStackView.leadingAnchor
            constraintEqualToAnchor:self.paddingContainerView.leadingAnchor
                           constant:NCUserManagementPadding],
        [self.contentStackView.trailingAnchor
            constraintEqualToAnchor:self.paddingContainerView.trailingAnchor
                           constant:-NCUserManagementPadding],
        [self.contentStackView.topAnchor constraintEqualToAnchor:self.paddingContainerView.topAnchor
                                                        constant:NCFriendApplyCellMargin],
        [self.contentStackView.bottomAnchor
            constraintEqualToAnchor:self.paddingContainerView.bottomAnchor
                           constant:-NCFriendApplyCellMargin],

        [self.portraitImageView.widthAnchor
            constraintEqualToConstant:NCFriendApplyCellPortraitWidth],
        [self.portraitImageView.heightAnchor
            constraintEqualToConstant:NCFriendApplyCellPortraitWidth],
        [self.topStackView.heightAnchor constraintEqualToConstant:34]

    ]];
}

- (void)showPortrait:(NSString *)url {
    if (url) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:url]];
    } else {
        [self.portraitImageView setImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
    }
}

- (void)updateWithViewModel:(NCApplyFriendCellViewModel *)viewModel {
    self.viewModel = viewModel;
    self.labName.text = viewModel.application.name;
    [self showPortrait:viewModel.application.avatarUrl];
    self.labRemark.text = self.viewModel.application.extra;
    switch (viewModel.application.applicationStatus) {
    case NCFriendApplicationStatusAccepted:
        self.labStatus.text = NCUILocalizedString(@"friend_application_accepted");
        break;
    case NCFriendApplicationStatusRefused:
        self.labStatus.text = NCUILocalizedString(@"friend_application_refused");
        break;
    case NCFriendApplicationStatusExpired:
        self.labStatus.text = NCUILocalizedString(@"friend_application_expired");
        break;
    default:
        self.labStatus.text = NCUILocalizedString(@"friend_application_un_handled");
        break;
    }
}

- (void)btnExpandClick:(id)sender {
    [self.viewModel expandRemark];
}

#pragma mark - NCSizeCalculateLabelDelegate

- (void)labelLayoutFinished:(UILabel *)label natureSize:(CGSize)natureSize {
    BOOL ret = [self.viewModel shouldHideExpandButton:label.bounds.size natureSize:natureSize];
    self.btnExpand.hidden = ret;
}
#pragma mark - GETTER

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [NCImageView new];
        if (NCChatUIConfigCenter.ui.globalConversationAvatarStyle == NC_USER_AVATAR_CYCLE &&
            NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = NCFriendApplyCellPortraitWidth / 2;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView
            setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _portraitImageView;
}

- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        lab.font = [UIFont boldSystemFontOfSize:17];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                             forAxis:UILayoutConstraintAxisHorizontal];
        _labName = lab;
    }
    return _labName;
}

- (NCSizeCalculateLabel *)labRemark {
    if (!_labRemark) {
        NCSizeCalculateLabel *lab = [NCSizeCalculateLabel new];
        lab.delegate = self;
        lab.textColor = NCDynamicColor(@"text_secondary_color");
        lab.font = [UIFont systemFontOfSize:14];
        lab.numberOfLines = 0;
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisHorizontal];

        _labRemark = lab;
    }
    return _labRemark;
}

- (UILabel *)labStatus {
    if (!_labStatus) {
        UILabel *lab = [UILabel new];
        lab.textColor = NCDynamicColor(@"text_primary_color");
        lab.font = [UIFont systemFontOfSize:13];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentCompressionResistancePriority:UILayoutPriorityRequired
                                             forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _labStatus = lab;
    }
    return _labStatus;
}

- (UIButton *)btnExpand {
    if (!_btnExpand) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:NCUILocalizedString(@"friend_application_expand")
             forState:UIControlStateNormal];
        btn.hidden = YES;
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn addTarget:self
                      action:@selector(btnExpandClick:)
            forControlEvents:UIControlEventTouchUpInside];
        [btn setTitleColor:NCDynamicColor(@"primary_color") forState:UIControlStateNormal];
        [btn sizeToFit];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn setContentCompressionResistancePriority:UILayoutPriorityRequired
                                             forAxis:UILayoutConstraintAxisHorizontal];
        [btn setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _btnExpand = btn;
    }
    return _btnExpand;
}

- (UIStackView *)topStackView {
    if (!_topStackView) {
        _topStackView = [[UIStackView alloc] init];
        _topStackView.axis = UILayoutConstraintAxisHorizontal;
        _topStackView.alignment = UIStackViewAlignmentFill;
        _topStackView.distribution = UIStackViewDistributionFill;
        _topStackView.spacing = 10;
        _topStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _topStackView.accessibilityLabel = @"topStackView";
    }
    return _topStackView;
}

- (UIStackView *)bottomStackView {
    if (!_bottomStackView) {
        _bottomStackView = [[UIStackView alloc] init];
        _bottomStackView.accessibilityLabel = @"bottomStackView";
        _bottomStackView.axis = UILayoutConstraintAxisHorizontal;
        _bottomStackView.alignment = UIStackViewAlignmentCenter;
        _bottomStackView.distribution = UIStackViewDistributionFill;
        _bottomStackView.spacing = 10;
        _bottomStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _bottomStackView;
}

- (UIStackView *)rightStackView {
    if (!_rightStackView) {
        _rightStackView = [[UIStackView alloc] init];
        _rightStackView.accessibilityLabel = @"rightStackView";
        _rightStackView.axis = UILayoutConstraintAxisVertical;
        _rightStackView.alignment = UIStackViewAlignmentFill;
        _rightStackView.distribution = UIStackViewDistributionFill;
        _rightStackView.spacing = 3;
        _rightStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _rightStackView;
}

- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.accessibilityLabel = @"contentStackView";
        _contentStackView.axis = UILayoutConstraintAxisHorizontal;
        _contentStackView.alignment = UIStackViewAlignmentCenter;
        _contentStackView.distribution = UIStackViewDistributionFill;
        _contentStackView.spacing = 12;
        _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contentStackView;
}
@end
