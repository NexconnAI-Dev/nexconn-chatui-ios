//
//  NCProfileViewController.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileViewController.h"
#import "NCChatUICommonDefine.h"
#import "NCGroupProfileViewModel.h"
#import "NCMyProfileViewModel.h"
#import "NCProfileTableView.h"
#import "NCUserProfileViewModel.h"
#import "NCViewModelAdapterCenter.h"

@interface NCProfileViewController () <UITableViewDelegate, UITableViewDataSource,
                                       NCListViewModelResponder>

@property (nonatomic, strong) NCProfileViewModel *viewModel;

@property (nonatomic, strong) NCProfileTableView *profileView;

@end

@implementation NCProfileViewController

- (instancetype)initWithViewModel:(NCProfileViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.viewModel.responder = self;
        if ([viewModel isKindOfClass:[NCMyProfileViewModel class]]) {
            self.title = NCUILocalizedString(@"my_profile_title");
        } else if ([viewModel isKindOfClass:[NCGroupProfileViewModel class]]) {
            self.title = NCUILocalizedString(@"group_profile_title");
        } else {
            self.title = NCUILocalizedString(@"user_profile_title");
        }
    }
    return self;
}

- (void)loadView {
    self.view = self.profileView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigationBarItems];
    [self.viewModel registerCellForTableView:self.profileView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.viewModel updateProfile];
}

#pragma mark-- UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];
}

#pragma mark-- UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.profileList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.profileList[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCProfileCellViewModel *viewModel =
        self.viewModel.profileList[indexPath.section][indexPath.row];
    return [viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
    ;
}

- (CGFloat)tableView:(nonnull UITableView *)tableView
    heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NCProfileCellViewModel *viewModel =
        self.viewModel.profileList[indexPath.section][indexPath.row];
    return [viewModel tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark-- NCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.profileView reloadData];
}

- (UIViewController *)currentViewController {
    return self;
}

- (void)updateTitle:(NSString *)title {
    self.title = title;
}

- (void)reloadFooterView {
    self.profileView.tableFooterView = [self.viewModel loadFooterView];
}

#pragma mark-- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
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

#pragma mark-- getter

- (NCProfileTableView *)profileView {
    if (!_profileView) {
        _profileView = [[NCProfileTableView alloc] initWithFrame:CGRectZero
                                                           style:(UITableViewStyleGrouped)];
        _profileView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        _profileView.tableHeaderView =
            [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 15)];
        _profileView.sectionHeaderHeight = 0;
        _profileView.separatorStyle = UITableViewCellSeparatorStyleNone;
        if (@available(iOS 15.0, *)) {
            _profileView.sectionHeaderTopPadding = 15;
        }
        _profileView.delegate = self;
        _profileView.dataSource = self;
    }
    return _profileView;
}
@end
