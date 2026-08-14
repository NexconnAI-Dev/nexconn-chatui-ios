//
//  NCFriendListViewModel.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFriendListViewModel.h"
#import "NCUPinYinTools.h"
#import "NCChatUICommonDefine.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCApplyFriendListViewController.h"
#import "NCSearchFriendsViewController.h"
#import "NCUserOnlineStatusManager.h"
#import "NCUserOnlineStatusUtil.h"
#import "NCChatUI.h"
#import "NCChatUIErrorCode.h"

static void *NCFriendListOperationQueueSpecificKey = &NCFriendListOperationQueueSpecificKey;

@interface NCFriendListViewModel()<NCSearchBarViewModelDelegate>
@property (nonatomic, strong) NCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, strong) NCSearchBarViewModel *searchBarVM;
// All cells.
@property (nonatomic, strong) NSArray *dataSource;
// Section index titles.
@property (nonatomic, strong) NSArray *indexTitles;
// Cells grouped by index title.
@property (nonatomic, strong) NSDictionary *dicInfo;
// Persistent cells.
@property (nonatomic, strong) NSArray *permanentViewModels;
// Search result cells.
@property (nonatomic, strong) NSArray *matchFriendList;

// userID:cellviewmodel
@property (nonatomic, strong) NSMutableDictionary *userIDToCellViewModelMap;

@property (nonatomic, weak) UIViewController <NCListViewModelResponder> *responder;

@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation NCFriendListViewModel
@dynamic delegate;


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.queue = dispatch_queue_create("ai.nexconn.friendList.operationQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(self.queue, NCFriendListOperationQueueSpecificKey, NCFriendListOperationQueueSpecificKey, NULL);
        self.userIDToCellViewModelMap = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserOnlineStatusChanged:) name:NCChatUIUserOnlineStatusChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [NCFriendListPermanentCellViewModel registerCellForTableView:tableView];
    [NCFriendListCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
  
    id<NCCellViewModelProtocol> vm = nil;
    
    // Normal mode.
    if (indexPath.section != 0) {
        NSString *key = [self.indexTitles objectAtIndex:indexPath.section-1];
        NSArray *array = [self.dicInfo objectForKey:key];
        vm = [array objectAtIndex:indexPath.row];
    } else {
        vm = [self.permanentViewModels objectAtIndex:indexPath.row];
    }
    if ([self.delegate respondsToSelector:@selector(friendListViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate friendListViewModel:self
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
    NSInteger count = self.indexTitles.count;
    return count+1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    // Normal mode.
    if (section == 0) {
        return self.permanentViewModels.count;
    } else {
        NSString *key = [self.indexTitles objectAtIndex:section-1];
        NSArray *array = [self.dicInfo objectForKey:key];
        return array.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    id<NCCellViewModelProtocol> vm = nil;
    // Normal mode.
    if (indexPath.section != 0) {
        NSString *key = [self.indexTitles objectAtIndex:indexPath.section-1];
        NSArray *array = [self.dicInfo objectForKey:key];
        vm = [array objectAtIndex:indexPath.row];
    } else {
        vm = [self.permanentViewModels objectAtIndex:indexPath.row];
    }
    cell = [vm tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section {
    // Hide the first section outside search mode.
    if (section == 0 ) {
        return CGFLOAT_MIN;
    }
    return 32;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 32)];
    view.backgroundColor = [UIColor clearColor];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.font = [UIFont systemFontOfSize:14.f];
    title.textColor = NCDynamicColor(@"text_primary_color");
    [view addSubview:title];
    
    NSString *text = nil;
    if (section != 0) {
        text = self.indexTitles[section-1];
    }
    title.text = text;
    title.textAlignment = NSTextAlignmentNatural;
    [title sizeToFit];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [title.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:16],
        [title.centerYAnchor constraintEqualToAnchor:view.centerYAnchor]
    ]];
    return view;
}

#pragma mark - SearchBar
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self showSearchFriends];
    return NO;
}

- (void)showSearchFriends {
    NCSearchFriendsViewModel *viewModel = [[NCSearchFriendsViewModel alloc] init];
    NCSearchFriendsViewController *vc = [[NCSearchFriendsViewController alloc] initWithViewModel:viewModel];
    [self.responder.navigationController pushViewController:vc animated:YES];
}
#pragma mark - Public

- (NSArray *)sectionIndexTitles {
    return self.indexTitles;
}

- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureSearchBarViewModelForFriendListViewModel:)]) {
        self.searchBarVM = [self.delegate willConfigureSearchBarViewModelForFriendListViewModel:self];
    } else if(!self.searchBarVM) {
        NCSearchBarViewModel *vm = [[NCSearchBarViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForFriendListViewModel:)]) {
        self.naviItemsVM = [self.delegate willConfigureRightNavigationItemsForFriendListViewModel:self];
    } else if(!self.naviItemsVM) {
        NCNavigationItemsViewModel *vm = [[NCNavigationItemsViewModel alloc] initWithResponder:viewController];
        self.naviItemsVM = vm;
    }

    return [self.naviItemsVM rightNavigationBarItems];
}


- (void)fetchData {
    NSMutableArray *permanents = [NSMutableArray array];    
    // Notify the consumer after adding persistent cell data.
    if ([self.delegate respondsToSelector:@selector(appendPermanentCellViewModelsForFriendListViewModel:)]) {
        NSArray *vms = [self.delegate appendPermanentCellViewModelsForFriendListViewModel:self];
        if (vms.count) {
            [permanents addObjectsFromArray:vms];
        }
    }
    if (permanents) {
        [self removeSeparatorLineIfNeed:@[permanents]];
    }
    self.permanentViewModels = permanents;
    
    [[NCEngine userModule] getFriendsWithCompletion:^(NSArray<NCFriendInfo *> * _Nullable friendInfos, NCError * _Nullable error) {
        if (error) {
            [self showErrorByCode:(NCChatUIErrorCode)error.code];
            [self reloadData];
            return;
        }
        [self configureDataSourceWithArray:friendInfos];
    }];
}

- (BOOL)isDisplayOnlineStatus:(NCFriendListCellViewModel *)viewModel {
    if (![NCUserOnlineStatusUtil shouldDisplayOnlineStatus]) {
        return NO;
    }
    NSString *currentUserId = [NCEngine getCurrentUserId];
    if ([currentUserId isEqualToString:viewModel.friendInfo.userId]) {
        return NO;
    }
    return YES;
}

- (void)configureDataSourceWithArray:(NSArray<NCFriendInfo *> *)friendInfos {
    [self performOperationQueueBlock:^{
            NSArray *array = nil;
            NSMutableArray *tmp = [NSMutableArray array];
            NSMutableArray *needFetchOnlineStatusUserIds = [NSMutableArray array];
            for (NCFriendInfo *friend in friendInfos) {
                NCFriendListCellViewModel *vm = [[NCFriendListCellViewModel alloc] initWithFriend:friend];
                
                if (friend.userId.length > 0 && [self isDisplayOnlineStatus:vm]) {
                    NCSubscribeUserOnlineStatus *onlineStatus = [NCUserOnlineStatusManager.sharedManager getCachedOnlineStatus:friend.userId];
                    vm.displayOnlineStatus = YES;
                    vm.onlineStatus = onlineStatus;
                    if (!onlineStatus) {
                        [needFetchOnlineStatusUserIds addObject:friend.userId];
                    }
                }
                [tmp addObject:vm];
                if (friend.userId.length > 0) {
                    [self.userIDToCellViewModelMap setObject:vm forKey:friend.userId];
                }
            }
            array = tmp;
            if (needFetchOnlineStatusUserIds.count > 0) {
                [NCUserOnlineStatusManager.sharedManager fetchFriendOnlineStatus:needFetchOnlineStatusUserIds];
            }
            // Notify the consumer that the data source changed.
        if ([self.delegate respondsToSelector:@selector(friendListViewModel:willLoadItemsInDataSource:)]) {
                array = [self.delegate friendListViewModel:self
                                 willLoadItemsInDataSource:tmp];
            }
            [self groupAndReloadItemsInArray:array];
    }];
}

- (void)bindResponder:(UIViewController <NCListViewModelResponder>*)responder {
    self.responder = responder;
}

- (void)onUserOnlineStatusChanged:(NSNotification *)notification {
    NSArray<NSString *> *changedUserIds = notification.userInfo[NCChatUIUserOnlineStatusChangedUserIdsKey];
    for (NSString *userId in changedUserIds) {
        NCFriendListCellViewModel *vm = [self.userIDToCellViewModelMap objectForKey:userId];
        if (![self isDisplayOnlineStatus:vm]) {
            continue;
        }
        // Match friend IDs.
        if ([vm.friendInfo.userId isEqualToString:userId]) {
            NCSubscribeUserOnlineStatus *onlineStatus = [NCUserOnlineStatusManager.sharedManager getCachedOnlineStatus:userId];
            [vm refreshOnlineStatus:onlineStatus];
        }
    }
}

#pragma mark - Private

- (void)groupAndReloadItemsInArray:(NSArray *)array {
    [self performOperationQueueBlock:^{
        // Group the data source.
        NSDictionary *dicInfo = [NCUPinYinTools sortedWithPinYinArray:array
                                                  usingBlock:^NSString * _Nonnull(NCFriendListCellViewModel * obj, NSUInteger idx) {
            return obj.friendInfo.remark.length > 0 ? obj.friendInfo.remark : obj.friendInfo.name;
        }];
        // Sort section index titles.
        NSArray *indexTitles = [[dicInfo allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ([obj1 isKindOfClass:[NSString class]]&&[obj2 isKindOfClass:[NSString class]]) {
                NSString *key1 = (NSString *)obj1;
                NSString *key2 = (NSString *)obj2;
                if ([key1 isEqualToString:@"#"]) {
                    if ([key2 isEqualToString:@"#"]) {
                        return NSOrderedSame;
                    }
                    return NSOrderedDescending;
                } else if ([key2 isEqualToString:@"#"]) {
                    return NSOrderedAscending;
                }
            }
            return [obj1 compare:obj2 options:NSNumericSearch];
        }];
        [self removeSeparatorLineIfNeed:[dicInfo allValues]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSource = array;
            // Switch data sources on the main thread to avoid concurrent mutation.
            self.dicInfo = dicInfo;
            self.indexTitles = indexTitles;
            // Ask the view controller to reload the list.
            [self reloadData];
        });
    }];
}

- (void)reloadData {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL empty = (self.dataSource.count == 0) && (self.permanentViewModels.count == 0);
            [self.responder reloadData:empty];
        });
    }
}

- (void)showErrorByCode:(NCChatUIErrorCode)code {
    (void)code;
    if ([self.responder respondsToSelector:@selector(showTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder showTips:NCUILocalizedString(@"friend_list_failed")];
        });
    }
}

- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(NCFriendListOperationQueueSpecificKey)) {
        block();
    }
    else {
        dispatch_async(self.queue, block);
    }
}
@end
