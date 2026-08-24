//
//  NCFullScreenEditView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFullScreenEditView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCEmojiBoardView.h"

#define Height_EmojiBoardView 223.5f

@interface NCFullScreenEditView () <NCEditInputBarControlDelegate, NCEditInputBarControlDataSource>

/// Background dimming view.
@property (nonatomic, strong) UIView *backgroundView;

/// Current bottom-bar layout state.
@property (nonatomic, assign) KBottomBarStatus currentLayoutState;

/// Bottom constraint for the edit input bar.
@property (nonatomic, strong) NSLayoutConstraint *editInputBarControlBottomConstraint;

/// Bottom spacer used by the keyboard and emoji panel.
@property (nonatomic, strong) UIView *bottomPlaceholderView;

/// Bottom constraint for the spacer view.
@property (nonatomic, strong) NSLayoutConstraint *bottomPlaceholderConstraint;

/// Height constraint for the spacer view.
@property (nonatomic, strong) NSLayoutConstraint *bottomPlaceholderHeightConstraint;

@end

@implementation NCFullScreenEditView

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.currentLayoutState = KBottomBarDefaultStatus;
        [self setupUI];
        [self setupViewConstraints];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Release the retained constraint reference.
    self.bottomPlaceholderHeightConstraint = nil;
}

#pragma mark - UI Setup

- (void)setupUI {
    // Start transparent and dim the background during presentation.
    self.backgroundColor = [UIColor clearColor];

    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = NCDynamicColor(@"common_background_color");
    self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.backgroundView];

    // Create the spacer used by the keyboard and emoji panel.
    self.bottomPlaceholderView = [[UIView alloc] init];
    self.bottomPlaceholderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:self.bottomPlaceholderView];
}

- (void)setupViewConstraints {
    CGFloat safeAreaTop = [NCChatUIUtility getWindowSafeAreaInsets].top;
    CGFloat safeAreaBottom = [NCChatUIUtility getWindowSafeAreaInsets].bottom;
    CGFloat topOffset = safeAreaTop;

    // Pin the background view to all edges.
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundView.topAnchor constraintEqualToAnchor:self.topAnchor constant:topOffset],
        [self.backgroundView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.backgroundView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.backgroundView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];

    // Pin the spacer to the bottom edge.
    self.bottomPlaceholderConstraint =
        [self.bottomPlaceholderView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor
                                                                constant:-safeAreaBottom];
    self.bottomPlaceholderHeightConstraint =
        [self.bottomPlaceholderView.heightAnchor constraintEqualToConstant:0];
    [NSLayoutConstraint activateConstraints:@[
        [self.bottomPlaceholderView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.bottomPlaceholderView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        self.bottomPlaceholderConstraint,
        self.bottomPlaceholderHeightConstraint,
    ]];

    // Position the edit input bar above the spacer.
    [self setupEditInputContainerConstraints];
}

- (void)setupEditInputContainerConstraints {
    // Use Auto Layout for the edit input bar.
    self.editInputBarControl.translatesAutoresizingMaskIntoConstraints = NO;

    // Add the input bar to the background view before activating constraints.
    [self.backgroundView addSubview:self.editInputBarControl];

    self.editInputBarControlBottomConstraint = [self.editInputBarControl.bottomAnchor
        constraintEqualToAnchor:self.bottomPlaceholderView.topAnchor];

    [NSLayoutConstraint activateConstraints:@[
        [self.editInputBarControl.topAnchor constraintEqualToAnchor:self.backgroundView.topAnchor],
        [self.editInputBarControl.leadingAnchor
            constraintEqualToAnchor:self.backgroundView.leadingAnchor],
        [self.editInputBarControl.trailingAnchor
            constraintEqualToAnchor:self.backgroundView.trailingAnchor],
        self.editInputBarControlBottomConstraint
    ]];
}

#pragma mark - Presentation

- (void)showWithConfig:(NCEditInputBarConfig *)config animation:(BOOL)animated {
    [self.editInputBarControl showWithConfig:config];
    if (animated) {
        // Begin below the viewport with a transparent background.
        self.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.bounds));
        self.backgroundColor = [UIColor clearColor];

        [UIView animateWithDuration:0.3
            animations:^{
              // Slide the editor in while dimming the background.
              self.transform = CGAffineTransformIdentity;
              self.backgroundColor = NCMASKCOLOR(0x000000, 0.5);
            }
            completion:^(BOOL finished) {
              [self.editInputBarControl restoreFocus];
            }];
    } else {
        // Apply the final visible state immediately.
        self.backgroundColor = NCMASKCOLOR(0x000000, 0.5);
        [self.editInputBarControl restoreFocus];
    }
}

- (void)hideWithAnimation:(BOOL)animated completion:(void (^_Nullable)(void))completion {
    // Dismiss the input responder before hiding the editor.
    [self.editInputBarControl.editInputContainer resignInputViewFirstResponder];

    self.backgroundColor = [UIColor clearColor];

    if (animated) {
        [UIView animateWithDuration:0.2
            animations:^{
              // Slide the editor out while clearing the background.
              self.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.bounds));
            }
            completion:^(BOOL finished) {
              [self removeFromSuperview];
              if (completion)
                  completion();
            }];
    } else {
        [self removeFromSuperview];
        if (completion)
            completion();
    }
}

#pragma mark - NCEditInputBarControlDelegate

- (void)editInputBarControlCollapseFromFullScreenEdit:(NCEditInputBarControl *)editInputBarControl {
    if ([self.delegate respondsToSelector:@selector(fullScreenEditViewCollapse:)]) {
        [self.delegate fullScreenEditViewCollapse:self];
    }
}

- (void)editInputBarControl:(NCEditInputBarControl *)editInputBarControl
         didConfirmWithText:(NSString *)text {
    if ([self.delegate respondsToSelector:@selector(fullScreenEditView:didConfirmWithText:)]) {
        [self.delegate fullScreenEditView:self didConfirmWithText:text];
    }
}

- (void)editInputBarControlDidCancel:(NCEditInputBarControl *)editInputBarControl {
    if ([self.delegate respondsToSelector:@selector(fullScreenEditViewCancel:)]) {
        [self.delegate fullScreenEditViewCancel:self];
    }
}

- (void)editInputBarControl:(NCEditInputBarControl *)editInputBarControl
           showUserSelector:(void (^)(NCChatUIUserInfo *selectedUser))selectedBlock
                     cancel:(void (^)(void))cancelBlock {
    if ([self.delegate respondsToSelector:@selector(fullScreenEditView:showUserSelector:cancel:)]) {
        [self.delegate fullScreenEditView:self showUserSelector:selectedBlock cancel:cancelBlock];
    }
}

- (void)editInputBarControl:(NCEditInputBarControl *)editInputBarControl
          shouldChangeFrame:(CGRect)frame {
    // Match the spacer height to the requested bottom-bar frame.
    self.bottomPlaceholderHeightConstraint.constant = frame.size.height;
    [self layoutIfNeeded];
}

#pragma mark - Getter Methods

- (void)setIsMentionedEnabled:(BOOL)isMentionedEnabled {
    _isMentionedEnabled = isMentionedEnabled;
    self.editInputBarControl.isMentionedEnabled = isMentionedEnabled;
}

- (NCEditInputBarControl *)editInputBarControl {
    if (!_editInputBarControl) {
        _editInputBarControl = [[NCEditInputBarControl alloc] initWithIsFullScreen:YES];
        _editInputBarControl.channelId = self.channelId;
        _editInputBarControl.delegate = self;
        _editInputBarControl.dataSource = self;
        _editInputBarControl.bottomPanelsContainerView = self.bottomPlaceholderView;
    }
    return _editInputBarControl;
}

@end
