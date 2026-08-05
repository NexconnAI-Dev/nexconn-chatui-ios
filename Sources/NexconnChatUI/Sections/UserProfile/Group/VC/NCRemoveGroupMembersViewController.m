//
//  NCRemoveGroupMembersViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCRemoveGroupMembersViewController.h"
#import "NCBaseButton.h"
#import "NCBaseTableView.h"
#import "NCChatUICommonDefine.h"
#import "NCSelectUserView.h"
@interface NCRemoveGroupMembersViewController ()<
UITableViewDelegate,
UITableViewDataSource,
NCListViewModelResponder
>

@property (nonatomic, strong) NCBaseButton *confirmButton;

@property (nonatomic, strong) NCSelectUserView *listView;

@property (nonatomic, strong) NCRemoveGroupMembersViewModel *viewModel;


@end

@implementation NCRemoveGroupMembersViewController

- (instancetype)initWithViewModel:(NCRemoveGroupMembersViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = NCUILocalizedString(@"group_members_kick");
    }
    return self;
}

- (void)loadView {
    self.view = self.listView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel registerCellForTableView:self.listView.tableView];
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

#pragma mark -- private

- (void)setNavigationBarItems {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
    self.confirmButton.enabled = NO;
    
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    self.navigationItem.leftBarButtonItems = [NCChatUIUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

- (void)setupView {
    [self.listView configureSearchBar:[self.viewModel configureSearchBar]];
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmButtonDidClick {
    [self.viewModel selectionDidDone];
}

- (void)itemSelectDidUpdate {
    if (self.viewModel.selectUserIds.count > 0) {
        self.confirmButton.enabled = YES;
    } else {
        self.confirmButton.enabled = NO;
    }
}

#pragma mark -- NCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.listView.tableView reloadData];
    self.listView.emptyLabel.hidden = !isEmpty;
}

- (void)updateItem:(NSIndexPath *)indexPath {
    [self itemSelectDidUpdate];
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark -- UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self
                         tableView:tableView
                      didSelectRow:indexPath];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.memberList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return  [self.viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel.memberList[indexPath.row] tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark -- getter

- (NCSelectUserView *)listView {
    if (!_listView) {
        _listView = [NCSelectUserView new];
        _listView.emptyLabel.text = NCUILocalizedString(@"not_user_found");
        _listView.tableView.delegate = self;
        _listView.tableView.dataSource = self;
    }
    return _listView;
}

- (NCBaseButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [NCBaseButton buttonWithType:UIButtonTypeCustom];
        [_confirmButton setTitle:NCUILocalizedString(@"confirm") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:NCDynamicColor(@"primary_color") forState:(UIControlStateNormal)];
        [_confirmButton setTitleColor:NCDynamicColor(@"disabled_color") forState:(UIControlStateDisabled)];
        [_confirmButton addTarget:self action:@selector(confirmButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        _confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    }
    return _confirmButton;
}
@end
