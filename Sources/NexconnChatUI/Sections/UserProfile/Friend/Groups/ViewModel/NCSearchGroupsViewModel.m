//
//  NCSearchGroupsViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSearchGroupsViewModel.h"
#import "NCChatUICommonDefine.h"
#import "NCGroupInfoCellViewModel.h"
#import "NCGroupManager.h"

NSInteger const NCSearchGroupInfoMaxCount = 50;

static void *NCSearchGroupsOperationQueueSpecificKey = &NCSearchGroupsOperationQueueSpecificKey;

@interface NCSearchGroupsViewModel () <NCSearchBarViewModelDelegate>
@property (nonatomic, strong) NCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, strong) NCSearchBarViewModel *searchBarVM;
// All cells.
@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, weak) UIViewController<NCListViewModelResponder> *responder;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) NCUIPagingQueryOption *option;
@property (nonatomic, copy) NSString *keyword;
@property (nonatomic, assign) NSUInteger searchRequestId;
@end

@implementation NCSearchGroupsViewModel
@dynamic delegate;

- (instancetype)initWithOption:(nullable NCUIPagingQueryOption *)option {
    self = [super init];
    if (self) {
        [self ready];
        self.option = option;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self ready];
    }
    return self;
}

- (void)ready {
    self.queue =
        dispatch_queue_create("ai.nexconn.searchGroups.operationQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(self.queue, NCSearchGroupsOperationQueueSpecificKey,
                                NCSearchGroupsOperationQueueSpecificKey, NULL);
    self.dataSource = [NSMutableArray array];
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [NCGroupInfoCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    id<NCCellViewModelProtocol> vm = [self cellViewModelAtIndexPath:indexPath];
    if (!vm) {
        [self reloadData:NO];
        return;
    }
    if ([vm isKindOfClass:[NCGroupInfoCellViewModel class]]) {
        NCGroupInfo *groupInfo = ((NCGroupInfoCellViewModel *)vm).groupInfo;
        if (groupInfo.groupId.length == 0) {
            return;
        }
    }
    if ([self.delegate respondsToSelector:@selector(searchGroupsViewModel:viewController:tableView:
                                                    didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate searchGroupsViewModel:self
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

- (NSInteger)numberOfSections {
    return 1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    if (section != 0) {
        return 0;
    }
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<NCCellViewModelProtocol> vm = [self cellViewModelAtIndexPath:indexPath];
    if (!vm) {
        [self reloadData:NO];
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:nil];
    }
    UITableViewCell *cell = [vm tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell;
}

#pragma mark - SearchBar
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText isEqualToString:self.keyword]) {
        return;
    }
    self.option.pageToken = nil;
    self.keyword = searchText;
    if (searchText.length == 0) {
        [self restoreData];
    } else {
        [self.dataSource removeAllObjects];
        [self reloadData:NO];
        [self fetchDataWithKeyword:searchText];
    }
}
- (void)setKeyword:(NSString *)keyword {
    if (![_keyword isEqualToString:keyword]) {
        _keyword = keyword;
    }
}

- (void)searchBar:(UISearchBar *)searchBar editingStateChanged:(BOOL)inSearching {
    if (inSearching && searchBar.text.length > 0) {
        BOOL empty = self.dataSource.count == 0;
        [self reloadData:empty];
    } else {
        [self restoreData];
    }
}

#pragma mark - Public

- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    if ([self.delegate
            respondsToSelector:@selector(
                                   willConfigureSearchBarViewModelForSearchGroupsViewModel:)]) {
        NCSearchBarViewModel *searchBarVM =
            [self.delegate willConfigureSearchBarViewModelForSearchGroupsViewModel:self];
        searchBarVM.delegate = self;
        self.searchBarVM = searchBarVM;
    } else if (!self.searchBarVM) {
        NCSearchBarViewModel *vm = [[NCSearchBarViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate
            respondsToSelector:@selector(
                                   willConfigureRightNavigationItemsForSearchGroupsViewModel:)]) {
        self.naviItemsVM =
            [self.delegate willConfigureRightNavigationItemsForSearchGroupsViewModel:self];
    }
    return [self.naviItemsVM rightNavigationBarItems];
}

- (void)endEditingState {
    [self.searchBarVM endEditingState];
    [self restoreData];
}

- (void)fetchDataWithKeyword:(NSString *)keyword {
    if (keyword == nil) {
        [self refreshingFinished:YES withTips:nil];
        return;
    }
    if (self.option == nil) {
        self.option = [NCUIPagingQueryOption new];
        self.option.count = NCSearchGroupInfoMaxCount;
    }
    NSUInteger requestId = [self beginSearchWithKeyword:keyword];
    [self performOperationQueueBlock:^{
      NCUIPagingQueryOption *requestOption = self.option;
      [NCGroupManager
          searchJoinedGroupInfos:keyword
                          option:requestOption
                        complete:^(NCUIPagingQueryResult<NCGroupInfo *> *_Nullable result) {
                          if (![self isCurrentSearchWithKeyword:keyword requestId:requestId]) {
                              return;
                          }
                          if (!result) {
                              [self refreshingFinished:YES
                                              withTips:NCUILocalizedString(@"group_list_failed")];
                              return;
                          }
                          if (result.pageToken.length != 0) {
                              requestOption.pageToken = result.pageToken;
                          }
                          NSArray *infos = result.data;
                          NSMutableArray *array = [NSMutableArray array];
                          NSArray *items = @[];
                          if (infos.count) {
                              for (NCGroupInfo *info in infos) {
                                  NCGroupInfoCellViewModel *vm =
                                      [[NCGroupInfoCellViewModel alloc] initWithGroupInfo:info
                                                                                  keyword:keyword];
                                  [array addObject:vm];
                              }
                              items = array;
                              if ([self.delegate
                                      respondsToSelector:@selector(searchGroupsViewModel:
                                                                   willLoadItemsInDataSource:)]) {
                                  items = [self.delegate searchGroupsViewModel:self
                                                     willLoadItemsInDataSource:array];
                              }
                          }
                          if (items) {
                              [self removeSeparatorLineIfNeed:@[ items ]];
                          }
                          dispatch_async(dispatch_get_main_queue(), ^{
                            if (![self isCurrentSearchWithKeyword:keyword requestId:requestId]) {
                                return;
                            }
                            [self.dataSource addObjectsFromArray:items];
                            [self reloadData:self.dataSource.count == 0];
                          });

                          [self refreshingFinished:YES withTips:nil];
                        }];
    }];
}

- (void)bindResponder:(UIViewController<NCListViewModelResponder> *)responder {
    self.responder = responder;
}

- (void)loadMoreData {
    [self fetchDataWithKeyword:self.keyword];
}
#pragma mark - Private

- (id<NCCellViewModelProtocol>)cellViewModelAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 0 || indexPath.row < 0 || indexPath.row >= self.dataSource.count) {
        return nil;
    }
    id vm = self.dataSource[indexPath.row];
    if (![vm conformsToProtocol:@protocol(NCCellViewModelProtocol)]) {
        return nil;
    }
    return vm;
}

- (NSUInteger)beginSearchWithKeyword:(NSString *)keyword {
    @synchronized(self) {
        self.keyword = [keyword copy];
        self.searchRequestId += 1;
        return self.searchRequestId;
    }
}

- (void)invalidateSearch {
    @synchronized(self) {
        self.keyword = nil;
        self.searchRequestId += 1;
    }
}

- (BOOL)isCurrentSearchWithKeyword:(NSString *)keyword requestId:(NSUInteger)requestId {
    @synchronized(self) {
        return self.searchRequestId == requestId && [self.keyword isEqualToString:keyword];
    }
}

- (void)restoreData {
    [self invalidateSearch];
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.option) {
          self.option.pageToken = nil;
      }
      [self.dataSource removeAllObjects];
      // Ask the view controller to reload the list.
      [self reloadData:NO];
    });
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

- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(NCSearchGroupsOperationQueueSpecificKey)) {
        block();
    } else {
        dispatch_async(self.queue, block);
    }
}
@end
