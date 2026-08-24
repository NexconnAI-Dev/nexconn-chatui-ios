//
//  NCMessageReadDetailTabView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageReadDetailTabView.h"
#import "NCChatUICommonDefine.h"

@interface NCMessageReadDetailTabView ()

@property (nonatomic, assign) NSInteger readCount;
@property (nonatomic, assign) NSInteger unreadCount;

@property (nonatomic, assign) NCMessageReadDetailTabType currentTab;

/// Indicator leading constraint used by the selection animation.
@property (nonatomic, strong) NSLayoutConstraint *indicatorLeadingConstraint;

@end

@implementation NCMessageReadDetailTabView

- (void)setupView {
    // Read button.
    self.readButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.readButton.titleLabel.font = [UIFont systemFontOfSize:14];
    self.readButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.readButton addTarget:self
                        action:@selector(readButtonTapped)
              forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.readButton];

    // Unread button.
    self.unreadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.unreadButton.titleLabel.font = [UIFont systemFontOfSize:14];
    self.unreadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.unreadButton addTarget:self
                          action:@selector(unreadButtonTapped)
                forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.unreadButton];

    // Divider.
    self.separatorLine = [[UIView alloc] init];
    self.separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
    self.separatorLine.backgroundColor = NCDynamicColor(@"line_background_color");
    [self addSubview:self.separatorLine];

    // Selection indicator.
    self.indicatorView = [[UIView alloc] init];
    self.indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    self.indicatorView.backgroundColor = self.selectedColor;
    [self addSubview:self.indicatorView];

    // Install constraints.
    [self setupViewConstraints];

    // Update titles.
    [self updateButtonTitles];

    // Apply the default selection.
    [self selectTabAtIndex:NCMessageReadDetailTabTypeRead];
}

/// Installs layout constraints.
- (void)setupViewConstraints {
    // Layout constants.
    CGFloat horizontalMargin = 16;
    CGFloat lineHeight = 1;

    // Read button constraints.
    [NSLayoutConstraint activateConstraints:@[
        [self.readButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor
                                                      constant:horizontalMargin],
        [self.readButton.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.readButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor
                                                     constant:-lineHeight]
    ]];

    // Unread button constraints.
    [NSLayoutConstraint activateConstraints:@[
        [self.unreadButton.leadingAnchor constraintEqualToAnchor:self.readButton.trailingAnchor],
        [self.unreadButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor
                                                         constant:-horizontalMargin],
        [self.unreadButton.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.unreadButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor
                                                       constant:-lineHeight],
        [self.unreadButton.widthAnchor constraintEqualToAnchor:self.readButton.widthAnchor]
    ]];

    // Divider constraints.
    [NSLayoutConstraint activateConstraints:@[
        [self.separatorLine.leadingAnchor constraintEqualToAnchor:self.leadingAnchor
                                                         constant:horizontalMargin],
        [self.separatorLine.trailingAnchor constraintEqualToAnchor:self.trailingAnchor
                                                          constant:-horizontalMargin],
        [self.separatorLine.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.separatorLine.heightAnchor constraintEqualToConstant:lineHeight]
    ]];

    // Indicator constraints, initially below the read button.
    self.indicatorLeadingConstraint =
        [self.indicatorView.leadingAnchor constraintEqualToAnchor:self.readButton.leadingAnchor];
    [NSLayoutConstraint activateConstraints:@[
        self.indicatorLeadingConstraint,
        [self.indicatorView.widthAnchor constraintEqualToAnchor:self.readButton.widthAnchor],
        [self.indicatorView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.indicatorView.heightAnchor constraintEqualToConstant:lineHeight]
    ]];
}

/// Applies colors.
- (void)setupSelectedColor:(UIColor *)selectedColor unselectedColor:(UIColor *)unselectedColor {
    self.selectedColor = selectedColor;
    self.unselectedColor = unselectedColor;
    [self updateColorConfiguration];
}

- (void)setupReadCount:(NSInteger)readCount unreadCount:(NSInteger)unreadCount {
    self.readCount = readCount;
    self.unreadCount = unreadCount;
    [self updateButtonTitles];
}

- (void)updateButtonTitles {
    NSString *readTitle =
        [NSString stringWithFormat:@"%@(%ld)", NCUILocalizedString(@"read"), (long)self.readCount];
    NSString *unreadTitle = [NSString
        stringWithFormat:@"%@(%ld)", NCUILocalizedString(@"unread"), (long)self.unreadCount];

    [self.readButton setTitle:readTitle forState:UIControlStateNormal];
    [self.unreadButton setTitle:unreadTitle forState:UIControlStateNormal];
}

/// Updates button title colors.
- (void)updateButtonTitleColors {
    if (self.currentTab == NCMessageReadDetailTabTypeRead) {
        [self.readButton setTitleColor:self.selectedColor forState:UIControlStateNormal];
        [self.unreadButton setTitleColor:self.unselectedColor forState:UIControlStateNormal];
    } else {
        [self.readButton setTitleColor:self.unselectedColor forState:UIControlStateNormal];
        [self.unreadButton setTitleColor:self.selectedColor forState:UIControlStateNormal];
    }
}

/// Updates the color configuration.
- (void)updateColorConfiguration {
    self.indicatorView.backgroundColor = self.selectedColor;
    // Update button colors.
    [self updateButtonTitleColors];
}

- (void)selectTabAtIndex:(NCMessageReadDetailTabType)tabType {
    // Skip layout work when the selected tab has not changed.
    if (self.currentTab == tabType) {
        return;
    }
    self.currentTab = tabType;

    // Update the indicator position constraint.
    [self updateIndicatorConstraint];

    // Animate the selection change.
    [UIView animateWithDuration:0.25
                     animations:^{
                       [self updateButtonTitleColors];
                       [self layoutIfNeeded];
                     }];

    if ([self.delegate respondsToSelector:@selector(tabView:didSelectTabAtIndex:)]) {
        [self.delegate tabView:self didSelectTabAtIndex:tabType];
    }
}

/// Updates the indicator constraint.
- (void)updateIndicatorConstraint {
    // Deactivate the previous constraint.
    self.indicatorLeadingConstraint.active = NO;

    // Create a constraint for the selected tab.
    if (self.currentTab == NCMessageReadDetailTabTypeRead) {
        self.indicatorLeadingConstraint = [self.indicatorView.leadingAnchor
            constraintEqualToAnchor:self.readButton.leadingAnchor];
    } else {
        self.indicatorLeadingConstraint = [self.indicatorView.leadingAnchor
            constraintEqualToAnchor:self.unreadButton.leadingAnchor];
    }

    // Activate the new constraint.
    self.indicatorLeadingConstraint.active = YES;
}

#pragma mark - Actions

- (void)readButtonTapped {
    [self selectTabAtIndex:NCMessageReadDetailTabTypeRead];
}

- (void)unreadButtonTapped {
    [self selectTabAtIndex:NCMessageReadDetailTabTypeUnread];
}

@end
