//
//  NCGroupMemberListViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupMemberListViewController.h"
#import "NCChatUICommonDefine.h"
#import "NCGroupMemberListViewModel.h"
#import "NCSelectUserView.h"
@interface NCGroupMemberListViewController () <UITableViewDelegate, UITableViewDataSource,
                                               NCListViewModelResponder>

@property (nonatomic, strong) NCSelectUserView *membersView;

@property (nonatomic, strong) NCGroupMemberListViewModel *viewModel;

@end

@implementation NCGroupMemberListViewController

- (instancetype)initWithViewModel:(NCGroupMemberListViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = NCUILocalizedString(@"group_members");
    }
    return self;
}

- (void)loadView {
    self.view = self.membersView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel registerCellForTableView:self.membersView.tableView];
    [self setNavigationBarItems];
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.viewModel fetchGroupMembersByPage];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.viewModel endEditingState];
}

#pragma mark-- private

- (void)setNavigationBarItems {
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    self.navigationItem.leftBarButtonItems =
        [NCChatUIUtility getLeftNavigationItems:imgMirror
                                          title:@""
                                         target:self
                                         action:@selector(leftBarButtonItemPressed)];
}

- (void)setupView {
    [self.membersView configureSearchBar:[self.viewModel configureSearchBar]];
}

#pragma mark-- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark-- NCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.membersView.tableView reloadData];
    self.membersView.emptyLabel.hidden = !isEmpty;
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark-- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.memberList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel.memberList[indexPath.row] tableView:tableView
                                         cellForRowAtIndexPath:indexPath];
}

#pragma mark-- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel.memberList[indexPath.row] tableView:tableView
                                       heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView
      willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.viewModel.memberList.count - 10) {
        [self.viewModel fetchGroupMembersByPage];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark-- getter

- (NCSelectUserView *)membersView {
    if (!_membersView) {
        _membersView = [NCSelectUserView new];
        _membersView.tableView.delegate = self;
        _membersView.tableView.dataSource = self;
        _membersView.emptyLabel.text = NCUILocalizedString(@"not_user_found");
    }
    return _membersView;
}

@end
