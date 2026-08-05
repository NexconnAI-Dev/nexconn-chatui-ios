//
//  NCApplyFriendListViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCApplyFriendListViewModel.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIErrorCode.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCApplyNaviItemsViewModel.h"

@interface NCApplyFriendSectionItem()
- (id)itemAtIndex:(NSInteger)index;
- (void)removeItemAtIndex:(NSInteger)index;
- (NSInteger)countOfItems;
- (void)clean;

- (void)appendItems:(NSArray *)items;
@end

NSInteger const NCFriendApplyListMaxCount = 100;

static void *NCApplyFriendListOperationQueueSpecificKey = &NCApplyFriendListOperationQueueSpecificKey;

@interface NCApplyFriendListViewModel()<NCApplyNaviItemsViewModelDelegate>
@property (nonatomic, strong) NCNavigationItemsViewModel *naviItemsVM;
// All cells.
@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, strong)NSArray <NCApplyFriendSectionItem *>* sectionItems;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, weak) UIViewController <NCListViewModelResponder> *responder;
@property (nonatomic, strong) NCFriendApplicationsQueryParams *option;
@property (nonatomic, strong) NSArray<NSNumber *> *types;
@property (nonatomic, strong) NSArray<NSNumber *> *status;
@property (nonatomic, weak) NCBaseCellViewModel *lastBottomCellVM;
@property (nonatomic, strong) NCFriendApplicationsQuery *query;

@end

@implementation NCApplyFriendListViewModel
@dynamic delegate;

- (instancetype)initWithSectionItems:(nullable NSArray <NCApplyFriendSectionItem *>*)items
                              option:(nullable NCFriendApplicationsQueryParams *)option
                               types:(nullable NSArray<NSNumber *> *)types
                              status:(nullable NSArray<NSNumber *> *)status
{
    self = [super init];
    if (self) {
        [self ready];
        self.sectionItems = items;
        self.option = option;
        self.status = status;
        self.types = types;
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
    self.queue = dispatch_queue_create("ai.nexconn.applyFriendList.operationQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(self.queue, NCApplyFriendListOperationQueueSpecificKey, NCApplyFriendListOperationQueueSpecificKey, NULL);
}

- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForApplyFriendListViewModel:)]) {
        self.naviItemsVM = [self.delegate willConfigureRightNavigationItemsForApplyFriendListViewModel:self];
    } else if(!self.naviItemsVM) {
        NCApplyNaviItemsViewModel *vm = [[NCApplyNaviItemsViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.naviItemsVM = vm;
    }
    return [self.naviItemsVM rightNavigationBarItems];
}

- (void)fetchData {
    if (self.types.count == 0) {
        self.types = @[@(NCFriendApplicationTypeSent),
                        @(NCFriendApplicationTypeReceived)];
    }
    if (self.status.count == 0) {
        self.status = @[@(NCFriendApplicationStatusUnHandled),
                       @(NCFriendApplicationStatusAccepted),
                       @(NCFriendApplicationStatusRefused),
                       @(NCFriendApplicationStatusExpired)];
    }
    if (!self.option) {
        NCFriendApplicationsQueryParams *opt = [[NCFriendApplicationsQueryParams alloc] init];
        opt.pageSize = NCFriendApplyListMaxCount;
        self.option = opt;
    }
    [self.dataSource removeAllObjects];
    for (NCApplyFriendSectionItem *item in self.sectionItems) {
        [item clean];
    }
    self.option.applicationTypes = self.types ?: @[];
    self.option.applicationStatuses = self.status ?: @[];
    self.query = [NCUserModule createFriendApplicationsQueryWithParams:self.option];
    [self reloadData:NO];
    [self fetchDataWithOption:self.option types:self.types status:self.status];
}

- (void)fetchDataWithOption:(NCFriendApplicationsQueryParams *)option
                      types:(nonnull NSArray<NSNumber *> *)types
                     status:(nonnull NSArray<NSNumber *> *)status {
    [self performOperationQueueBlock:^{
        self.option = option;
        self.option.applicationTypes = types ?: @[];
        self.option.applicationStatuses = status ?: @[];
        if (!self.query) {
            self.query = [NCUserModule createFriendApplicationsQueryWithParams:self.option];
        }
        [self.query loadNextPageWithCompletion:^(NSArray<NCFriendApplicationInfo *> * _Nullable infos, NCError * _Nullable error) {
            if (error) {
                [self refreshingFinished:NO withTips:NCUILocalizedString(@"friend_application_failed")];
                return;
            }
            NSMutableArray *array = [NSMutableArray array];
            NSArray *items = @[];
            if (infos.count) {
                for (NCFriendApplicationInfo *info in infos) {
                    NCApplyFriendCellViewModel *vm = [[NCApplyFriendCellViewModel alloc] initWithApplicationInfo:info];
                    [vm bindResponder:self.responder];
                    [array addObject:vm];
                }
                items = array;
                if ([self.delegate respondsToSelector:@selector(applyFriendListViewModel:willLoadItemsInDataSource:)]) {
                    items = [self.delegate applyFriendListViewModel:self willLoadItemsInDataSource:array];
                }
            }
            [self.dataSource addObjectsFromArray:items];
            [self groupApplications:items];
            [self refreshingFinished:YES withTips:nil];
        }];
    }];
}

- (void)bindResponder:(UIViewController <NCListViewModelResponder>*)responder {
    self.responder = responder;
    for (NCApplyFriendCellViewModel *vm in self.dataSource) {
        [vm bindResponder:self.responder];
    }
}

- (void)loadMoreData {
    [self fetchDataWithOption:self.option types:self.types status:self.status];
}

#pragma mark - Private

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
    if (dispatch_get_specific(NCApplyFriendListOperationQueueSpecificKey)) {
        block();
    }
    else {
        dispatch_async(self.queue, block);
    }
}

- (void)groupApplications:(NSArray <NCApplyFriendCellViewModel *>*)infos {
    if (self.sectionItems.count == 0) {
        NCApplyFriendSectionItem *item = [[NCApplyFriendSectionItem alloc] initWithFilterBlock:nil compareBlock:nil];
        item.timeEnd = [[NSDate date] timeIntervalSince1970] * 1000;
        item.title = @"";
        self.sectionItems = @[item];
    }
    [self groupApplications:infos withSectionItems:self.sectionItems];
}

- (void)groupApplications:(NSArray <NCApplyFriendCellViewModel *>*)infos
         withSectionItems:(NSArray <NCApplyFriendSectionItem *>*)items {
    NSInteger count = self.sectionItems.count;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    for (int i=0 ; i<count; i++) {
        NCApplyFriendSectionItem *item = self.sectionItems[i];
        NSArray *ret = [item filterAndSortItems:infos];
        if (!ret) {
            ret = @[];
        }
        [array addObject:ret];
    }
    // Mutate the data source on the main thread to keep it synchronized with UI updates.
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int i=0 ; i<count; i++) {
            NCApplyFriendSectionItem *item = self.sectionItems[i];
            NSArray *tmp = array[i];
            [self removeSeparatorWithArray:tmp];
            [item appendItems:tmp];
        }
        [self reloadData:self.dataSource.count == 0];
    });
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
#pragma mark - Protocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [NCApplyFriendCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    NCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:indexPath.section];
    NCApplyFriendCellViewModel *vm = [item itemAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(applyFriendListViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate applyFriendListViewModel:self
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
    return self.sectionItems.count;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    NCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:section];
    return [item countOfItems];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:indexPath.section];
    NCApplyFriendCellViewModel *vm = [item itemAtIndex:indexPath.row];
    return [vm tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section {
    NCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:section];
    if (![item isValidSectionItem]) {
        return 0.01;
    }
    return 34;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:section];
    if (![item isValidSectionItem] || item.title.length == 0) {
        return nil;
    }
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.frame = CGRectMake(0, 0, tableView.frame.size.width, 32);
    view.backgroundColor = NCDynamicColor(@"clear_color");
    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectZero];
    lab.font = [UIFont systemFontOfSize:14.f];
    lab.textColor = NCDynamicColor(@"text_primary_color");
    lab.text = item.title;
    [view addSubview:lab];

    [lab sizeToFit];
    lab.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [lab.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:16],
        [lab.centerYAnchor constraintEqualToAnchor:view.centerYAnchor]
    ]];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:indexPath.section];
    NCApplyFriendCellViewModel *vm = [item itemAtIndex:indexPath.row];
    return [vm cellHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:section];
    if (![item isValidSectionItem] || item.title.length == 0) {
        return 0;
    }
    return 34;
}

- (void)removeItem:(NCApplyFriendSectionItem *)item 
         tableView:(UITableView *)tableView
       atIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath || !item) {
        return;
    }
    [self performOperationQueueBlock:^{
        [item removeItemAtIndex:indexPath.row];
        dispatch_async(dispatch_get_main_queue(), ^{
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        });
    }];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCApplyFriendSectionItem *item = [self.sectionItems objectAtIndex:indexPath.section];
    NCApplyFriendCellViewModel *vm = [item itemAtIndex:indexPath.row]; 
    NSArray *array = [vm tableView:tableView editActionsForRowAtIndexPath:indexPath completion:^(NSInteger errorCode) {
        if (errorCode == NCChatUIErrorCodeSuccess) {
            [self removeItem:item tableView:tableView atIndexPath:indexPath];
        } else {
            [self showTips:NCUILocalizedString(@"friend_application_delete_failed")];
        }
    }];
    return array;
}


#pragma mark - NCApplyNaviItemsViewModelDelegate
- (void)userDidSelectCategory:(NCApplicationCategory)category {
    switch (category) {
        case NCApplicationCategoryReceived:
            self.types = @[@(NCFriendApplicationTypeReceived)];
            break;
        case NCApplicationCategorySent:
            self.types = @[@(NCFriendApplicationTypeSent)];
            break;
        default:
            self.types = @[@(NCFriendApplicationTypeSent),
                            @(NCFriendApplicationTypeReceived)];
            break;
    }
    [self fetchData];
}
@end
