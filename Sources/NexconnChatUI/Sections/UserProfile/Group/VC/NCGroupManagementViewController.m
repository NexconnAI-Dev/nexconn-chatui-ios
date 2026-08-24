//
//  NCGroupManagementViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//
#import "NCGroupManagementViewController.h"
#import "NCBaseTableView.h"
#import "NCChatUICommonDefine.h"

@interface NCGroupManagementViewController () <UITableViewDelegate, UITableViewDataSource,
                                               NCListViewModelResponder>

@property (nonatomic, strong) NCBaseTableView *tableView;

@property (nonatomic, strong) NCGroupManagementViewModel *viewModel;

@end

@implementation NCGroupManagementViewController

- (instancetype)initWithViewModel:(NCGroupManagementViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = NCUILocalizedString(@"group_management");
    }
    return self;
}

- (void)loadView {
    self.view = self.tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel registerCellForTableView:self.tableView];
    [self setNavigationBarItems];
    [self.viewModel fetchDataSources];
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

#pragma mark-- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark-- NCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.tableView reloadData];
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark-- UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.viewModel numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark-- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark-- getter

- (NCBaseTableView *)tableView {
    if (!_tableView) {
        _tableView = [[NCBaseTableView alloc] initWithFrame:CGRectZero
                                                      style:(UITableViewStyleGrouped)];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        _tableView.tableFooterView = [UIView new];
        _tableView.tableHeaderView =
            [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 15)];
        _tableView.sectionHeaderHeight = 0;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 15;
        }
    }
    return _tableView;
}
@end
