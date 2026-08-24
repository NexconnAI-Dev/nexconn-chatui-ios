//
//  NCSightFileBrowserCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightFileBrowserCell.h"
#import "NCChatUICommonDefine.h"

NSString *const NCSightFileBrowserCellIdentifier = @"NCSightFileBrowserCellIdentifier";

@implementation NCSightFileBrowserCell

- (void)setupView {
    [super setupView];
    self.paddingContainerView.backgroundColor = [UIColor clearColor];
    [self.paddingContainerView addSubview:self.contentStackView];
    [self.topStackView addArrangedSubview:self.labelTitle];
    [self.topStackView addArrangedSubview:self.labelTime];
    [self.rightStackView addArrangedSubview:self.topStackView];
    [self.rightStackView addArrangedSubview:self.labelSubtitle];
    [self.contentStackView addArrangedSubview:self.imageIcon];
    [self.contentStackView addArrangedSubview:self.rightStackView];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:37 trailing:0];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStackView.leadingAnchor
            constraintEqualToAnchor:self.paddingContainerView.leadingAnchor],
        [self.contentStackView.trailingAnchor
            constraintEqualToAnchor:self.paddingContainerView.trailingAnchor],
        [self.contentStackView.topAnchor constraintEqualToAnchor:self.paddingContainerView.topAnchor
                                                        constant:NCUserManagementPadding],
        [self.contentStackView.bottomAnchor
            constraintEqualToAnchor:self.paddingContainerView.bottomAnchor
                           constant:-NCUserManagementPadding],
        [self.imageIcon.widthAnchor constraintEqualToConstant:32],
        [self.imageIcon.heightAnchor constraintEqualToConstant:32]
    ]];
}

- (UIImageView *)imageIcon {
    if (!_imageIcon) {
        _imageIcon = [UIImageView new];
        _imageIcon.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _imageIcon;
}

- (UILabel *)labelTime {
    if (!_labelTime) {
        UILabel *lab = [UILabel new];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        lab.font = [UIFont systemFontOfSize:12];
        lab.textColor = NCDynamicColor(@"text_secondary_color");
        [lab setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                             forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentHuggingPriority:UILayoutPriorityDefaultHigh
                               forAxis:UILayoutConstraintAxisHorizontal];
        _labelTime = lab;
    }
    return _labelTime;
}

- (UILabel *)labelSubtitle {
    if (!_labelSubtitle) {
        UILabel *lab = [UILabel new];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        lab.font = [UIFont systemFontOfSize:12];
        lab.textColor = NCDynamicColor(@"text_secondary_color");
        _labelSubtitle = lab;
    }
    return _labelSubtitle;
}

- (UILabel *)labelTitle {
    if (!_labelTitle) {
        UILabel *lab = [UILabel new];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        lab.font = [UIFont systemFontOfSize:14];
        lab.textColor = NCDynamicColor(@"text_primary_color");
        [lab setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                             forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisHorizontal];
        _labelTitle = lab;
    }
    return _labelTitle;
}

- (UIStackView *)topStackView {
    if (!_topStackView) {
        _topStackView = [[UIStackView alloc] init];
        _topStackView.axis = UILayoutConstraintAxisHorizontal;
        _topStackView.alignment = UIStackViewAlignmentCenter;
        _topStackView.distribution = UIStackViewDistributionFill;
        _topStackView.spacing = 16;
        _topStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _topStackView;
}

- (UIStackView *)rightStackView {
    if (!_rightStackView) {
        _rightStackView = [[UIStackView alloc] init];
        _rightStackView.axis = UILayoutConstraintAxisVertical;
        _rightStackView.alignment = UIStackViewAlignmentFill;
        _rightStackView.distribution = UIStackViewDistributionFill;
        _rightStackView.spacing = 5;
        _rightStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _rightStackView;
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
