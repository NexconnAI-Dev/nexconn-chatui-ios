//
//  NCApplyNaviItemsViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCApplyNaviItemsViewModel.h"
#import "NCButton.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
@interface NCApplyNaviItemsViewModel ()
@property (nonatomic, strong) UIView *coverView;
@end

@implementation NCApplyNaviItemsViewModel
@dynamic delegate;

- (NSArray *)rightNavigationBarItems {
    NCButton *btn = [[NCButton alloc] init];
    [btn addTarget:self
                  action:@selector(rightBarItemClicked:)
        forControlEvents:UIControlEventTouchUpInside];
    UIImage *image = NCDynamicImage(@"friend_apply_more_img");
    [btn setImage:image forState:UIControlStateNormal];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    return @[ item ];
}

- (void)rightBarItemClicked:(id)sender {
    if (self.responder) {
        UIView *btn = (UIView *)sender;
        [self showCoverViewBy:btn];
    }
}

- (void)showCoverViewBy:(UIView *)item {
    UIWindow *window = [NCChatUIUtility getKeyWindow];
    [window addSubview:self.coverView];
    [NSLayoutConstraint activateConstraints:@[
        [self.coverView.leadingAnchor constraintEqualToAnchor:window.leadingAnchor],
        [self.coverView.trailingAnchor constraintEqualToAnchor:window.trailingAnchor],
        [self.coverView.topAnchor constraintEqualToAnchor:window.topAnchor],
        [self.coverView.bottomAnchor constraintEqualToAnchor:window.bottomAnchor]
    ]];
    [self.coverView setNeedsLayout];
    [self.coverView layoutIfNeeded];
}

- (void)removeCoverView {
    [self.coverView removeFromSuperview];
}

- (void)btnClick:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(userDidSelectCategory:)]) {
        [self.delegate userDidSelectCategory:(NCApplicationCategory)btn.tag];
    }
    [self removeCoverView];
    [btn setBackgroundColor:NCDynamicColor(@"clear_color")];
}

- (void)touchDown:(UIButton *)btn {
    [btn setBackgroundColor:NCDynamicColor(@"auxiliary_background_2_color")];
}

- (void)touchCancel:(UIButton *)btn {
    [btn setBackgroundColor:NCDynamicColor(@"clear_color")];
}
- (NCButton *)createButton:(NSString *)title category:(NSInteger)category {
    NCButton *btn = [NCButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    UIColor *color = NCDynamicColor(@"text_primary_color");
    [btn setTitleColor:color forState:UIControlStateNormal];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.tag = category;
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];

    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpOutside];
    [btn addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [btn addTarget:self action:@selector(touchCancel:) forControlEvents:UIControlEventTouchCancel];
    return btn;
}

- (void)configureSheetView:(UIView *)containerView {
    CGFloat width = 180;
    CGFloat height = 181;

    CGFloat yOffset = CGRectGetMaxY(self.responder.navigationController.navigationBar.frame);
    UIView *panel = [[UIView alloc] init];
    ;
    panel.backgroundColor = NCDynamicColor(@"common_background_color");
    panel.layer.cornerRadius = 10;
    panel.layer.masksToBounds = YES;
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:panel];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;

    [panel addSubview:stackView];
    [NSLayoutConstraint activateConstraints:@[
        [panel.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-16],
        [panel.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:yOffset],
        [panel.widthAnchor constraintEqualToConstant:width],
        [panel.heightAnchor constraintEqualToConstant:height],

        [stackView.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor],
        [stackView.topAnchor constraintEqualToAnchor:panel.topAnchor constant:16],
        [stackView.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-16]
    ]];
    NSString *all = NCUILocalizedString(@"friend_application_all") ?: @"";
    NSString *received = NCUILocalizedString(@"friend_application_received") ?: @"";
    NSString *sent = NCUILocalizedString(@"friend_application_sent") ?: @"";
    NSArray *titles = @[ all, received, sent ];
    for (int i = 0; i < titles.count; i++) {
        UIButton *btn = [self createButton:titles[i] category:i];
        [stackView addArrangedSubview:btn];
    }
}

- (UIView *)coverView {
    if (!_coverView) {
        UIWindow *window = [NCChatUIUtility getKeyWindow];
        UIView *view = [[UIView alloc] initWithFrame:window.bounds];
        view.backgroundColor = NCDynamicColor(@"mask_color");
        view.translatesAutoresizingMaskIntoConstraints = NO;
        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeCoverView)];
        [view addGestureRecognizer:tap];
        [self configureSheetView:view];
        _coverView = view;
    }
    return _coverView;
}

@end
