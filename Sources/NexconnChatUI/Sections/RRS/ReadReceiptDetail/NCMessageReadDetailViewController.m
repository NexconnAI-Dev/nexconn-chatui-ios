//
//  NCMessageReadDetailViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageReadDetailViewController.h"
#import "NCMessageReadDetailViewModel.h"
#import "NCMessageReadDetailView.h"
#import "NCMessageModel.h"
#import "NCChatUICommonDefine.h"
#import "NCMessageReadDetailCell.h"

@interface NCMessageReadDetailViewController ()<UITableViewDelegate, UITableViewDataSource, NCMessageReadDetailViewModelResponder, NCMessageReadDetailViewDelegate>

@property (nonatomic, strong) NCMessageReadDetailViewModel *viewModel;

/// Header view.
@property (nonatomic, strong) UIView *headerView;

/// Main content view.
@property (nonatomic, strong) NCMessageReadDetailView *mainView;

@end

@implementation NCMessageReadDetailViewController

- (instancetype)initWithViewModel:(NCMessageReadDetailViewModel *)viewModel {
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        [_viewModel bindResponder:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NCUILocalizedString(@"message_read_status");
    self.view.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    
    [self setupView];
    [self setupNavigationBar];
    [self.viewModel loadData];
}

#pragma mark - UI Setup

- (void)setupView {
    // Obtain the header view.
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(viewController:headerViewWithMessage:)]) {
        self.headerView = [self.dataSource viewController:self headerViewWithMessage:self.viewModel.messageModel];
    }
    
    // Add the header view when provided.
    if (self.headerView) {
        self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:self.headerView];
    }
    
    // Add the main content view.
    self.mainView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mainView];
    
    // Install constraints.
    [self setupViewConstraints];
    
    // Set the read and unread counts.
    NSInteger readCount = self.viewModel.messageModel.readReceiptInfo.readCount;
    NSInteger unreadCount = self.viewModel.messageModel.readReceiptInfo.unreadCount;
    [self.mainView setupReadCount:readCount unreadCount:unreadCount];
}

- (void)setupViewConstraints {
    NSLayoutAnchor *topAnchor;
    if (@available(iOS 11.0, *)) {
        topAnchor = self.view.safeAreaLayoutGuide.topAnchor;
    } else {
        topAnchor = self.view.topAnchor;
    }
    
    // Constrain the header first when it exists.
    if (self.headerView) {
        [NSLayoutConstraint activateConstraints:@[
            [self.headerView.topAnchor constraintEqualToAnchor:topAnchor],
            [self.headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
        ]];
        topAnchor = self.headerView.bottomAnchor;
    }
    
    // Main content constraints.
    [NSLayoutConstraint activateConstraints:@[
        [self.mainView.topAnchor constraintEqualToAnchor:topAnchor],
        [self.mainView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mainView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mainView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)setupNavigationBar {
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    self.navigationItem.leftBarButtonItems = [NCChatUIUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NCMessageReadDetailTabType tabType = [self.mainView tabTypeForTableView:tableView];
    return [self.viewModel numberOfSectionsForTabType:tabType];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NCMessageReadDetailTabType tabType = [self.mainView tabTypeForTableView:tableView];
    return [self.viewModel numberOfRowsForTabType:tabType inSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCMessageReadDetailTabType tabType = [self.mainView tabTypeForTableView:tableView];
    return [self.viewModel cellHeightForTabType:tabType atIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCMessageReadDetailTabType tabType = [self.mainView tabTypeForTableView:tableView];
    
    NCMessageReadDetailCellViewModel *cellViewModel = [self.viewModel cellViewModelForTabType:tabType atIndex:indexPath.row];
    if (!cellViewModel) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
    }
    
    NCMessageReadDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:[NCMessageReadDetailCell reuseIdentifier] forIndexPath:indexPath];
    [cell bindViewModel:cellViewModel];
    cell.contentView.backgroundColor = tableView.backgroundColor;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - NCMessageReadDetailViewDelegate

/// Handles tab selection changes.
- (void)readReceiptUserListView:(NCMessageReadDetailView *)view didSwitchToTab:(NCMessageReadDetailTabType)tabType {
    [self.viewModel switchTabToType:tabType];
    
    // Determine whether the selected list is empty.
    BOOL isEmpty = (tabType == NCMessageReadDetailTabTypeRead) 
        ? (self.viewModel.readUserList.count == 0) 
        : (self.viewModel.unreadUserList.count == 0);
    
    // Update the visible state.
    [self.mainView switchToTabType:tabType isEmpty:isEmpty];
    
    // Update the empty-state text.
    if (isEmpty) {
        [self updateEmptyViewTextForTabType:tabType];
    }
}

/// Handles requests to load more data.
- (void)readReceiptUserListView:(NCMessageReadDetailView *)view needLoadMoreForTabType:(NCMessageReadDetailTabType)tabType {
    [self.viewModel loadMoreData];
}

#pragma mark - NCMessageReadDetailViewModelResponder

/// Updates a read or unread user list.
/// @param tabType The read or unread list type.
/// @param isEmpty Whether the list is empty.
/// @param hasMoreData Whether more data is available.
- (void)updateUserListForTabType:(NCMessageReadDetailTabType)tabType
                         isEmpty:(BOOL)isEmpty
                     hasMoreData:(BOOL)hasMoreData {
    // Reload the list and end its loading state.
    [self.mainView reloadDataForTabType:tabType hasMoreData:hasMoreData];
    
    // Update the UI only when this list owns the selected tab,
    // preventing concurrent loads from affecting the other tab.
    if (self.viewModel.currentTabType == tabType) {
        if (isEmpty) {
            [self updateEmptyViewTextForTabType:tabType];
        }
        [self.mainView switchToTabType:tabType isEmpty:isEmpty];
    }
}

- (UIViewController *)currentViewController {
    return self;
}

/// Updates the read and unread counts in the tab view.
- (void)updateTabViewWithReadCount:(NSInteger)readCount unreadCount:(NSInteger)unreadCount {
    [self.mainView setupReadCount:readCount unreadCount:unreadCount];
}

#pragma mark - Private Methods

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

/// Updates the empty-state text for the selected tab.
- (void)updateEmptyViewTextForTabType:(NCMessageReadDetailTabType)tabType {
    NSString *text;
    if (tabType == NCMessageReadDetailTabTypeRead) {
        text = NCUILocalizedString(@"message_read_status_none_read");
    } else {
        text = NCUILocalizedString(@"message_read_status_all_read");
    }
    [self.mainView updateEmptyViewText:text];
}

#pragma mark - Getter

- (NCMessageReadDetailView *)mainView {
    if (!_mainView) {
        CGFloat tabHeight = self.viewModel.config.tabHeight;
        _mainView = [[NCMessageReadDetailView alloc] initWithFrame:CGRectZero tabHeight:tabHeight];
        _mainView.delegate = self;
        
        // Configure the table view delegate and data source.
        _mainView.readTableView.delegate = self;
        _mainView.readTableView.dataSource = self;
        _mainView.unreadTableView.delegate = self;
        _mainView.unreadTableView.dataSource = self;
        
        // Register the cell.
        [_mainView.readTableView registerClass:[NCMessageReadDetailCell class] forCellReuseIdentifier:[NCMessageReadDetailCell reuseIdentifier]];
        [_mainView.unreadTableView registerClass:[NCMessageReadDetailCell class] forCellReuseIdentifier:[NCMessageReadDetailCell reuseIdentifier]];
    }
    return _mainView;
}

@end
