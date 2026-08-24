//
//  NCStackTableViewCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStackTableViewCell.h"

@implementation NCStackTableViewCell

- (void)setupView {
    [super setupView];
    [self.paddingContainerView addSubview:self.contentStackView];
}

- (void)setupConstraints {
    [super setupConstraints];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStackView.leadingAnchor
            constraintEqualToAnchor:self.paddingContainerView.leadingAnchor
                           constant:NCUserManagementPadding],
        [self.contentStackView.trailingAnchor
            constraintEqualToAnchor:self.paddingContainerView.trailingAnchor
                           constant:-NCUserManagementPadding],
        [self.contentStackView.topAnchor
            constraintEqualToAnchor:self.paddingContainerView.topAnchor],
        [self.contentStackView.bottomAnchor
            constraintEqualToAnchor:self.paddingContainerView.bottomAnchor]
    ]];
}

- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.axis = UILayoutConstraintAxisHorizontal;
        _contentStackView.alignment = UIStackViewAlignmentCenter;
        _contentStackView.distribution = UIStackViewDistributionFill;
        _contentStackView.spacing = 5;
        _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contentStackView;
}
@end
