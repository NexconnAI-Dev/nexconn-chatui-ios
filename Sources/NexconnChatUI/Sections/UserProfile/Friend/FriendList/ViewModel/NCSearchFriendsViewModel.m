//
//  NCSearchFriendsViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSearchFriendsViewModel.h"
#import "NCUPinYinTools.h"
#import "NCChatUICommonDefine.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCApplyFriendListViewController.h"

static void *NCSearchFriendsOperationQueueSpecificKey = &NCSearchFriendsOperationQueueSpecificKey;

@interface NCSearchFriendsViewModel()<NCSearchBarViewModelDelegate>
@property (nonatomic, strong) NCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, strong) NCSearchBarViewModel *searchBarVM;
// All cells.
@property (nonatomic, strong) NSArray *dataSource;

@property (nonatomic, weak) id<NCListViewModelResponder> responder;

@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation NCSearchFriendsViewModel
@dynamic delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.queue = dispatch_queue_create("ai.nexconn.searchFriends.operationQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(self.queue, NCSearchFriendsOperationQueueSpecificKey, NCSearchFriendsOperationQueueSpecificKey, NULL);
    }
    return self;
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [NCFriendListCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    id<NCCellViewModelProtocol> vm = [self.dataSource objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(searchFriendsViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL ret = [self.delegate searchFriendsViewModel:self
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
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<NCCellViewModelProtocol> vm = [self.dataSource objectAtIndex:indexPath.row];
    UITableViewCell *cell = [vm tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell;
}


#pragma mark - SearchBar
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        [self restoreData];
    } else {
        [self fetchDataWithKeyword:searchText];
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

- (NSArray *)sectionIndexTitles {
    return @[];
}

- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureSearchBarViewModelForSearchFriendsViewModel:)]) {
        self.searchBarVM = [self.delegate willConfigureSearchBarViewModelForSearchFriendsViewModel:self];
    } else if(!self.searchBarVM) {
        NCSearchBarViewModel *vm = [[NCSearchBarViewModel alloc] initWithResponder:viewController];
        vm.delegate = self;
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForSearchFriendsViewModel:)]) {
        self.naviItemsVM = [self.delegate willConfigureRightNavigationItemsForSearchFriendsViewModel:self];
    }
    return [self.naviItemsVM rightNavigationBarItems];
}

- (void)endEditingState {
    [self.searchBarVM endEditingState];
    [self restoreData];
}

- (void)fetchDataWithKeyword:(NSString *)keyword {
    [[NCEngine userModule] searchFriendsInfoWithName:keyword completion:^(NSArray<NCFriendInfo *> * _Nullable friendInfos, NCError * _Nullable error) {
        if (error) {
            [self showErrorByCode:error.code];
            [self reloadData:NO];
            return;
        }
        [self configureDataSourceWithArray:friendInfos];
    }];
}

- (void)configureDataSourceWithArray:(NSArray<NCFriendInfo *> *)friendInfos {
    [self performOperationQueueBlock:^{
            NSArray *array = nil;
            NSMutableArray *tmp = [NSMutableArray array];
            
            for (NCFriendInfo *friend in friendInfos) {
                NCFriendListCellViewModel *vm = [[NCFriendListCellViewModel alloc] initWithFriend:friend];
                [tmp addObject:vm];
            }
            array = tmp;
            // Notify the consumer that the data source changed.
        if ([self.delegate respondsToSelector:@selector(searchFriendsViewModel:willLoadItemsInDataSource:)]) {
            array = [self.delegate searchFriendsViewModel:self
                                willLoadItemsInDataSource:tmp];
            }
        if (array) {
            [self removeSeparatorLineIfNeed:@[array]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSource = array;
            // Ask the view controller to reload the list.
            [self reloadData:array.count==0];
        });
    }];
}

- (void)bindResponder:(id<NCListViewModelResponder>)responder {
    self.responder = responder;
}

#pragma mark - Private

- (void)restoreData {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataSource = @[];
        // Ask the view controller to reload the list.
        [self reloadData:NO];
    });}

- (void)reloadData:(BOOL)isEmpty {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{

            [self.responder reloadData:isEmpty];
        });
    }
}

- (void)showErrorByCode:(NSInteger)code {
    if ([self.responder respondsToSelector:@selector(showTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder showTips:NCUILocalizedString(@"friend_list_failed")];
        });
    }
}

- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(NCSearchFriendsOperationQueueSpecificKey)) {
        block();
    }
    else {
        dispatch_async(self.queue, block);
    }
}
@end
