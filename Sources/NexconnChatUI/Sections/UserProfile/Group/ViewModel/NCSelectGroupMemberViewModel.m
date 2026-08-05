//
//  NCSelectGroupMemberViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSelectGroupMemberViewModel.h"
#import "NCRemoveGroupMemberCellViewModel.h"
#import "NCGroupManager.h"
#import "NCAlertView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUI.h"
@interface NCSelectGroupMemberViewModel ()<NCSearchBarViewModelDelegate>

@property (nonatomic, strong) NSMutableArray <NCRemoveGroupMemberCellViewModel *>*mutableMemberList;

@property (nonatomic, strong) NSMutableArray <NCRemoveGroupMemberCellViewModel *>*matchMemberList;

@property (nonatomic, strong) NSMutableArray <NSString *>*selectUserIds;

@property (nonatomic, strong) NCSearchBarViewModel *searchBarVM;

@property (nonatomic, strong) NCUIPagingQueryResult<NCGroupMemberInfo *> *queryResult;

@property (nonatomic, strong) NCSearchGroupMembersQuery *searchMembersQuery;

@property (nonatomic, assign) NSInteger loadedSearchMemberCount;

@property (nonatomic, assign) BOOL hasMoreSearchMembers;

@property (nonatomic, weak) id<NCListViewModelResponder> responder;

@property (nonatomic, assign) NSInteger pageCount;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, strong) NSArray *existingUserIds;

@end
@implementation NCSelectGroupMemberViewModel

@dynamic delegate;

+ (instancetype)viewModelWithGroupId:(NSString *)groupId existingUserIds:(NSArray *)existingUserIds{
    NCSelectGroupMemberViewModel *viewModel = [[self.class alloc] init];
    viewModel.groupId = groupId;
    viewModel.existingUserIds = existingUserIds;
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.pageCount = 100;
        self.maxSelectCount = 100;
        self.hasMoreSearchMembers = YES;
    }
    return self;
}

- (void)fetchGroupMembersByPage {
    if ([self.searchBarVM isCurrentFirstResponder]) {
        [self filterDataSource];
    } else {
        [self fetchGroupMembers];
    }
}

- (void)endEditingState {
    self.searchMembersQuery = nil;
    self.loadedSearchMemberCount = 0;
    self.hasMoreSearchMembers = YES;
    [self.matchMemberList removeAllObjects];
    [self.searchBarVM endEditingState];
}

- (void)bindResponder:(id<NCListViewModelResponder>)responder {
    self.responder = responder;
}

#pragma mark - NCSearchBarViewModelDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchMembersQuery = nil;
    self.loadedSearchMemberCount = 0;
    self.hasMoreSearchMembers = YES;
    [self.matchMemberList removeAllObjects];
    if (searchText.length == 0) {
        [self.responder reloadData:NO];
    } else {
        [self filterDataSource];
    }
}

- (void)searchBar:(UISearchBar *)searchBar editingStateChanged:(BOOL)inSearching {
    if (!inSearching) {
        [self endEditingState];
    }
    [self.responder reloadData:NO];
}

#pragma mark -- NCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [NCRemoveGroupMemberCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController *)viewController tableView:(UITableView *)tableView didSelectRow:(NSIndexPath *)indexPath {
    NCRemoveGroupMemberCellViewModel *vm = (NCRemoveGroupMemberCellViewModel *)self.memberList[indexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(selectGroupMember:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate selectGroupMember:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:vm];
        if (intercept) {
            return;
        }
    }
    
    if (vm.selectState != NCSelectStateDisable){
        if ((vm.selectState == NCSelectStateUnselect) && self.selectUserIds.count >= self.maxSelectCount) {
            if (!self.tip) {
                self.tip = [NSString stringWithFormat:NCUILocalizedString(@"group_member_select_max_tip"), @(self.maxSelectCount)];
            }
            [NCAlertView showAlertController:nil message:self.tip hiddenAfterDelay:2];
            return;
        }
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [vm updateCell:cell state:(vm.selectState ? NCSelectStateUnselect : NCSelectStateSelect)];
        if (vm.selectState == NCSelectStateSelect) {
            [self.selectUserIds addObject:vm.member.userId];
        } else {
            [self.selectUserIds removeObject:vm.member.userId];
        }
        if ([self.responder respondsToSelector:@selector(updateItem:)]) {
            [self.responder updateItem:indexPath];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCRemoveGroupMemberCellViewModel *cellVM = (NCRemoveGroupMemberCellViewModel *)self.memberList[indexPath.row];
    UITableViewCell *cell = [cellVM tableView:tableView cellForRowAtIndexPath:indexPath];
    [self updateCellViewModelSelectState:cellVM complete:^(NCSelectState state) {
        [cellVM updateCell:cell state:state];
    }];
    return cell;
}


#pragma mark -- private

- (NSInteger)totalCountForSearchQuery {
    if (![self.searchMembersQuery respondsToSelector:@selector(totalCount)]) {
        return -1;
    }
    return self.searchMembersQuery.totalCount;
}

- (BOOL)searchHasMoreWithCurrentPageCount:(NSInteger)currentPageCount {
    NSInteger totalCount = [self totalCountForSearchQuery];
    if (totalCount >= 0) {
        return self.loadedSearchMemberCount < totalCount;
    }
    return currentPageCount >= self.pageCount;
}

- (void)filterDataSource {
    if (self.searchMembersQuery && !self.hasMoreSearchMembers) {
        return;
    }
    if (!self.searchMembersQuery) {
        NCSearchGroupMembersQueryParams *params = [NCSearchGroupMembersQueryParams new];
        params.groupId = self.groupId;
        params.memberName = self.searchBarVM.searchBar.text ?: @"";
        params.pageSize = self.pageCount;
        self.searchMembersQuery = [NCGroupChannel createSearchGroupMembersQueryWithParams:params];
    }
    [self.searchMembersQuery loadNextPageWithCompletion:^(NSArray<NCGroupMemberInfo *> * _Nullable members,
                                                          NCError * _Nullable error) {
        if (error) {
            return;
        }
        NSArray<NCGroupMemberInfo *> *memberList = members ?: @[];
        self.loadedSearchMemberCount += memberList.count;
        self.hasMoreSearchMembers = [self searchHasMoreWithCurrentPageCount:memberList.count];
        NSMutableArray<NSString *> *userIds = [NSMutableArray array];
        for (NCGroupMemberInfo *member in memberList) {
            if (member.userId.length > 0) {
                [userIds addObject:member.userId];
            }
        }
        [NCGroupManager fetchFriendInfosWithUserIds:userIds.copy complete:^(NSArray<NCFriendInfo *> * _Nullable friendInfos) {
            NSArray *list = [self getViewModelsWithMembers:memberList friendInfos:friendInfos];
            if (list.count) {
                [self removeSeparatorLineIfNeed:@[list]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.matchMemberList addObjectsFromArray:list];
                [self.responder reloadData:self.matchMemberList.count == 0];
            });
        }];
    }];
}

- (void)fetchGroupMembers {
    if (self.queryResult && self.queryResult.pageToken.length == 0) {
        return;
    }
    NCUIPagingQueryOption *option = [NCUIPagingQueryOption new];
    option.pageToken = self.queryResult.pageToken;
    option.count = self.pageCount;
    NCGroupMemberRole role;
    // The first page includes the owner and admins. Once queryResult exists, later pages load regular members only.
    if (self.queryResult) {
        role = NCGroupMemberRoleNormal;
    } else {
        role = NCGroupMemberRoleUndef;
    }
    option.order = YES;
    [NCGroupManager getGroupMemberInfos:self.groupId option:option role:role complete:^(NCUIPagingQueryResult<NCGroupMemberInfo *> * _Nonnull result) {
        if (result.data.count == 0) {
            return;
        }
        NSMutableArray<NSString *> *userIds = [NSMutableArray array];
        for (NCGroupMemberInfo *member in result.data) {
            if (member.userId.length > 0) {
                [userIds addObject:member.userId];
            }
        }
        [NCGroupManager fetchFriendInfosWithUserIds:userIds.copy complete:^(NSArray<NCFriendInfo *> * _Nullable friendInfos) {
            NSArray *list = [self getViewModelsWithMembers:result.data friendInfos:friendInfos];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.queryResult = result;
                [self.mutableMemberList addObjectsFromArray:list];
                [self.responder reloadData:NO];
            });
        }];
    }];
}

#pragma mark -- public

- (UISearchBar *)configureSearchBar {
    NCSearchBarViewModel *vm = [[NCSearchBarViewModel alloc] init];
    vm.delegate = self;
    if ([self.delegate respondsToSelector:@selector(selectGroupMember:willLoadSearchBarViewModel:)]) {
        self.searchBarVM = [self.delegate selectGroupMember:self willLoadSearchBarViewModel:vm];
    } else {
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (void)selectionDidDone {
    if ([self.delegate respondsToSelector:@selector(selectGroupMemberDidSelectComplete:selectUserIds:viewController:)]) {
        BOOL intercept = [self.delegate selectGroupMemberDidSelectComplete:self selectUserIds:self.selectUserIds viewController:[self.responder currentViewController]];
        if (intercept) {
            return;
        }
    }
    if (self.selectionDidCompelteBlock) {
        self.selectionDidCompelteBlock(self.selectUserIds, [self.responder currentViewController]);
    }
}


- (NSArray<NCRemoveGroupMemberCellViewModel *> *)getViewModelsWithMembers:(NSArray<NCGroupMemberInfo *> *)members friendInfos:(NSArray<NCFriendInfo *> *)friendInfos {
    NSMutableArray *list = [NSMutableArray array];
    for (NCGroupMemberInfo *member in members) {
        if ([self.hideUserIds containsObject:member.userId]) {
            continue;
        }
        NCRemoveGroupMemberCellViewModel *cellVM = [[NCRemoveGroupMemberCellViewModel alloc] initWithMember:member];
        if (friendInfos.count > 0) {
            cellVM.remark = [NCGroupManager friendWithUserId:member.userId inFriendInfos:friendInfos].remark;
        }
        [list addObject:cellVM];
    }
    if ([self.delegate respondsToSelector:@selector(selectGroupMember:willLoadItemsInDataSource:)]) {
        list = [self.delegate selectGroupMember:self willLoadItemsInDataSource:list].mutableCopy;
    }
    if (list.count) {
        [self removeSeparatorLineIfNeed:@[list]];
    }
    return list;
}

- (void)updateCellViewModelSelectState:(NCRemoveGroupMemberCellViewModel *)cellVM complete:(void(^)(NCSelectState state))complete {
    if ([cellVM.member.userId isEqualToString:[NCEngine getCurrentUserId]]) {
        complete(NCSelectStateDisable);
        return;
    }
    
    if ([self.existingUserIds containsObject:cellVM.member.userId]) {
        complete(NCSelectStateDisable);
        return;
    }
    
    if ([self.selectUserIds containsObject:cellVM.member.userId]) {
        complete(NCSelectStateSelect);
        return;
    }

    complete(NCSelectStateUnselect);
    return;
}

#pragma mark -- setter

- (void)setMaxSelectCount:(NSInteger)maxSelectCount {
    if (maxSelectCount < 0) {
        return;
    }
    if (maxSelectCount > 100) {
        maxSelectCount = 100;
    }
    _maxSelectCount = maxSelectCount;
}

#pragma mark -- getter

- (NSMutableArray<NSString *> *)selectUserIds {
    if (!_selectUserIds) {
        _selectUserIds = [NSMutableArray array];
    }
    return _selectUserIds;
}

- (NSArray<NCRemoveGroupMemberCellViewModel *> *)memberList {
    if (self.searchBarVM.searchBar.text.length > 0) {
        return self.matchMemberList;
    }
    return self.mutableMemberList;
}

- (NSMutableArray<NCRemoveGroupMemberCellViewModel *> *)matchMemberList {
    if (!_matchMemberList) {
        _matchMemberList = [NSMutableArray array];
    }
    return _matchMemberList;
}

- (NSMutableArray<NCRemoveGroupMemberCellViewModel *> *)mutableMemberList {
    if (!_mutableMemberList) {
        _mutableMemberList = [NSMutableArray array];
    }
    return _mutableMemberList;
}

@end
