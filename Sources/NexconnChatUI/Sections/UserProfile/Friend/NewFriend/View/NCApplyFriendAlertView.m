//
//  NCApplyFriendAlertView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCApplyFriendAlertView.h"
#import "NCChatUICommonDefine.h"
#import "NCBaseButton.h"
#import "NCChatUIUtility.h"
#import "NCPlaceholderTextView.h"

@interface NCApplyFriendAlertView()<UITextViewDelegate>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) NCPlaceholderTextView *txtView;
@property (nonatomic, strong) UILabel *labTitle;
@property (nonatomic, copy) NCApplyFriendAlertBlock block;
@property (nonatomic, assign) NSInteger limit;
@end

@implementation NCApplyFriendAlertView
+ (void)showAlert:(NSString *)title
      placeholder:(NSString *)placeholder
       completion:(void(^)(NSString *))completion {
    [self showAlert:title
        placeholder:placeholder
        lengthLimit:INT32_MAX
         completion:completion];
}

+ (void)showAlert:(NSString *)title
      placeholder:(NSString *)placeholder
      lengthLimit:(NSInteger)limit
       completion:(NCApplyFriendAlertBlock)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        NCApplyFriendAlertView *alert = [NCApplyFriendAlertView new];
        alert.labTitle.text = title;
        alert.txtView.placeholder = placeholder;
        alert.block = completion;
        alert.limit = limit;
        UIWindow *window = [NCChatUIUtility getKeyWindow];
        alert.frame = [window bounds];
        [window addSubview:alert];
    });
}

- (void)setupView {
    [super setupView];
    self.backgroundColor =NCDynamicColor(@"mask_color");
    self.containerView = [self configureContainerView];
    [self addSubview:self.containerView];
}

- (void)setupConstraints {
    [super setupConstraints];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.containerView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-100],
        [self.containerView.widthAnchor constraintEqualToConstant:288]
    ]];
}

#pragma mark - Private

- (UIView *)configureContainerView {
    UIView *view = [UIView new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    
    view.accessibilityLabel = @"container";
    view.layer.cornerRadius = 10;
    view.backgroundColor = NCDynamicColor(@"common_background_color");
    view.layer.masksToBounds = YES;
    
    UIStackView *contentStackView = [[UIStackView alloc] init];
    contentStackView.axis = UILayoutConstraintAxisVertical;
    contentStackView.alignment = UIStackViewAlignmentFill;
    contentStackView.distribution = UIStackViewDistributionFill;
    contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:contentStackView];
    
    UIView *titleContainer = [UIView new];
    titleContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [titleContainer addSubview:self.labTitle];
    [NSLayoutConstraint activateConstraints:@[
        [self.labTitle.centerXAnchor constraintEqualToAnchor:titleContainer.centerXAnchor],
        [self.labTitle.topAnchor constraintEqualToAnchor:titleContainer.topAnchor constant:24],
        [self.labTitle.bottomAnchor constraintEqualToAnchor:titleContainer.bottomAnchor constant:-20]
    ]];
    [contentStackView addArrangedSubview:titleContainer];
    
    UIView *txtContainer = [UIView new];
    txtContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [txtContainer addSubview:self.txtView];
    [NSLayoutConstraint activateConstraints:@[
        [self.txtView.leadingAnchor constraintEqualToAnchor:txtContainer.leadingAnchor constant:16],
        [self.txtView.trailingAnchor constraintEqualToAnchor:txtContainer.trailingAnchor constant:-16],
        [self.txtView.topAnchor constraintEqualToAnchor:txtContainer.topAnchor],
        [self.txtView.bottomAnchor constraintEqualToAnchor:txtContainer.bottomAnchor constant:-28],
        [self.txtView.heightAnchor constraintEqualToConstant:110]
    ]];
    [contentStackView addArrangedSubview:txtContainer];
    
    UIView *line1 = [[UIView alloc] init];
    line1.backgroundColor = NCDynamicColor(@"line_background_color");
    line1.translatesAutoresizingMaskIntoConstraints = NO;
    [contentStackView addArrangedSubview:line1];
    [NSLayoutConstraint activateConstraints:@[
        [line1.heightAnchor constraintEqualToConstant:1]
    ]];
    
    UIView *line2 = [[UIView alloc] init];
    line2.translatesAutoresizingMaskIntoConstraints = NO;
    line2.backgroundColor =  NCDynamicColor(@"line_background_color");
    
    UIStackView *bottomStackView = [[UIStackView alloc] init];
    [contentStackView addArrangedSubview:bottomStackView];

    bottomStackView.axis = UILayoutConstraintAxisHorizontal;
    bottomStackView.alignment = UIStackViewAlignmentFill;
    bottomStackView.distribution = UIStackViewDistributionFill;
    bottomStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomStackView addArrangedSubview:self.cancelButton];
    [bottomStackView addArrangedSubview:line2];
    [bottomStackView addArrangedSubview:self.confirmButton];
    CGFloat buttonHeight = 55;

    [NSLayoutConstraint activateConstraints:@[
        [line2.widthAnchor constraintEqualToConstant:1],
        [line2.heightAnchor constraintEqualToConstant:buttonHeight],
        [self.cancelButton.widthAnchor constraintEqualToAnchor:self.confirmButton.widthAnchor],

        [contentStackView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [contentStackView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [contentStackView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [contentStackView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
    ]];
    
    return view;
}

- (void)confirmButtonClick {
    NSString *text = self.txtView.text;
    if (self.block) {
        self.block(text);
    }
    [self removeFromSuperview];
}

- (void)cancelButtonClick {
    [self removeFromSuperview];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (newText.length > self.limit) {
        return NO;
    }
    return YES;
}

#pragma mark - Property
- (UILabel *)labTitle {
    if (!_labTitle) {
        UILabel *lab = [UILabel new];
        lab.font = [UIFont systemFontOfSize:17];
        lab.textColor = NCDynamicColor(@"text_primary_color");
        lab.textAlignment = NSTextAlignmentCenter;
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        _labTitle = lab;
    }
    return _labTitle;
}

- (NCPlaceholderTextView *)txtView {
    if (!_txtView) {
        NCPlaceholderTextView *txt = [[NCPlaceholderTextView alloc] init];
        txt.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        [txt setTextColor:NCDynamicColor(@"text_primary_color")];
        txt.layer.cornerRadius = 4;
        txt.delegate = self;
        txt.font = [UIFont systemFontOfSize:14];
        txt.contentInset = UIEdgeInsetsMake(6, 6, 6, 6);
        txt.delegate = self;
        txt.translatesAutoresizingMaskIntoConstraints = NO;
        [txt setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        _txtView = txt;
    }
    return _txtView;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[NCBaseButton alloc] initWithFrame:CGRectMake(0, 0, 99, 40)];
        [_confirmButton setTitle:NCUILocalizedString(@"confirm") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:NCDynamicColor(@"primary_color") forState:(UIControlStateNormal)];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [_confirmButton addTarget:self
                           action:@selector(confirmButtonClick)
                 forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _confirmButton;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [[NCBaseButton alloc] initWithFrame:CGRectMake(0, 0, 99, 40)];
        [_cancelButton setTitle:NCUILocalizedString(@"cancel") forState:UIControlStateNormal];
        [_cancelButton setTitleColor:NCDynamicColor(@"text_primary_color")
                            forState:(UIControlStateNormal)];
        [_cancelButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [_cancelButton addTarget:self
                           action:@selector(cancelButtonClick)
                 forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _cancelButton;
}


@end
