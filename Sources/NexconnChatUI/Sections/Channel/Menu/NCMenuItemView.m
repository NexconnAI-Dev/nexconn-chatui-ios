//
//  NCMenuItemView.m
//  PopMenu
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMenuItemView.h"
#import "NCChatUICommonDefine.h"
#import "NCMenuItem.h"

@interface NCMenuItemView ()

@property (nonatomic, strong, readwrite) UIImageView *iconImageView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong) UIStackView *stackView;

@end

@implementation NCMenuItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // Create the icon view.
    _iconImageView = [[UIImageView alloc] init];
    _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    _iconImageView.translatesAutoresizingMaskIntoConstraints = NO;

    // Create the title label.
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:12];
    _titleLabel.textColor = NCDynamicColor(@"control_title_white_color");
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.numberOfLines = 2; // Allow the title to wrap.
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    // Arrange the icon and title vertically.
    _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[ _iconImageView, _titleLabel ]];
    _stackView.axis = UILayoutConstraintAxisVertical;
    _stackView.alignment = UIStackViewAlignmentCenter; // Center the icon and text horizontally.
    _stackView.distribution = UIStackViewDistributionFill;
    _stackView.spacing = 6;
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:_stackView];

    // Pin the stack to the top and horizontal edges while allowing content-driven height.
    [NSLayoutConstraint activateConstraints:@[
        // Top and horizontal alignment
        [_stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
        [_stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
        [_stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-4],

        // Fixed icon size
        [_iconImageView.widthAnchor constraintEqualToConstant:24],
        [_iconImageView.heightAnchor constraintEqualToConstant:24]
    ]];

    // Use a lower-priority bottom bound so the content determines the height.
    NSLayoutConstraint *bottomConstraint =
        [_stackView.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-8];
    bottomConstraint.priority = UILayoutPriorityDefaultHigh;
    bottomConstraint.active = YES;

    // Add tap handling.
    UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tapGesture];

    // Configure the background and corner radius.
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;
}

- (void)configureWithMenuItem:(NCMenuItem *)menuItem {
    self.iconImageView.image = menuItem.image;
    self.titleLabel.text = menuItem.title;
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    // Animate tap feedback before invoking the action.
    [UIView animateWithDuration:0.1
        animations:^{
          self.transform = CGAffineTransformMakeScale(0.95, 0.95);
          self.backgroundColor = NCDynamicColor(@"selected_background_color");
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.1
              animations:^{
                self.transform = CGAffineTransformIdentity;
                self.backgroundColor = [UIColor clearColor];
              }
              completion:^(BOOL finished) {
                if (self.actionHandler) {
                    self.actionHandler();
                }
              }];
        }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.backgroundColor = NCDynamicColor(@"selected_background_color");
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.backgroundColor = [UIColor clearColor];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.backgroundColor = [UIColor clearColor];
}

@end
