//
//  NCUserSearchViewController.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUserSearchViewController.h"
#import "NCUserSearchView.h"
#import "NCChatUICommonDefine.h"
@interface NCUserSearchViewController ()<NCListViewModelResponder>
@property (nonatomic, strong) NCUserSearchView *listView;
@property (nonatomic, strong) NCUserSearchViewModel *viewModel;
@end

@implementation NCUserSearchViewController

- (instancetype)initWithViewModel:(NCUserSearchViewModel *)viewModel
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
    [self setupView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.viewModel endEditingState];
}

- (void)setupView {
    if (!self.title) {
        self.title = NCUILocalizedString(@"user_search_add_new");
    }
    [self configureSearchBar];
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    self.navigationItem.leftBarButtonItems = [NCChatUIUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
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
    [self.listView displayEmptyView:isEmpty];
}

#pragma mark - UITableViewDelegate


#pragma mark - Property

- (NCUserSearchView *)listView {
    if (!_listView) {
        NCUserSearchView *listView = [NCUserSearchView new];
        _listView = listView;
    }
    return _listView;
}

@end
