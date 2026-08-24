//
//  NCGroupMentionViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupMentionViewController.h"
#import "NCChatUICommonDefine.h"
#import "NCGroupMemberListViewModel.h"
#import "NCSearchBarListView.h"
@interface NCGroupMentionViewController () <UITableViewDelegate, UITableViewDataSource,
                                            NCListViewModelResponder>

@property (nonatomic, strong) NCSearchBarListView *membersView;

@property (nonatomic, strong) NCGroupMentionViewModel *viewModel;

@end

@implementation NCGroupMentionViewController

- (instancetype)initWithViewModel:(NCGroupMentionViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = NCUILocalizedString(@"select_mentioned_user");
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
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.viewModel selectionCanceled];
}

#pragma mark-- NCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.membersView.tableView reloadData];
    self.membersView.labEmpty.hidden = !isEmpty;
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark-- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark-- UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.viewModel numberOfSections];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView
      willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.viewModel.memberList.count - 10) {
        [self.viewModel fetchGroupMembersByPage];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self.viewModel heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [self.viewModel tableView:tableView viewForHeaderInSection:section];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark-- getter

- (NCSearchBarListView *)membersView {
    if (!_membersView) {
        _membersView = [NCSearchBarListView new];
        _membersView.tableView.delegate = self;
        _membersView.tableView.dataSource = self;
        _membersView.labEmpty.text = NCUILocalizedString(@"not_user_found");
    }
    return _membersView;
}

@end
