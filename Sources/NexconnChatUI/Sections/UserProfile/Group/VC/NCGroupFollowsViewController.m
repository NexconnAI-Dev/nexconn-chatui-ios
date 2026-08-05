//
//  NCGroupFollowsViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupFollowsViewController.h"
#import "NCSelectUserView.h"
#import "NCChatUICommonDefine.h"

@interface NCGroupFollowsViewController ()<
UITableViewDelegate,
UITableViewDataSource,
NCListViewModelResponder
>

@property (nonatomic, strong) NCSelectUserView *selectUserView;

@property (nonatomic, strong) NCGroupFollowsViewModel *viewModel;

@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation NCGroupFollowsViewController

- (instancetype)initWithViewModel:(NCGroupFollowsViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = NCUILocalizedString(@"group_follows_vc_title");
    }
    return self;
}

- (void)loadView {
    self.view = self.selectUserView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel registerCellForTableView:self.selectUserView.tableView];
    [self setNavigationBarItems];
    [self setupView];
    [self.viewModel fetchGroupFollows];
}

#pragma mark -- private

- (void)setNavigationBarItems {
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    self.navigationItem.leftBarButtonItems = [NCChatUIUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

- (void)setupView {
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- NCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.selectUserView.tableView reloadData];
    self.selectUserView.emptyLabel.hidden = !isEmpty;
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark -- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark -- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark -- getter

- (NCSelectUserView *)selectUserView {
    if (!_selectUserView) {
        _selectUserView = [NCSelectUserView new];
        _selectUserView.tableView.delegate = self;
        _selectUserView.tableView.dataSource = self;
        _selectUserView.emptyLabel.text = NCUILocalizedString(@"no_group_follows");
    }
    return _selectUserView;
}

@end
