//
//  NCGroupCreateViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupCreateViewController.h"
#import "NCGroupCreateView.h"
#import "NCChatUICommonDefine.h"
@interface NCGroupCreateViewController ()<NCGroupCreateViewDelegate, NCGroupCreateViewModelResponder, UITextFieldDelegate>

@property (nonatomic, strong) NCGroupCreateView *createView;

@property (nonatomic, strong) NCGroupCreateViewModel *viewModel;

@end

@implementation NCGroupCreateViewController

- (instancetype)initWithViewModel:(NCGroupCreateViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.viewModel.responder = self;
    }
    return self;
}

- (void)loadView {
    self.view = self.createView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NCUILocalizedString(@"group_create");
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setNavigationBarItems];
}

#pragma mark -- UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (newText.length > self.viewModel.groupNameLimit) {
        return NO;
    }
    return YES;
}

#pragma mark -- NCGroupCreateViewModelResponder

- (void)groupPortraitDidUpdate:(NSString *)avatarUrl {
    self.createView.portraitImageView.imageURL = [NSURL URLWithString:avatarUrl];
}

#pragma mark -- NCGroupCreateViewDelegate

- (void)portaitImageViewDidClick {
    [self.viewModel portraitImageViewDidClick:self];
}

#pragma mark -- action

- (void)createButtonDidClick {
    [self.viewModel createGroup:self.createView.nameEditView.textField.text inViewController:self];
}

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- private

- (void)setNavigationBarItems {
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    self.navigationItem.leftBarButtonItems = [NCChatUIUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

#pragma mark -- getter

- (NCGroupCreateView *)createView {
    if (!_createView) {
        _createView = [NCGroupCreateView new];
        [_createView.createButton addTarget:self action:@selector(createButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
        _createView.delegate = self;
        _createView.nameEditView.textField.delegate = self;
    }
    return _createView;
}

@end
