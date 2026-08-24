//
//  NCFriendListViewController.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFriendListViewController.h"
#import "NCAlertView.h"
#import "NCChatUICommonDefine.h"
#import "NCFriendListView.h"
#import "NCPaddingTableViewCell.h"
@interface NCFriendListViewController () <UITableViewDelegate, UITableViewDataSource,
                                          NCListViewModelResponder>

@property (nonatomic, strong) NCFriendListViewModel *viewModel;
@property (nonatomic, strong) NCFriendListView *listView;
@end

@implementation NCFriendListViewController
- (instancetype)initWithViewModel:(NCFriendListViewModel *)viewModel {
    self = [super init];
    if (self) {
        [viewModel bindResponder:self];
        self.viewModel = viewModel;
    }
    return self;
}

- (void)loadView {
    self.view = self.listView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.viewModel fetchData];
}

- (void)setupView {
    [self.viewModel registerCellForTableView:self.listView.tableView];
    if (!self.title) {
        self.title = NCUILocalizedString(@"friend_list_contact");
    }
    [self configureSearchBar];
    [self configureRightNaviItems];
}

- (void)configureSearchBar {
    UISearchBar *bar = [self.viewModel configureSearchBarForViewController:self];
    [self.listView configureSearchBar:bar];
}

- (void)configureRightNaviItems {
    NSArray *items = [self.viewModel configureRightNaviItemsForViewController:self];
    self.navigationItem.rightBarButtonItems = items;
}

#pragma mark - NCFriendListViewModelResponder
- (void)reloadData:(BOOL)isEmpty {
    [self.listView.tableView reloadData];
    [self.listView.tableView setNeedsLayout];
    [self.listView.tableView layoutIfNeeded];
    self.listView.labEmpty.hidden = !isEmpty;
}

- (void)showTips:(NSString *)tips {
    [NCAlertView showAlertController:nil message:tips hiddenAfterDelay:2];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];
}

#pragma mark - UITableViewDataSource
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.viewModel sectionIndexTitles];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.viewModel numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[NCPaddingTableViewCell class]]) {
        NCPaddingTableViewCell *paddingCell = (NCPaddingTableViewCell *)cell;
        [paddingCell updatePaddingContainer:NCUserManagementPadding trailing:-1];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NCUserManagementCellHeight;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [self.viewModel tableView:tableView viewForHeaderInSection:section];
    ;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self.viewModel heightForHeaderInSection:section];
    ;
}

// Without this delegate method, the table view uses the header height for its footer.
// Returning 0 or 0.0f does not suppress that default footer height.
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark - Property

- (NCFriendListView *)listView {
    if (!_listView) {
        NCFriendListView *listView = [NCFriendListView new];
        listView.tableView.dataSource = self;
        listView.tableView.delegate = self;
        _listView = listView;
    }
    return _listView;
}
@end
