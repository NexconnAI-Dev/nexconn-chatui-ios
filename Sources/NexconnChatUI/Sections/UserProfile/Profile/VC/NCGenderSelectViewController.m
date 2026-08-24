//
//  NCGenderSelectViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGenderSelectViewController.h"
#import "NCBaseButton.h"
#import "NCBaseTableView.h"
#import "NCChatUICommonDefine.h"
#import "NCProfileGenderViewModel.h"

#define NCGenderSelectViewControllerConfirmWidth 100
#define NCGenderSelectViewControllerConfirmHeight 40

@interface NCGenderSelectViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NCProfileGenderViewModel *viewModel;

@property (nonatomic, strong) NCBaseTableView *genderView;

@property (nonatomic, strong) NCBaseButton *confirmButton;

@end

@implementation NCGenderSelectViewController

- (instancetype)initWithViewModel:(id)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
    }
    return self;
}

- (void)loadView {
    self.view = self.genderView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NCUILocalizedString(@"gender_edit");
    [self.viewModel registerCellForTableView:self.genderView];
    [self setNavigationBarItems];
}

- (void)setNavigationBarItems {
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];

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
    [self.viewModel updateUserProfileGender:self];
}

#pragma mark-- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCProfileGenderCellViewModel *cellViewModel = self.viewModel.dataSource[indexPath.row];
    return [cellViewModel tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark-- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel.dataSource[indexPath.row] tableView:tableView
                                       heightForRowAtIndexPath:indexPath];
}

#pragma mark-- getter

- (NCBaseTableView *)genderView {
    if (!_genderView) {
        _genderView = [[NCBaseTableView alloc] initWithFrame:CGRectZero
                                                       style:UITableViewStyleGrouped];
        _genderView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        _genderView.tableHeaderView =
            [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 15)];
        _genderView.sectionHeaderHeight = 0;
        _genderView.separatorStyle = UITableViewCellSeparatorStyleNone;
        if (@available(iOS 15.0, *)) {
            _genderView.sectionHeaderTopPadding = 15;
        }
        _genderView.delegate = self;
        _genderView.dataSource = self;
    }
    return _genderView;
}

- (NCBaseButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [NCBaseButton buttonWithType:UIButtonTypeCustom];
        [_confirmButton setTitle:NCUILocalizedString(@"confirm") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:NCDynamicColor(@"primary_color")
                             forState:(UIControlStateNormal)];
        [_confirmButton addTarget:self
                           action:@selector(confirmButtonDidClick)
                 forControlEvents:UIControlEventTouchUpInside];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        _confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    }
    return _confirmButton;
}

@end
