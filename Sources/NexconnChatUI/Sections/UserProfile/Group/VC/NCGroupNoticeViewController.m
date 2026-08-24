//
//  NCGroupNoticeViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupNoticeViewController.h"
#import "NCAlertView.h"
#import "NCBaseButton.h"
#import "NCChatUICommonDefine.h"
#import "NCGroupNoticeView.h"
@interface NCGroupNoticeViewController () <UITextViewDelegate>

@property (nonatomic, strong) NCGroupNoticeViewModel *viewModel;

@property (nonatomic, strong) NCGroupNoticeView *noticeView;

@property (nonatomic, strong) NCBaseButton *confirmButton;

@end

@implementation NCGroupNoticeViewController

- (instancetype)initWithViewModel:(NCGroupNoticeViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
    }
    return self;
}

- (void)loadView {
    self.view = self.noticeView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setNavigationBarItems];
    [self setupView];
}

#pragma mark-- UITextViewDelegate

- (BOOL)textView:(UITextView *)textView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text {
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (newText.length > self.viewModel.limit) {
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.confirmButton.enabled = [self.viewModel canSaveNotice:textView.text];
}

#pragma mark-- private

- (void)setupView {
    self.noticeView.textView.text = self.viewModel.group.notice;
    self.noticeView.tipLabel.text = [self.viewModel tip];
    [self.noticeView updateTextViewHeight:self.viewModel.canEdit];
    BOOL isEmtpy = (self.viewModel.group.notice.length == 0 && !self.viewModel.canEdit);
    [self.noticeView showEmptylabel:isEmtpy];
}

- (void)setNavigationBarItems {
    if (self.viewModel.canEdit) {
        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
        self.confirmButton.enabled = NO;
    }

    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    self.navigationItem.leftBarButtonItems =
        [NCChatUIUtility getLeftNavigationItems:imgMirror
                                          title:@""
                                         target:self
                                         action:@selector(leftBarButtonItemPressed)];
}

#pragma mark-- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmButtonDidClick {
    [self.noticeView.textView resignFirstResponder];
    [self.viewModel updateNotice:self.noticeView.textView.text inViewController:self];
}

#pragma mark-- getter

- (NCGroupNoticeView *)noticeView {
    if (!_noticeView) {
        _noticeView = [NCGroupNoticeView new];
        _noticeView.textView.delegate = self;
    }
    return _noticeView;
}

- (NCBaseButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [NCBaseButton buttonWithType:UIButtonTypeCustom];
        [_confirmButton setTitle:NCUILocalizedString(@"save") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:NCDynamicColor(@"primary_color")
                             forState:(UIControlStateNormal)];
        [_confirmButton setTitleColor:NCDynamicColor(@"disabled_color")
                             forState:(UIControlStateDisabled)];
        [_confirmButton addTarget:self
                           action:@selector(confirmButtonDidClick)
                 forControlEvents:UIControlEventTouchUpInside];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        _confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _confirmButton.enabled = NO;
    }
    return _confirmButton;
}

@end
