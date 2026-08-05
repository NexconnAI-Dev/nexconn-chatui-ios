//
//  NCApplyFriendOperationCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCApplyFriendOperationCell.h"
#import "NCChatUICommonDefine.h"
#import "NCImageView.h"

NSString  * const NCFriendApplyOperationCellIdentifier = @"NCFriendApplyOperationCellIdentifier";
NSInteger const NCApplyFriendOperationCellBtnMinWidth = 45;
NSInteger const NCApplyFriendOperationCellBtnSpace = 10;
@implementation NCApplyFriendOperationCell

- (void)setupView {
    [super setupView];
    self.labStatus.hidden = YES;
    [self.topStackView addArrangedSubview:self.btnReject];
    [self.topStackView addArrangedSubview:self.btnApprove];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateCGColorUI];
}

#pragma mark -- private

- (void)updateCGColorUI {
    UIColor *borderColor = NCDynamicColor(@"line_background_color");
    self.btnReject.layer.borderColor = borderColor.CGColor;
}

#pragma mark -- getter

- (UIButton *)btnReject {
    if (!_btnReject) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:NCUILocalizedString(@"friend_application_refuse") forState:UIControlStateNormal];
        btn.backgroundColor =
        NCDynamicColor(@"common_background_color");
        [btn setTitleColor:NCDynamicColor(@"hint_color") forState:UIControlStateNormal];
        UIColor *borderColor = NCDynamicColor(@"line_background_color");
        btn.layer.borderColor = borderColor.CGColor;
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        btn.layer.borderWidth = 1;
        btn.layer.cornerRadius = 4;
        btn.contentEdgeInsets = UIEdgeInsetsMake(5, 17, 5, 17);
        [btn sizeToFit];

        [btn addTarget:self
                action:@selector(rejectApplication)
      forControlEvents:UIControlEventTouchUpInside];
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
        [btn setTitleColor:NCDynamicColor(@"control_title_white_color") forState:UIControlStateNormal];
        btn.layer.cornerRadius = 4;
        btn.contentEdgeInsets = UIEdgeInsetsMake(5, 17, 5, 17);
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn sizeToFit];
        [btn addTarget:self
                action:@selector(approveApplication)
      forControlEvents:UIControlEventTouchUpInside];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn setContentCompressionResistancePriority:UILayoutPriorityRequired
                                             forAxis:UILayoutConstraintAxisHorizontal];
        [btn setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _btnApprove = btn;
    }
    return _btnApprove;
}

- (void)approveApplication {
    [self.viewModel approveApplication];
}

- (void)rejectApplication {
    [self.viewModel rejectApplication];
}
@end
