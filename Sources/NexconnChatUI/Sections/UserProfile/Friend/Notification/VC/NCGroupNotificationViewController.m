//
//  NCGroupNotificationViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupNotificationViewController.h"
#import "NCGroupNotificationView.h"
#import "NCGroupNotificationViewModel.h"
#import "NCAlertView.h"
#import "NCChatUICommonDefine.h"

@interface NCGroupNotificationViewController ()<UITableViewDelegate, UITableViewDataSource,NCListViewModelResponder>
@property (nonatomic, strong) NCGroupNotificationViewModel *viewModel;
@property (nonatomic, strong) NCGroupNotificationView *listView;
@end

@implementation NCGroupNotificationViewController
- (instancetype)initWithViewModel:(NCGroupNotificationViewModel *)viewModel
{
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
//    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupView];
    [self.viewModel fetchData];
}

- (void)setupView {
    [self.viewModel registerCellForTableView:self.listView.tableView];
    if (!self.title) {
        self.title = NCUILocalizedString(@"group_notification_all");
    }
    [self configureRightNaviItems];
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    self.navigationItem.leftBarButtonItems = [NCChatUIUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)configureRightNaviItems {
    NSArray *items = [self.viewModel configureRightNaviItemsForViewController:self];
    self.navigationItem.rightBarButtonItems = items;
}

- (void)loadMore {
    [self.viewModel loadMoreData];
}
#pragma mark - NCFriendListViewModelResponder
- (void)reloadData:(BOOL)isEmpty {
    [self.listView.tableView reloadData];
    [self.listView.tableView setNeedsLayout];
    [self.listView.tableView layoutIfNeeded];
    self.listView.labEmpty.hidden = !isEmpty;
}

- (void)refreshingFinished:(BOOL)success withTips:(NSString *)tips {
    [self.listView stopRefreshing];
    [self showTips:tips];
}

- (void)showTips:(NSString *)tips {
    if (tips.length == 0) {
        return;
    }
    [NCAlertView showAlertController:nil
                             message:tips
                    hiddenAfterDelay:2];
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self
                         tableView:tableView
                      didSelectRow:indexPath];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.viewModel numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel numberOfRowsInSection:section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return  [self.viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - Property

- (NCGroupNotificationView *)listView {
    if (!_listView) {
        NCGroupNotificationView *listView = [NCGroupNotificationView new];
        listView.tableView.dataSource = self;
        listView.tableView.delegate = self;
        listView.tableView.estimatedRowHeight = 115;
        [listView addRefreshingTarget:self withSelector:@selector(loadMore)];
        _listView = listView;
    }
    return _listView;
}
@end
