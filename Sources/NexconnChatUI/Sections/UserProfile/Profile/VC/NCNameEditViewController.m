//
//  NCNameEditViewController.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCNameEditViewController.h"
#import "NCNameEditView.h"
#import "NCBaseButton.h"
#import "NCChatUICommonDefine.h"
#import "NCAlertView.h"
#define NCNameEditViewTop 15

@interface NCNameEditViewController ()<
NCNameEditViewModelDelegate,
UITextFieldDelegate
>

@property (nonatomic, strong) NCBaseButton *confirmButton;

@property (nonatomic, strong) NCNameEditView *nameEditView;

@property (nonatomic, strong) NCNameEditViewModel *viewModel;

@end

@implementation NCNameEditViewController

- (instancetype)initWithViewModel:(NCNameEditViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.viewModel.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.viewModel.title;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupView];
    [self setNavigationBarItems];
    __weak typeof(self) weakSelf = self;
    [self.viewModel getCurrentName:^(NSString * name) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.nameEditView.textField.text = name;
        });
    }];
}

- (void)setupView {
    self.view.backgroundColor = self.nameEditView.backgroundColor;
    [self.view addSubview:self.nameEditView];
    self.nameEditView.frame = CGRectOffset(self.view.bounds, 0, NCNameEditViewTop);
}
#pragma mark -- NCNameEditViewModelDelegate

- (void)nameUpdateDidSuccess {
    [self.navigationController popViewControllerAnimated:YES];
    [NCAlertView showAlertController:nil
                             message:NCUILocalizedString(@"set_success")
                    hiddenAfterDelay:2];
}

- (void)nameUpdateDidError:(NSString *)errorInfo {
    if (errorInfo.length > 0) {
        [NCAlertView showAlertController:nil 
                                 message:errorInfo
                        hiddenAfterDelay:2];
    }
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark -- UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.confirmButton.enabled = YES;
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (newText.length > self.viewModel.limit) {
        return NO;
    }
    return YES;
}


#pragma mark -- private

- (void)setNavigationBarItems {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
    self.confirmButton.enabled = NO;
    
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    self.navigationItem.leftBarButtonItems = [NCChatUIUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmButtonDidClick {
    [self.viewModel updateName:self.nameEditView.textField.text];
}

#pragma mark -- getter

- (NCNameEditView *)nameEditView {
    if (!_nameEditView) {
        _nameEditView = [[NCNameEditView alloc] init];
        _nameEditView.contentLabel.text = self.viewModel.content;
        _nameEditView.textField.placeholder = self.viewModel.placeHolder;
        _nameEditView.tipLabel.text = self.viewModel.tip;
        _nameEditView.textField.delegate = self;
    }
    return _nameEditView;
}

- (NCBaseButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[NCBaseButton alloc] init];
        [_confirmButton setTitle:NCUILocalizedString(@"confirm") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:NCDynamicColor(@"primary_color") forState:(UIControlStateNormal)];
        [_confirmButton setTitleColor:NCDynamicColor(@"disabled_color") forState:(UIControlStateDisabled)];
        [_confirmButton addTarget:self action:@selector(confirmButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        _confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_confirmButton sizeToFit];
        _confirmButton.enabled = NO;
    }
    return _confirmButton;
}

@end
