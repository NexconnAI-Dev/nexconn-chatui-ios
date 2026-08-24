//
//  NCGroupNotificationViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupNotificationViewModel.h"
#import "NCChatUICommonDefine.h"
#import "NCGroupNotificationCellViewModel.h"
#import "NCGroupNotificationNaviItemsViewModel.h"

NSInteger const NCGroupNotificationMaxCount = 50;

static void *NCGroupNotificationOperationQueueSpecificKey =
    &NCGroupNotificationOperationQueueSpecificKey;

@interface NCGroupNotificationViewModel () <NCGroupNotificationNaviItemsViewModelDelegate>
@property (nonatomic, strong) NCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, weak) UIViewController<NCListViewModelResponder> *responder;

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NSArray<NSNumber *> *types;
@property (nonatomic, strong) NSArray<NSNumber *> *status;
@property (nonatomic, strong) NCGroupApplicationsQuery *query;
@end

@implementation NCGroupNotificationViewModel
@dynamic delegate;

#pragma mark - Public

- (instancetype)initWithOption:(nullable NCGroupApplicationsQueryParams *)option
                         types:(nullable NSArray<NSNumber *> *)types
                        status:(nullable NSArray<NSNumber *> *)status {
    self = [super init];
    if (self) {
        [self ready];
        self.option = option;
        self.status = status;
        self.types = types;
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
    self.dataSource = [NSMutableArray array];
    self.queue =
        dispatch_queue_create("ai.nexconn.groupNotification.operationQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(self.queue, NCGroupNotificationOperationQueueSpecificKey,
                                NCGroupNotificationOperationQueueSpecificKey, NULL);
}

/// Configures navigation.
- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate
            respondsToSelector:
                @selector(willConfigureRightNavigationItemsForGroupNotificationViewModel:)]) {
        self.naviItemsVM =
            [self.delegate willConfigureRightNavigationItemsForGroupNotificationViewModel:self];
    } else if (!self.naviItemsVM) {
        NCGroupNotificationNaviItemsViewModel *vm =
            [[NCGroupNotificationNaviItemsViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.naviItemsVM = vm;
    }
    return [self.naviItemsVM rightNavigationBarItems];
}

/// Loads data.
- (void)fetchData {
    if (self.types.count == 0) {
        self.types = [self applicationDirectionByCategory:NCGroupNotificationCategoryAll];
    }
    if (self.status.count == 0) {
        self.status = [self applicationStatusByCategory:NCGroupNotificationCategoryAll];
    }
    if (!self.option) {
        NCGroupApplicationsQueryParams *opt = [[NCGroupApplicationsQueryParams alloc] init];
        opt.pageSize = NCGroupNotificationMaxCount;
        self.option = opt;
    }
    self.option.directions = self.types ?: @[];
    self.option.status = self.status ?: @[];
    self.query = [NCGroupChannel createGroupApplicationsQueryWithParams:self.option];
    [self.dataSource removeAllObjects];
    [self fetchDataWithOption:self.option types:self.types status:self.status];
}

- (void)fetchDataWithOption:(NCGroupApplicationsQueryParams *)option
                      types:(nonnull NSArray<NSNumber *> *)types
                     status:(nonnull NSArray<NSNumber *> *)status {
    self.types = types;
    self.status = status;
    self.option = option;

    [self performOperationQueueBlock:^{
      self.option.directions = types ?: @[];
      self.option.status = status ?: @[];
      if (!self.query) {
          self.query = [NCGroupChannel createGroupApplicationsQueryWithParams:self.option];
      }
      [self.query loadNextPageWithCompletion:^(NCGroupApplicationsPageResult *_Nullable page,
                                               NCError *_Nullable error) {
        if (error) {
            [self refreshingFinished:NO withTips:NCUILocalizedString(@"group_notification_failed")];
            return;
        }
        NSArray *infos = page.data;
        NSMutableArray *array = [NSMutableArray array];
        NSArray *items = @[];
        if (infos.count) {
            for (NCGroupApplicationInfo *info in infos) {
                NCGroupNotificationCellViewModel *vm =
                    [[NCGroupNotificationCellViewModel alloc] initWithApplicationInfo:info];
                [vm bindResponder:self.responder];
                [array addObject:vm];
            }
            items = array;
            if ([self.delegate respondsToSelector:@selector(groupNotificationViewModel:
                                                            willLoadItemsInDataSource:)]) {
                items = [self.delegate groupNotificationViewModel:self
                                        willLoadItemsInDataSource:array];
            }
        }
        if (items) {
            [self removeSeparatorLineIfNeed:@[ items ]];
        }
        [self.dataSource addObjectsFromArray:items];
        [self reloadData:self.dataSource.count == 0];
        [self refreshingFinished:YES withTips:nil];
      }];
    }];
}

- (void)bindResponder:(UIViewController<NCListViewModelResponder> *)responder {
    self.responder = responder;
}

/// Returns the cell height.
/// - Parameters:
///   - tableView: tableView
///   - indexPath: indexPath
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCGroupNotificationCellViewModel *vm = [self.dataSource objectAtIndex:indexPath.row];
    return [vm tableView:tableView heightForRowAtIndexPath:indexPath];
}

/// Loads the next page.
- (void)loadMoreData {
    [self fetchDataWithOption:self.option types:self.types status:self.status];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCGroupNotificationCellViewModel *vm = [self.dataSource objectAtIndex:indexPath.row];
    return [vm tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    NCGroupNotificationCellViewModel *vm = [self.dataSource objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(groupNotificationViewModel:viewController:
                                                    tableView:didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate groupNotificationViewModel:self
                                              viewController:viewController
                                                   tableView:tableView
                                                didSelectRow:indexPath
                                               cellViewModel:vm];
        if (ret) {
            return;
        }
    }
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [NCGroupNotificationCellViewModel registerCellForTableView:tableView];
}

- (NSInteger)numberOfSections {
    return 1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}
#pragma mark - Private
- (NSArray *)applicationDirectionByCategory:(NCGroupNotificationCategory)category {
    NSArray *array = @[
        @(NCGroupApplicationDirectionInvitationReceived),
        @(NCGroupApplicationDirectionApplicationReceived),
        @(NCGroupApplicationDirectionApplicationSent), @(NCGroupApplicationDirectionInvitationSent)
    ];
    return array;
}

- (NSArray *)applicationStatusByCategory:(NCGroupNotificationCategory)category {
    NSArray *array = @[];
    switch (category) {
    case NCGroupNotificationCategoryToBeConfirmed:
        array = @[
            @(NCGroupApplicationStatusInviteeUnhandled), @(NCGroupApplicationStatusAdminUnhandled)
        ];
        break;
    case NCGroupNotificationCategoryDealt:
        array = @[
            @(NCGroupApplicationStatusJoined), @(NCGroupApplicationStatusInviteeRefused),
            @(NCGroupApplicationStatusAdminRefused)
        ];
        break;
    case NCGroupNotificationCategoryExpired:
        array = @[ @(NCGroupApplicationStatusExpired) ];
        break;
    default:
        array = @[
            @(NCGroupApplicationStatusAdminUnhandled), @(NCGroupApplicationStatusAdminRefused),
            @(NCGroupApplicationStatusInviteeUnhandled), @(NCGroupApplicationStatusInviteeRefused),
            @(NCGroupApplicationStatusJoined), @(NCGroupApplicationStatusExpired)
        ];
        break;
    }
    return array;
}

#pragma mark - NCApplyNaviItemsViewModelDelegate

/// Applies the category selected by the user.
- (void)userDidSelectCategory:(NCGroupNotificationCategory)category {
    NSArray *types = [self applicationDirectionByCategory:category];
    NSArray *status = [self applicationStatusByCategory:category];
    self.query = nil;
    [self.dataSource removeAllObjects];
    [self reloadData:NO];
    [self fetchDataWithOption:self.option types:types status:status];
}

#pragma mark - Private
- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(NCGroupNotificationOperationQueueSpecificKey)) {
        block();
    } else {
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
- (void)setOption:(NCGroupApplicationsQueryParams *)option {
    if (_option != option) {
        _option = option;
    }
}

- (void)setTypes:(NSArray<NSNumber *> *)types {
    if (_types != types) {
        _types = types;
    }
}

- (void)setStatus:(NSArray<NSNumber *> *)status {
    if (_status != status) {
        _status = status;
    }
}
@end
