//
//  NCSelectUserViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSelectUserViewController.h"
#import "NCBaseButton.h"
#import "NCBaseTableView.h"
#import "NCChatUICommonDefine.h"
#import "NCPaddingTableViewCell.h"
#import "NCSelectUserView.h"

@interface NCSelectUserViewController () <UITableViewDelegate, UITableViewDataSource,
                                          NCListViewModelResponder>

@property (nonatomic, strong) NCBaseButton *confirmButton;

@property (nonatomic, strong) NCSelectUserView *listView;

@property (nonatomic, strong) NCSelectUserViewModel *viewModel;

@end

@implementation NCSelectUserViewController

- (instancetype)initWithViewModel:(NCSelectUserViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = NCUILocalizedString(@"select_contact");
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
    [self.viewModel fetchData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.viewModel endEditingState];
}

#pragma mark-- private

- (void)setNavigationBarItems {
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
    self.confirmButton.enabled = NO;

    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    self.navigationItem.leftBarButtonItems =
        [NCChatUIUtility getLeftNavigationItems:imgMirror
                                          title:@""
                                         target:self
                                         action:@selector(leftBarButtonItemPressed)];
}

- (void)setupView {
    UIView *bar = [self.viewModel configureSearchBarForViewController:self];
    [self.listView configureSearchBar:bar];
}

#pragma mark-- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmButtonDidClick {
    [self.viewModel selectionDidDone];
}

#pragma mark-- NCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.listView.tableView reloadData];
    self.listView.emptyLabel.hidden = !isEmpty;
}

- (void)updateItem:(NSIndexPath *)indexPath {
    if (self.viewModel.selectUserIds.count > 0) {
        self.confirmButton.enabled = YES;
    } else {
        self.confirmButton.enabled = NO;
    }
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark-- UITableViewDataSource
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
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self.viewModel heightForHeaderInSection:section];
}

// Without this delegate method, the table view uses the header height for its footer.
// Returning 0 or 0.0f does not suppress that default footer height.
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark-- getter

- (NCSelectUserView *)listView {
    if (!_listView) {
        _listView = [NCSelectUserView new];
        _listView.emptyLabel.text = [self.viewModel emptyTip];
        _listView.tableView.delegate = self;
        _listView.tableView.dataSource = self;
    }
    return _listView;
}

- (NCBaseButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[NCBaseButton alloc] init];
        [_confirmButton setTitle:NCUILocalizedString(@"confirm") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:NCDynamicColor(@"primary_color")
                             forState:(UIControlStateNormal)];
        [_confirmButton setTitleColor:NCDynamicColor(@"disabled_color")
                             forState:(UIControlStateDisabled)];
        [_confirmButton addTarget:self
                           action:@selector(confirmButtonDidClick)
                 forControlEvents:UIControlEventTouchUpInside];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        _confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    }
    return _confirmButton;
}

@end
