//
//  NCMessageReadDetailView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageReadDetailView.h"
#import "NCMessageReadDetailTabView.h"
#import "NCChatUIConfig.h"
#import "NCChatUICommonDefine.h"
#import "NCMJRefresh.h"
#import "NCImageView.h"

@interface NCMessageReadDetailView () <NCReadReceiptDetailTabViewDelegate>

/// Read and unread tab view.
@property (nonatomic, strong, readwrite) NCMessageReadDetailTabView *tabView;

/// List container view.
@property (nonatomic, strong) UIView *tableContainerView;

/// Read-users table view.
@property (nonatomic, strong, readwrite) UITableView *readTableView;

/// Unread-users table view.
@property (nonatomic, strong, readwrite) UITableView *unreadTableView;

/// Empty-state container.
@property (nonatomic, strong) UIView *emptyContainerView;

/// Empty-state image view.
@property (nonatomic, strong) UIImageView *emptyImageView;

/// Empty-state label.
@property (nonatomic, strong) UILabel *emptyLabel;

/// Tab view height.
@property (nonatomic, assign) CGFloat tabHeight;

@end

@implementation NCMessageReadDetailView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame tabHeight:(CGFloat)tabHeight {
    self = [super initWithFrame:frame];
    if (self) {
        _tabHeight = tabHeight;
        [self setupView];
    }
    return self;
}

#pragma mark - UI Setup

- (void)setupView {
    self.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    
    // 1. Tab selector.
    self.tabView = [[NCMessageReadDetailTabView alloc] initWithFrame:CGRectZero];
    [self.tabView setupSelectedColor:NCDynamicColor(@"primary_color")
                   unselectedColor:NCDynamicColor(@"text_secondary_color")];
    self.tabView.delegate = self;
    self.tabView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.tabView];
    
    // 2. List container.
    self.tableContainerView = [[UIView alloc] init];
    self.tableContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.tableContainerView];
    
    // 3. Read-users list.
    self.readTableView = [self createTableView];
    [self.tableContainerView addSubview:self.readTableView];
    
    // 4. Unread-users list.
    self.unreadTableView = [self createTableView];
    self.unreadTableView.hidden = YES;
    [self.tableContainerView addSubview:self.unreadTableView];
    
    // 5. Empty state.
    [self.tableContainerView addSubview:self.emptyContainerView];
    
    [self setupViewConstraints];
}

- (UITableView *)createTableView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.backgroundColor = self.backgroundColor;
    tableView.rowHeight = 54;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (@available(iOS 11.0, *)) {
        tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    }
    
    CGFloat leftOffset = [NCChatUIConfig defaultConfig].ui.globalConversationPortraitSize.width + 12;
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        tableView.separatorInset = UIEdgeInsetsMake(0, leftOffset, 0, 0);
    }
    
    __weak typeof(self) weakSelf = self;
    NCMJRefreshAutoNormalFooter *footer = [NCMJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(readReceiptUserListView:needLoadMoreForTabType:)]) {
            // Identify the tab from the currently visible table view.
            NCMessageReadDetailTabType tabType = tableView == strongSelf.readTableView 
                ? NCMessageReadDetailTabTypeRead 
                : NCMessageReadDetailTabTypeUnread;
            [strongSelf.delegate readReceiptUserListView:strongSelf needLoadMoreForTabType:tabType];
        }
    }];
    footer.refreshingTitleHidden = YES;
    tableView.ncmj_footer = footer;
    
    return tableView;
}

- (void)setupViewConstraints {
    // Tab view constraints.
    [NSLayoutConstraint activateConstraints:@[
        [self.tabView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.tabView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.tabView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.tabView.heightAnchor constraintEqualToConstant:self.tabHeight]
    ]];
    
    // List container constraints.
    [NSLayoutConstraint activateConstraints:@[
        [self.tableContainerView.topAnchor constraintEqualToAnchor:self.tabView.bottomAnchor],
        [self.tableContainerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.tableContainerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.tableContainerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    
    // Table view constraints.
    [self setupTableViewConstraints:self.readTableView];
    [self setupTableViewConstraints:self.unreadTableView];
    
    // Empty-state constraints.
    self.emptyContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyContainerView.centerXAnchor constraintEqualToAnchor:self.tableContainerView.centerXAnchor],
        [self.emptyContainerView.centerYAnchor constraintEqualToAnchor:self.tableContainerView.centerYAnchor],
        [self.emptyContainerView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.tableContainerView.leadingAnchor constant:20],
        [self.emptyContainerView.trailingAnchor constraintLessThanOrEqualToAnchor:self.tableContainerView.trailingAnchor constant:-20]
    ]];
}

- (void)setupTableViewConstraints:(UITableView *)tableView {
    [NSLayoutConstraint activateConstraints:@[
        [tableView.topAnchor constraintEqualToAnchor:self.tableContainerView.topAnchor],
        [tableView.leadingAnchor constraintEqualToAnchor:self.tableContainerView.leadingAnchor],
        [tableView.trailingAnchor constraintEqualToAnchor:self.tableContainerView.trailingAnchor],
        [tableView.bottomAnchor constraintEqualToAnchor:self.tableContainerView.bottomAnchor]
    ]];
}

#pragma mark - Public Methods

- (void)setupReadCount:(NSInteger)readCount unreadCount:(NSInteger)unreadCount {
    [self.tabView setupReadCount:readCount unreadCount:unreadCount];
}

- (void)switchToTabType:(NCMessageReadDetailTabType)tabType isEmpty:(BOOL)isEmpty {
    BOOL isReadTab = (tabType == NCMessageReadDetailTabTypeRead);
    
    // Switch the visible table view.
    self.readTableView.hidden = !isReadTab;
    self.unreadTableView.hidden = isReadTab;
    
    // Update the empty state.
    self.emptyContainerView.hidden = !isEmpty;
}

- (void)updateEmptyViewText:(NSString *)text {
    self.emptyLabel.text = text;
}

- (void)reloadDataForTabType:(NCMessageReadDetailTabType)tabType hasMoreData:(BOOL)hasMoreData {
    // Select the corresponding table view.
    UITableView *tableView = tabType == NCMessageReadDetailTabTypeRead
        ? self.readTableView
        : self.unreadTableView;
    
    // Reload the list.
    [tableView reloadData];
    
    // End the pull-to-refresh animation.
    if (hasMoreData) {
        [tableView.ncmj_footer endRefreshing];
    } else {
        [tableView.ncmj_footer endRefreshingWithNoMoreData];
    }
}

- (NCMessageReadDetailTabType)tabTypeForTableView:(UITableView *)tableView {
    if (tableView == self.readTableView) {
        return NCMessageReadDetailTabTypeRead;
    }
    return NCMessageReadDetailTabTypeUnread;
}

#pragma mark - NCReadReceiptDetailTabViewDelegate

- (void)tabView:(NCMessageReadDetailTabView *)tabView didSelectTabAtIndex:(NCMessageReadDetailTabType)tabType {
    if ([self.delegate respondsToSelector:@selector(readReceiptUserListView:didSwitchToTab:)]) {
        [self.delegate readReceiptUserListView:self didSwitchToTab:tabType];
    }
}

#pragma mark - Getter

- (UIView *)emptyContainerView {
    if (!_emptyContainerView) {
        UIView *containerView = [[UIView alloc] init];
        containerView.hidden = YES;
        
        // Create the icon.
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = NCDynamicImage(@"channel_msg_rrs_read_list_empty_img");
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [containerView addSubview:imageView];
        self.emptyImageView = imageView;
        
        // Create the label.
        UILabel *label = [[UILabel alloc] init];
        label.textColor = NCDynamicColor(@"text_primary_color");
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [containerView addSubview:label];
        
        // Retain the label for later text updates.
        self.emptyLabel = label;
        
        // Install internal constraints.
        [NSLayoutConstraint activateConstraints:@[
            // Icon constraints.
            [imageView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
            [imageView.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor],
            [imageView.widthAnchor constraintEqualToConstant:52],
            [imageView.heightAnchor constraintEqualToConstant:52],
            
            // Label constraints.
            [label.topAnchor constraintEqualToAnchor:imageView.bottomAnchor constant:10],
            [label.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
            [label.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
            [label.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor]
        ]];
        
        _emptyContainerView = containerView;
    }
    return _emptyContainerView;
}

@end
