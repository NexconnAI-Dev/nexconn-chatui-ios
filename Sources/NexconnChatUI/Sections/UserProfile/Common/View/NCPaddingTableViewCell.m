//
//  NCPaddingTableViewCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPaddingTableViewCell.h"
#import "NCChatUICommonDefine.h"

NSInteger const NCUserManagementPadding = 16;
NSInteger const NCUserManagementImageCellLineLeading = 60;
NSInteger const NCUserManagementImageCellLineTrailing = 10;

@interface NCPaddingTableViewCell ()
@property (nonatomic, strong) NSLayoutConstraint *paddingLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *paddingTrailingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *lineLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *lineTrailingConstraint;
@end
@implementation NCPaddingTableViewCell

- (void)setupView {
    [super setupView];
    // Keep the cell transparent so the table view background remains visible.
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.paddingContainerView];
    [self.paddingContainerView addSubview:self.lineView];
}

- (void)setupConstraints {
    [super setupConstraints];

    self.paddingLeadingConstraint = [self.paddingContainerView.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor
                       constant:NCUserManagementPadding];
    self.paddingTrailingConstraint = [self.paddingContainerView.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor
                       constant:-NCUserManagementPadding];
    // Inset contentView by 16 points on each side.
    [NSLayoutConstraint activateConstraints:@[
        self.paddingLeadingConstraint, self.paddingTrailingConstraint,
        [self.paddingContainerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.paddingContainerView.bottomAnchor
            constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];
}

- (void)updatePaddingContainer:(NSInteger)leading trailing:(NSInteger)trailing {
    NSInteger leadingConstant = self.paddingLeadingConstraint.constant;
    NSInteger trailingConstant = self.paddingTrailingConstraint.constant;
    if (leadingConstant == leading && trailingConstant == trailing) {
        return;
    }
    NSInteger trailingDiff = trailingConstant - trailing;
    NSInteger leadingDiff = leadingConstant - leading;

    self.paddingLeadingConstraint.constant = leading;
    self.paddingTrailingConstraint.constant = trailing;
    if (self.lineLeadingConstraint) {
        self.lineLeadingConstraint.constant = self.lineLeadingConstraint.constant + leadingDiff;
    }
    if (self.lineTrailingConstraint) {
        self.lineTrailingConstraint.constant = self.lineTrailingConstraint.constant + trailingDiff;
    }
}

- (void)updateLineViewConstraints:(NSInteger)leading trailing:(NSInteger)trailing {
    if (self.lineLeadingConstraint && self.lineTrailingConstraint) {
        self.lineLeadingConstraint.constant = leading;
        self.lineTrailingConstraint.constant = trailing;
        return;
    } else {
        self.lineLeadingConstraint.active = NO;
        self.lineTrailingConstraint.active = NO;
    }
    self.lineLeadingConstraint =
        [self.lineView.leadingAnchor constraintEqualToAnchor:self.paddingContainerView.leadingAnchor
                                                    constant:leading];

    self.lineTrailingConstraint = [self.lineView.trailingAnchor
        constraintEqualToAnchor:self.paddingContainerView.trailingAnchor
                       constant:trailing];

    [NSLayoutConstraint activateConstraints:@[
        self.lineLeadingConstraint, self.lineTrailingConstraint,
        [self.lineView.heightAnchor constraintEqualToConstant:1],
        [self.lineView.bottomAnchor constraintEqualToAnchor:self.paddingContainerView.bottomAnchor]
    ]];
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [UIView new];
        _lineView.backgroundColor = NCDynamicColor(@"line_background_color");
        _lineView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _lineView;
}

- (UIView *)paddingContainerView {
    if (!_paddingContainerView) {
        _paddingContainerView = [UIView new];
        _paddingContainerView.backgroundColor = NCDynamicColor(@"common_background_color");
        _paddingContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _paddingContainerView;
}

- (void)setHideSeparatorLine:(BOOL)hideSeparatorLine {
    _hideSeparatorLine = hideSeparatorLine;
    self.lineView.hidden = hideSeparatorLine;
}
@end
