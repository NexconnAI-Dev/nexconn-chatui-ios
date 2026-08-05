//
//  NCMyGroupsViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMyGroupsViewModel.h"
#import "NCGroupInfoCellViewModel.h"
#import "NCChatUICommonDefine.h"
#import "NCSearchGroupsViewController.h"
#import "NCGroupManager.h"

NSInteger const NCGroupInfoMaxCount = 50;

static void *NCMyGroupsOperationQueueSpecificKey = &NCMyGroupsOperationQueueSpecificKey;

@interface NCMyGroupsViewModel()<NCSearchBarViewModelDelegate>

@property (nonatomic, strong) NCSearchBarViewModel *searchBarVM;
// All cells.
@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, weak) UIViewController <NCListViewModelResponder> *responder;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) NCUIPagingQueryOption *option;

@property (nonatomic, weak) NCGroupInfoCellViewModel *lastBottomCellVM;
@end

@implementation NCMyGroupsViewModel
@dynamic delegate;

- (instancetype)initWithOption:(nullable NCUIPagingQueryOption *)option {
    self = [super init];
    if (self) {
        [self ready];
        self.option = option;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self ready];
    }
    return self;
}
- (void)ready {
    self.dataSource = [NSMutableArray array];
    self.queue = dispatch_queue_create("ai.nexconn.myGroups.operationQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(self.queue, NCMyGroupsOperationQueueSpecificKey, NCMyGroupsOperationQueueSpecificKey, NULL);
}

/// Configures navigation.
- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForMyGroupsViewModel:)]) {
        NCNavigationItemsViewModel *naviItemsVM = [self.delegate willConfigureRightNavigationItemsForMyGroupsViewModel:self];
        return [naviItemsVM rightNavigationBarItems];

    }
    return nil;
}

/// Configures the search bar.
- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureSearchBarViewModelForMyGroupsViewModel:)]) {
        self.searchBarVM = [self.delegate willConfigureSearchBarViewModelForMyGroupsViewModel:self];
    } else if(!self.searchBarVM) {
        NCSearchBarViewModel *vm = [[NCSearchBarViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

/// Loads data.
- (void)fetchData {
    if (!self.option) {
        NCUIPagingQueryOption *opt = [[NCUIPagingQueryOption alloc] init];
        opt.count = NCGroupInfoMaxCount;
        self.option = opt;
    }
    [self.dataSource removeAllObjects];
    [self fetchDataWithOption:self.option];
}

/// Binds responders.
- (void)bindResponder:(UIViewController <NCListViewModelResponder>*)responder {
    self.responder = responder;
}

/// Returns the cell height.
/// - Parameters:
///   - tableView: tableView
///   - indexPath: indexPath
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NCUserManagementCellHeight;
}

/// Loads the next page.
- (void)loadMoreData {
    [self fetchDataWithOption:self.option];
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCGroupInfoCellViewModel *vm = [self.dataSource objectAtIndex:indexPath.row];
    return [vm tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    NCGroupInfoCellViewModel *vm = [self.dataSource objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(myGroupsViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate myGroupsViewModel:self
                                     viewController:viewController
                                          tableView:tableView
                                       didSelectRow:indexPath
                                      cellViewModel:vm];
        if (ret) {
            return;
        }
    }
    [vm itemDidSelectedByViewController:viewController];
}

#pragma mark - Protocol
- (void)registerCellForTableView:(UITableView *)tableView {
    [NCGroupInfoCellViewModel registerCellForTableView:tableView];
}

- (NSInteger)numberOfSections {
    return 1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

#pragma mark - SearchBar
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self showSearchGroups];
    return NO;
}

- (void)showSearchGroups {
    NCSearchGroupsViewModel *viewModel = [[NCSearchGroupsViewModel alloc] init];
    NCSearchGroupsViewController *vc = [[NCSearchGroupsViewController alloc] initWithViewModel:viewModel];
    [self.responder.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Private

- (void)fetchDataWithOption:(NCUIPagingQueryOption *)option {
    self.option = option;
    [self performOperationQueueBlock:^{
        [NCGroupManager getJoinedGroupInfosByRole:NCGroupMemberRoleUndef option:option complete:^(NCUIPagingQueryResult<NCGroupInfo *> * _Nullable result) {
            if (!result) {
                [self refreshingFinished:NO
                                withTips:NCUILocalizedString(@"group_list_failed")];
                return;
            }
            if (result.pageToken.length != 0) {
                self.option.pageToken = result.pageToken;
            }
            NSArray *infos = result.data;
            NSMutableArray *array = [NSMutableArray array];
            NSArray *items = @[];
            if (infos.count) {
                for (NCGroupInfo *info in infos) {
                    NCGroupInfoCellViewModel *vm = [[NCGroupInfoCellViewModel alloc] initWithGroupInfo:info keyword:@""];
                    [array addObject:vm];
                }
                items = array;
                if ([self.delegate respondsToSelector:@selector(myGroupsViewModel:willLoadItemsInDataSource:)]) {
                    items = [self.delegate myGroupsViewModel:self willLoadItemsInDataSource:array];
                }
            }
            [self removeSeparatorWithArray:items];
            [self.dataSource addObjectsFromArray:items];
            [self reloadData:self.dataSource.count == 0];
            [self refreshingFinished:YES withTips:nil];
        }];
    }];
  
}

- (void)removeSeparatorWithArray:(NSArray *)array {
    if (array.count) {
        [self removeSeparatorLineIfNeed:@[array]];
        if ([self.lastBottomCellVM isKindOfClass:[NCBaseCellViewModel class]]) { // Last cell from the previous page.
            self.lastBottomCellVM.hideSeparatorLine = NO; // Restore the previous last cell's separator when loading more.
        }
        self.lastBottomCellVM = array.lastObject;
    }
}
- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(NCMyGroupsOperationQueueSpecificKey)) {
        block();
    }
    else {
        dispatch_async(self.queue, block);
    }
}


- (void)reloadData:(BOOL)showEmpty {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder reloadData:showEmpty];
        });
    }
}

- (void)showTips:(NSString *)tips {
    if ([self.responder respondsToSelector:@selector(showTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder showTips:tips];
        });
    }
}

- (void)refreshingFinished:(BOOL)success withTips:(NSString *)tips {
    if ([self.responder respondsToSelector:@selector(refreshingFinished:withTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder refreshingFinished:success withTips:tips];
        });
    }
}
#pragma mark - Setter
- (void)setOption:(NCUIPagingQueryOption *)option {
    if (_option != option) {
        _option = option;
    }
}

@end
