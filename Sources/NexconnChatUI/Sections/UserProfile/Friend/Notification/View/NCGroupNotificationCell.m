//
//  NCGroupNotificationCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupNotificationCell.h"
#import "NCImageView.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
NSString  * const NCGroupNotificationCellIdentifier = @"NCGroupNotificationCellIdentifier";
NSInteger const NCGroupNotificationCellHorizontalMargin = 20;

NSInteger const NCGroupNotificationCellPortraitWidth = 32;
NSInteger const NCGroupNotificationOperationCellBtnMinWidth = 45;

@interface NCGroupNotificationCell()

/// Right-side container: labTips and labName.
@property (nonatomic, strong) UIStackView *rightStackView;

/// Top container: portrait and rightStackView.
@property (nonatomic, strong) UIStackView *topStackView;

/// Bottom container: labStatus, btnReject, and btnApprove.
@property (nonatomic, strong) UIStackView *bottomStackView;

/// Content container: topStackView and bottomStackView.
@property (nonatomic, strong) UIStackView *contentStackView;
@end

@implementation NCGroupNotificationCell


- (void)setupView {
    [super setupView];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.paddingContainerView addSubview:self.contentStackView];
    
    [self.topStackView addArrangedSubview:self.portraitImageView];
    [self.rightStackView addArrangedSubview:self.labTips];
    [self.rightStackView addArrangedSubview:self.labName];

    [self.topStackView addArrangedSubview:self.rightStackView];

    [self.contentStackView addArrangedSubview:self.topStackView];
    [self.contentStackView addArrangedSubview:self.bottomStackView];
    
    UIView *placeholder = [UIView new];
    placeholder.translatesAutoresizingMaskIntoConstraints = NO;
    [placeholder setContentHuggingPriority:UILayoutPriorityDefaultLow
                                   forAxis:UILayoutConstraintAxisHorizontal];
    [self.bottomStackView addArrangedSubview:placeholder];
    [self.bottomStackView addArrangedSubview:self.btnReject];
    [self.bottomStackView addArrangedSubview:self.btnApprove];
    [self.bottomStackView addArrangedSubview:self.labStatus];

    [self updateCGColorUI];
    
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateCGColorUI];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:NCUserManagementImageCellLineLeading
                           trailing:-NCUserManagementImageCellLineTrailing];
    [NSLayoutConstraint activateConstraints:@[
           [self.contentStackView.leadingAnchor constraintEqualToAnchor:self.paddingContainerView.leadingAnchor constant:NCUserManagementPadding],
           [self.contentStackView.trailingAnchor constraintEqualToAnchor:self.paddingContainerView.trailingAnchor constant:-NCUserManagementPadding],
           [self.contentStackView.topAnchor constraintEqualToAnchor:self.paddingContainerView.topAnchor constant:NCUserManagementPadding],
           [self.contentStackView.bottomAnchor constraintEqualToAnchor:self.paddingContainerView.bottomAnchor constant:-NCUserManagementPadding],
           
           [self.portraitImageView.widthAnchor constraintEqualToConstant:NCGroupNotificationCellPortraitWidth],
           [self.portraitImageView.heightAnchor constraintEqualToConstant:NCGroupNotificationCellPortraitWidth],
           [self.btnReject.heightAnchor constraintEqualToConstant:34],
           [self.btnApprove.heightAnchor constraintEqualToConstant:34]
       ]];
}

- (void)showPortrait:(NSString *)url {
    if (url.length) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:url]];
    } else {
        [self.portraitImageView setImage:NCDynamicImage(@"channel-list_cell_group_portrait_img")];
    }
}

- (BOOL)shouldShowOperationView:(NCGroupApplicationInfo *)application {
    if (application.status == NCGroupApplicationStatusAdminRefused ||
        application.status == NCGroupApplicationStatusInviteeRefused ||
        application.status == NCGroupApplicationStatusJoined ||
        application.status == NCGroupApplicationStatusExpired) {
        return NO;
    }
    // Received invitation.
    BOOL invited = application.status == NCGroupApplicationStatusInviteeUnhandled && application.direction == NCGroupApplicationDirectionInvitationReceived;
    if (invited) {
        return YES;
    }
    // Sent join request.
    BOOL isApply = application.direction == NCGroupApplicationDirectionApplicationSent;
    if (isApply) {
        return NO;
    }
    // Sent invitation.
    BOOL isInvite = application.direction == NCGroupApplicationDirectionInvitationSent;
    if(isInvite) {
        return NO;
    }
    
    if (application.status == NCGroupApplicationStatusAdminUnhandled) {
        return YES;
    }
    return NO;
}

- (void)updateWithViewModel:(NCGroupNotificationCellViewModel *)viewModel {
    self.viewModel = viewModel;
    BOOL isOperationView = [self shouldShowOperationView:viewModel.application];
    self.btnReject.hidden = !isOperationView;
    self.btnApprove.hidden = !isOperationView;
    self.labStatus.hidden = isOperationView;
    // Received invitation.
    if (viewModel.application.direction == NCGroupApplicationDirectionInvitationReceived) {
        [self showPortrait:viewModel.application.inviterInfo.avatarUrl];
    } else if (viewModel.application.direction == NCGroupApplicationDirectionApplicationReceived) {
        // Join request.
        if (viewModel.application.inviterInfo) { // An inviter is available.
            [self showPortrait:viewModel.application.inviterInfo.avatarUrl];
        } else { // Display the applicant.
            [self showPortrait:viewModel.application.joinMemberInfo.avatarUrl];
        }
      
    } else if (viewModel.application.direction == NCGroupApplicationDirectionApplicationSent) {
            // Display the applicant.
        [self showPortrait:viewModel.application.joinMemberInfo.avatarUrl];
    } else if (viewModel.application.direction == NCGroupApplicationDirectionInvitationSent) {
        // Display the inviter.
        [self showPortrait:viewModel.application.inviterInfo.avatarUrl];
}
    self.labStatus.text = [self statusString:viewModel.application];
}

- (NSString *)statusString:(NCGroupApplicationInfo *)application {
    NSString *status= @"";
    switch (application.status) {
        case NCGroupApplicationStatusAdminUnhandled:
            status = NCUILocalizedString(@"group_application_status_manager_un_handled");
            break;
        case NCGroupApplicationStatusAdminRefused:
            status = NCUILocalizedString(@"group_application_status_manager_refused");
            break;
        case NCGroupApplicationStatusInviteeUnhandled:
            status = NCUILocalizedString(@"group_application_status_invitee_un_handled");
            break;
        case NCGroupApplicationStatusInviteeRefused:
            status = NCUILocalizedString(@"group_application_status_invitee_refused");
            break;
        case NCGroupApplicationStatusJoined:
            status = NCUILocalizedString(@"group_application_status_joined");
            break;
        case NCGroupApplicationStatusExpired:
            status = NCUILocalizedString(@"group_application_status_expired");
            break;
        default:
            self.labStatus.text = @"";
            break;
    }
    return status;
}

- (void)approveApplication {
    [self.viewModel approveApplication];
}

- (void)rejectApplication {
    [self.viewModel rejectApplication];
}
- (void)updateCGColorUI {
    UIColor *borderColor = NCDynamicColor(@"line_background_color");
    self.btnReject.layer.borderColor = borderColor.CGColor;
}

#pragma mark - GETTER

- (UIButton *)btnReject {
    if (!_btnReject) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:NCUILocalizedString(@"friend_application_refuse") forState:UIControlStateNormal];
        btn.backgroundColor = NCDynamicColor(@"common_background_color");
        [btn setTitleColor:NCDynamicColor(@"hint_color") forState:UIControlStateNormal];
        btn.layer.borderColor = NCDynamicColor(@"line_background_color").CGColor;
        btn.contentEdgeInsets = UIEdgeInsetsMake(7, 17, 7, 17);
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        btn.layer.borderWidth = 1;
        btn.layer.cornerRadius = 6;
        [btn addTarget:self
                action:@selector(rejectApplication)
      forControlEvents:UIControlEventTouchUpInside];
        [btn sizeToFit];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [btn setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _btnReject = btn;
    }
    return _btnReject;
}

- (UIButton *)btnApprove {
    if (!_btnApprove) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:NCUILocalizedString(@"friend_application_accept") forState:UIControlStateNormal];
        [btn setBackgroundColor:NCDynamicColor(@"primary_color")];
        [btn setTitleColor:NCDynamicColor(@"control_title_white_color")
                  forState:UIControlStateNormal];
        btn.contentEdgeInsets = UIEdgeInsetsMake(7, 17, 7, 17);
        btn.layer.cornerRadius = 6;
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn addTarget:self
                action:@selector(approveApplication)
      forControlEvents:UIControlEventTouchUpInside];
        [btn sizeToFit];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [btn setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _btnApprove = btn;
    }
    return _btnApprove;
}

- (NCImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [NCImageView new];
        if (NCChatUIConfigCenter.ui.globalConversationAvatarStyle == NC_USER_AVATAR_CYCLE &&
            NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = NCGroupNotificationCellPortraitWidth/2;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.bounds = CGRectMake(0, 0, NCGroupNotificationCellPortraitWidth, NCGroupNotificationCellPortraitWidth);
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_group_portrait_img")];

    }
    return _portraitImageView;
}
 
- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        lab.font = [UIFont systemFontOfSize:14];
        lab.textColor = NCDynamicColor(@"text_secondary_color");
        lab.accessibilityLabel = @"labName";
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentCompressionResistancePriority:UILayoutPriorityRequired
                                             forAxis:UILayoutConstraintAxisVertical];
        _labName = lab;
    }
    return _labName;
}

- (UILabel *)labTips {
    if (!_labTips) {
        UILabel *lab = [UILabel new];
        lab.lineBreakMode = NSLineBreakByTruncatingTail;
        lab.textColor = NCDynamicColor(@"text_primary_color");
        lab.accessibilityLabel = @"labTips";
        lab.numberOfLines = 2;
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentCompressionResistancePriority:UILayoutPriorityRequired
                                             forAxis:UILayoutConstraintAxisVertical];
        _labTips = lab;
    }
    return _labTips;
}

- (UILabel *)labStatus {
    if (!_labStatus) {
        UILabel *lab = [UILabel new];
        lab.textColor = NCDynamicColor(@"text_secondary_color");
        lab.font = [UIFont systemFontOfSize:12];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _labStatus = lab;
    }
    return _labStatus;
}


- (UIStackView *)rightStackView {
    if (!_rightStackView) {
        _rightStackView = [[UIStackView alloc] init];
        _rightStackView.accessibilityLabel = @"rightStackView";
        _rightStackView.axis = UILayoutConstraintAxisVertical;
        _rightStackView.alignment = UIStackViewAlignmentFill;
        _rightStackView.distribution = UIStackViewDistributionFill;
        _rightStackView.spacing = 10;
        _rightStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _rightStackView;
}

- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.accessibilityLabel = @"contentStackView";
        _contentStackView.axis = UILayoutConstraintAxisVertical;
        _contentStackView.alignment = UIStackViewAlignmentFill;
        _contentStackView.distribution = UIStackViewDistributionFill;
        _contentStackView.spacing = 10;
        _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contentStackView;
}

- (UIStackView *)bottomStackView {
    if (!_bottomStackView) {
        _bottomStackView = [[UIStackView alloc] init];
        _bottomStackView.accessibilityLabel = @"bottomStackView";
        _bottomStackView.axis = UILayoutConstraintAxisHorizontal;
        _bottomStackView.alignment = UIStackViewAlignmentFill;
        _bottomStackView.distribution = UIStackViewDistributionFill;
        _bottomStackView.spacing = 10;
        _bottomStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _bottomStackView;
}


- (UIStackView *)topStackView {
    if (!_topStackView) {
        _topStackView = [[UIStackView alloc] init];
        _topStackView.axis = UILayoutConstraintAxisHorizontal;
        _topStackView.alignment = UIStackViewAlignmentCenter;
        _topStackView.distribution = UIStackViewDistributionFill;
        _topStackView.spacing = 12;
        _topStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _topStackView.accessibilityLabel = @"topStackView";
    }
    return _topStackView;
}

@end
