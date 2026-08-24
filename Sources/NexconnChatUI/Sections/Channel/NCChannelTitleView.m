//
//  NCChannelTitleView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelTitleView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCOnlineStatusView.h"

@interface NCChannelTitleView ()

/// Horizontal stack view containing the status indicator and title.
@property (nonatomic, strong) UIStackView *contentStackView;

/// Online status indicator.
@property (nonatomic, strong, readwrite) NCOnlineStatusView *onlineStatusView;

/// Title label.
@property (nonatomic, strong, readwrite) UILabel *titleLabel;

@end

@implementation NCChannelTitleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    [self addSubview:self.contentStackView];

    // Add the status indicator and title to the horizontal stack.
    [self.contentStackView addArrangedSubview:self.onlineStatusView];
    [self.contentStackView addArrangedSubview:self.titleLabel];

    // Pin the stack view to this view.
    self.contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStackView.leadingAnchor
            constraintGreaterThanOrEqualToAnchor:self.leadingAnchor],
        [self.contentStackView.trailingAnchor
            constraintLessThanOrEqualToAnchor:self.trailingAnchor],
        [self.contentStackView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.contentStackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.contentStackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor]
    ]];
}

#pragma mark - Public Methods

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
    [self sizeToFit];
}

- (void)updateOnlineStatus:(BOOL)isOnline {
    self.onlineStatusView.online = isOnline;
}

- (CGSize)intrinsicContentSize {
    CGSize stackSize =
        [self.contentStackView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return stackSize;
}

- (void)sizeToFit {
    [super sizeToFit];
    CGSize size = [self intrinsicContentSize];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, size.width, size.height);
}

#pragma mark - Getters

- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.axis = UILayoutConstraintAxisHorizontal;
        _contentStackView.alignment = UIStackViewAlignmentCenter;
        _contentStackView.distribution = UIStackViewDistributionFill;
        _contentStackView.spacing = 5;
    }
    return _contentStackView;
}

- (NCOnlineStatusView *)onlineStatusView {
    if (!_onlineStatusView) {
        _onlineStatusView = [[NCOnlineStatusView alloc] init];
        _onlineStatusView.hidden = NO;
    }
    return _onlineStatusView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:17];
        _titleLabel.textColor = NCDynamicColor(@"text_primary_color");
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

@end
