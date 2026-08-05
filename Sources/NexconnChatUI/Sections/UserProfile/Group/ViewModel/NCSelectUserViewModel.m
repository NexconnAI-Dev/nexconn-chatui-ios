//
//  NCSelectUserViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSelectUserViewModel.h"
#import "NCUPinYinTools.h"
#import "NCChatUICommonDefine.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCChatUI.h"
#import "NCNavigationItemsViewModel.h"
#import "NCAlertView.h"
#import "NCGroupCreateViewController.h"
#import "NSMutableArray+NCOperation.h"
#import "NCGroupManager.h"

static void *NCSelectUserOperationQueueSpecificKey = &NCSelectUserOperationQueueSpecificKey;

@interface NCSelectUserViewModel ()<NCSearchBarViewModelDelegate>
@property (nonatomic, strong) NCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, strong) NCSearchBarViewModel *searchBarVM;

// All cells.
@property (nonatomic, strong) NSArray *dataSource;
// Section index titles.
@property (nonatomic, strong) NSArray *indexTitles;
// Cells grouped by index title.
@property (nonatomic, strong) NSDictionary *dicInfo;
// Search result cells.
@property (nonatomic, strong) NSArray *matchFriendList;

@property (nonatomic, weak) id<NCListViewModelResponder> responder;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) NSMutableArray <NSString *>*selectUserIds;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, assign) NCSelectUserType type;

@property (nonatomic, strong) NSArray <NCGroupMemberInfo *> *members;

@end

@implementation NCSelectUserViewModel
@dynamic delegate;

+ (instancetype)viewModelWithType:(NCSelectUserType)type groupId:(NSString *)groupId {
    NCSelectUserViewModel *viewModel = [self.class new];
    viewModel.type = type;
    viewModel.groupId = groupId;
    return viewModel;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.maxSelectCount = 30;
        self.queue = dispatch_queue_create("ai.nexconn.selectUser.operationQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(self.queue, NCSelectUserOperationQueueSpecificKey, NCSelectUserOperationQueueSpecificKey, NULL);
    }
    return self;
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [NCSelectUserCellViewModel registerCellForTableView:tableView];
}

#pragma mark -- NCListViewModelProtocol

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    NCSelectUserCellViewModel *vm;
    if ([self.searchBarVM isCurrentFirstResponder]) { // Search mode or a section other than the first.
        NSString *key = [self.indexTitles objectAtIndex:indexPath.section];
        NSArray *array = [self.dicInfo objectForKey:key];
        vm = [array objectAtIndex:indexPath.row];
    } else {
        NSString *key = [self.indexTitles objectAtIndex:indexPath.section];
        NSArray *array = [self.dicInfo objectForKey:key];
        vm = [array objectAtIndex:indexPath.row];
    }
    
    if ([self.delegate respondsToSelector:@selector(selectUserViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate selectUserViewModel:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:vm];
        if (intercept) {
            return;
        }
    }
    
    if (vm.selectState != NCSelectStateDisable){
        if (vm.selectState == NCSelectStateUnselect && self.selectUserIds.count >= self.maxSelectCount) {
            [NCAlertView showAlertController:nil message:[NSString stringWithFormat:NCUILocalizedString(@"group_member_select_max_tip"), @(self.maxSelectCount)] hiddenAfterDelay:2];
            return;
        }
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [vm updateCell:cell state:(vm.selectState == NCSelectStateSelect) ? NCSelectStateUnselect : NCSelectStateSelect];
        if (vm.selectState == NCSelectStateSelect) {
            [self.selectUserIds addObject:vm.friendInfo.userId];
        } else {
            [self.selectUserIds removeObject:vm.friendInfo.userId];
        }
        if ([self.responder respondsToSelector:@selector(updateItem:)]) {
            [self.responder updateItem:indexPath];
        }
    }
}

- (NSInteger)numberOfSections {
    NSInteger count = self.indexTitles.count;
    return count;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    if ([self.searchBarVM isCurrentFirstResponder]) { // Search mode.
        NSString *key = [self.indexTitles objectAtIndex:section];
        NSArray *array = [self.dicInfo objectForKey:key];
        return array.count;
    }
    
    NSString *key = [self.indexTitles objectAtIndex:section];
    NSArray *array = [self.dicInfo objectForKey:key];
    return array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    NSString *key = [self.indexTitles objectAtIndex:indexPath.section];
    NSArray *array = [self.dicInfo objectForKey:key];
    NCSelectUserCellViewModel *vm = [array objectAtIndex:indexPath.row];
    cell = [vm tableView:tableView cellForRowAtIndexPath:indexPath];
    [vm updateCell:cell state:[self cellSelectState:vm.friendInfo.userId members:self.members]];
    return cell;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section {
    return 32;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.frame = CGRectMake(0, 0, tableView.frame.size.width, 32);
    view.backgroundColor = NCDynamicColor(@"clear_color");
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.font = [UIFont systemFontOfSize:14.f];
    title.textColor = NCDynamicColor(@"text_primary_color");
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:title];
   
    title.text = self.indexTitles[section];
    [title sizeToFit];
    [NSLayoutConstraint activateConstraints:@[
        [title.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:16],
        [title.centerYAnchor constraintEqualToAnchor:view.centerYAnchor]
    ]];
    return view;
}

#pragma mark - SearchBar
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        [self restoreData];
    } else {
        [self filterDataSourceWithKeyword:searchText];
    }
}

- (void)searchBar:(UISearchBar *)searchBar editingStateChanged:(BOOL)inSearching {
    if (inSearching) {
        [self reloadData];
    } else {
        [self restoreData];
    }
}

#pragma mark - Public

- (NSArray *)sectionIndexTitles {
    return self.indexTitles;
}

- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    NCSearchBarViewModel *vm = [[NCSearchBarViewModel alloc] init];
    vm.delegate = self;
    if ([self.delegate respondsToSelector:@selector(selectUserViewModel:willLoadSearchBarViewModel:)]) {
        self.searchBarVM = [self.delegate selectUserViewModel:self willLoadSearchBarViewModel:vm];
    } else {
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (void)endEditingState {
    [self.searchBarVM endEditingState];
    [self restoreData];
}

- (void)fetchData {
    [[NCEngine userModule] getFriendsWithCompletion:^(NSArray<NCFriendInfo *> * _Nullable friendInfos, NCError * _Nullable error) {
        if (error) {
            [self reloadData];
            return;
        }
        [self configureDataSourceWithArray:friendInfos];
    }];
}

- (void)configureDataSourceWithArray:(NSArray<NCFriendInfo *> *)friendInfos {
    [self fetchGroupMember:friendInfos groupId:self.groupId complete:^(NSArray<NCGroupMemberInfo *> * _Nullable members) {
        self.members = members;
        NSArray *array = nil;
        NSMutableArray *tmp = [NSMutableArray array];
        for (NCFriendInfo *friend in friendInfos) {
            NCSelectUserCellViewModel *vm = [[NCSelectUserCellViewModel alloc] initWithFriend:friend groupId:self.groupId];
            vm.selectState = [self cellSelectState:friend.userId members:members];
            [tmp addObject:vm];
        }
        array = tmp;
        // Notify the consumer that the data source changed.
        if ([self.delegate respondsToSelector:@selector(selectUserViewModel:willLoadItemsInDataSource:)]) {
            array = [self.delegate selectUserViewModel:self willLoadItemsInDataSource:tmp];
        }
        self.dataSource = array;
        [self groupAndReloadItemsInArray:self.dataSource];
    }];
}

- (NCSelectState)cellSelectState:(NSString *)userId
                         members:(NSArray<NCGroupMemberInfo *> *)members {
    if ([userId isEqualToString:[NCEngine getCurrentUserId]]) {
        return NCSelectStateDisable;
    }
    
    if ([self.selectUserIds containsObject:userId]) {
        return NCSelectStateSelect;
    }
    
    if (self.type == NCSelectUserTypeCreateGroup) {
        return NCSelectStateUnselect;
    }
    
    if ([self inGroupWithUser:userId members:members]) {
        return NCSelectStateDisable;
    }
    
    return NCSelectStateUnselect;
}

- (void)selectionDidDone {
    if ([self.delegate respondsToSelector:@selector(selectUserDidSelectComplete:selectUserIds:viewController:)]) {
        BOOL intercept = [self.delegate selectUserDidSelectComplete:self selectUserIds:self.selectUserIds viewController:[self.responder currentViewController]];
        if (intercept) {
            return;
        }
    }
    
    if (self.selectionDidCompelteBlock) {
        self.selectionDidCompelteBlock(self.selectUserIds, [self.responder currentViewController]);
    }
    if (self.type == NCSelectUserTypeCreateGroup){
        [self showCreateGroupVC];
    }
}

- (NSString *)emptyTip {
    if ([self.searchBarVM isCurrentFirstResponder] && self.searchBarVM.searchBar.text.length > 0) {
        return NCUILocalizedString(@"not_user_found");
    } else {
        return NCUILocalizedString(@"no_add_friends");
    }
}

- (void)bindResponder:(id<NCListViewModelResponder>)responder {
    self.responder = responder;
}

#pragma mark - Private

- (void)showCreateGroupVC {
    NCGroupCreateViewModel *viewModel = [NCGroupCreateViewModel viewModelWithInviteeUserIds:self.selectUserIds];
    NCGroupCreateViewController *vc = [[NCGroupCreateViewController alloc] initWithViewModel:viewModel];
    [[self.responder currentViewController].navigationController pushViewController:vc animated:YES];
}

- (void)groupAndReloadItemsInArray:(NSArray *)array {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Group the data source.
        self.dicInfo = [NCUPinYinTools sortedWithPinYinArray:array
                                                  usingBlock:^NSString * _Nonnull(NCSelectUserCellViewModel * obj, NSUInteger idx) {
            return obj.friendInfo.remark.length > 0 ? obj.friendInfo.remark : obj.friendInfo.name;
        }];
        // Sort section index titles.
        self.indexTitles = [[self.dicInfo allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
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
        NSArray *allFriends = [self.dicInfo allValues];
        [self removeSeparatorLineIfNeed:allFriends];
        // Ask the view controller to reload the list.
        [self reloadData];
    });
}

- (void)filterDataSourceWithKeyword:(NSString *)keyword {
    [[NCEngine userModule] searchFriendsInfoWithName:keyword completion:^(NSArray<NCFriendInfo *> * _Nullable friendInfos, NCError * _Nullable error) {
        if (error) {
            return;
        }
        NSMutableArray *tmp = [NSMutableArray array];
        [self fetchGroupMember:friendInfos groupId:self.groupId complete:^(NSArray<NCGroupMemberInfo *> * _Nullable members) {
            for (NCFriendInfo *friend in friendInfos) {
                NCSelectUserCellViewModel *vm = [[NCSelectUserCellViewModel alloc] initWithFriend:friend groupId:self.groupId];
                vm.selectState = [self cellSelectState:friend.userId members:members];
                [tmp addObject:vm];
            }
            self.matchFriendList = tmp.copy;
            [self groupAndReloadItemsInArray:self.matchFriendList];
        }];
    }];
}

- (void)restoreData {
    self.matchFriendList = @[];
    [self groupAndReloadItemsInArray:self.dataSource];
}

- (void)reloadData {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder reloadData:self.indexTitles.count == 0];
        });
    }
}

- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(NCSelectUserOperationQueueSpecificKey)) {
        block();
    }
    else {
        dispatch_async(self.queue, block);
    }
}

- (void)fetchGroupMember:(NSArray <NCFriendInfo *> *)friendInfos
                 groupId:(NSString *)groupId
                complete:(void (^)(NSArray<NCGroupMemberInfo *> * _Nullable members))complete {
    if (groupId.length <= 0) {
        return complete(nil);
    }
    NSMutableArray *userIdList = [NSMutableArray array];
    for (NCFriendInfo *info in friendInfos) {
        [userIdList nc_addObject:info.userId];
    }
    if (userIdList.count == 0) {
        return complete(nil);
    }
    [NCGroupManager getGroupMemberInfos:groupId userIds:userIdList complete:^(NSArray<NCGroupMemberInfo *> * _Nullable groupMembers) {
        [self performOperationQueueBlock:^{
            complete(groupMembers);
        }];
    }];
}

- (BOOL)inGroupWithUser:(NSString *)userId
                members:(NSArray<NCGroupMemberInfo *> *)members {
    for (NCGroupMemberInfo *info in members) {
        if ([info.userId isEqualToString:userId]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark -- setter & getter

- (void)setMaxSelectCount:(NSInteger)maxSelectCount {
    if (maxSelectCount <= 0) {
        return;
    }
    if (maxSelectCount > 100) {
        maxSelectCount = 100;
    }
    _maxSelectCount = maxSelectCount;
}

- (NSMutableArray<NSString *> *)selectUserIds {
    if (!_selectUserIds) {
        _selectUserIds = [NSMutableArray array];
    }
    return _selectUserIds;
}
@end
