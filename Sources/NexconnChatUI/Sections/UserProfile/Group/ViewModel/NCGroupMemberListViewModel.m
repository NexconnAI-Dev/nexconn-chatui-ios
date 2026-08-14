//
//  NCGroupMemberListViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupMemberListViewModel.h"
#import "NCGroupMemberCell.h"
#import "NCGroupManager.h"
#import "NCProfileViewController.h"
#import "NCUserProfileViewModel.h"
#import "NCChatUICommonDefine.h"
#import "NCRemoveGroupMemberCellViewModel.h"
#import "NCAlertView.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

static BOOL NCGroupMemberListOperationInvalidatesCurrentUser(NCGroupOperationEvent *event) {
    if (event.operation == NCGroupOperationDismiss) {
        return YES;
    }
    if (event.operation != NCGroupOperationKick && event.operation != NCGroupOperationQuit) {
        return NO;
    }
    NSString *currentUserId = [NCEngine getCurrentUserId] ?: @"";
    if (currentUserId.length == 0) {
        return NO;
    }
    for (NCGroupMemberInfo *memberInfo in event.memberInfos) {
        if ([memberInfo.userId isEqualToString:currentUserId]) {
            return YES;
        }
    }
    return NO;
}

@interface NCGroupMemberListViewModel ()<NCSearchBarViewModelDelegate, NCGroupChannelHandler>


@property (nonatomic, strong) NSMutableArray <NCGroupMemberCellViewModel *>*mutableMemberList;

@property (nonatomic, strong) NSMutableArray <NCGroupMemberCellViewModel *>*matchMemberList;

@property (nonatomic, strong) NCSearchBarViewModel *searchBarVM;

@property (nonatomic, strong) NCUIPagingQueryResult<NCGroupMemberInfo *> *queryResult;

@property (nonatomic, strong) NCSearchGroupMembersQuery *searchMembersQuery;

@property (nonatomic, assign) NSInteger loadedSearchMemberCount;

@property (nonatomic, assign) BOOL hasMoreSearchMembers;

@property (nonatomic, weak) id<NCListViewModelResponder> responder;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, assign) BOOL isLoadingMembers;

@property (nonatomic, assign) BOOL isLoadingSearchMembers;

@property (nonatomic, weak) NCGroupMemberCellViewModel *lastBottomCellVM;

@property (nonatomic, copy) NSString *groupEventHandlerId;
@end

@implementation NCGroupMemberListViewModel
@dynamic delegate;

+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    NCGroupMemberListViewModel *viewModel = [[self.class alloc] init];
    viewModel.groupId = groupId;
    viewModel.groupEventHandlerId = [NSString stringWithFormat:@"rc.group.member.list.%p", viewModel];
    [NCEngine addGroupChannelHandlerWithIdentifier:viewModel.groupEventHandlerId handler:viewModel];
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.pageCount = 50;
        self.hasMoreSearchMembers = YES;
    }
    return self;
}

- (void)dealloc {
    [NCEngine removeGroupChannelHandlerForIdentifier:self.groupEventHandlerId];
}

- (UISearchBar *)configureSearchBar {
    NCSearchBarViewModel *vm = [[NCSearchBarViewModel alloc] init];
    vm.delegate = self;
    if ([self.delegate respondsToSelector:@selector(groupMemberList:willLoadSearchBarViewModel:)]) {
        self.searchBarVM = [self.delegate groupMemberList:self willLoadSearchBarViewModel:vm];
    } else {
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
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

#pragma mark -- NCGroupChannelHandler

- (void)onGroupOperation:(NCGroupOperationEvent *)event {
    if (![event.groupId isEqualToString:self.groupId] ||
        !NCGroupMemberListOperationInvalidatesCurrentUser(event)) {
        return;
    }
    void (^leaveBlock)(void) = ^{
        UIViewController *viewController = [self.responder currentViewController];
        [viewController.navigationController popViewControllerAnimated:YES];
        [NCAlertView showAlertController:nil message:NCUILocalizedString(@"not_in_group") hiddenAfterDelay:1];
    };
    if ([NSThread isMainThread]) {
        leaveBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), leaveBlock);
    }
}

#pragma mark - RCFriendListSearchBarViewModelDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchMembersQuery = nil;
    self.loadedSearchMemberCount = 0;
    self.hasMoreSearchMembers = YES;
    [self.matchMemberList removeAllObjects];
    if (searchText.length == 0) {
        [self removeSeparatorWithArray:self.memberList];

        [self.responder reloadData:NO];
    } else {
        [self filterDataSource];
    }
}

- (void)searchBar:(UISearchBar *)searchBar editingStateChanged:(BOOL)inSearching {
    if (!inSearching) {
        [self endEditingState];
    }
    [self removeSeparatorWithArray:self.memberList];

    [self.responder reloadData:NO];
}

#pragma mark -- NCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCGroupMemberCell class]
      forCellReuseIdentifier:NCGroupMemberCellIdentifier];
}

- (void)viewController:(UIViewController *)viewController tableView:(UITableView *)tableView didSelectRow:(NSIndexPath *)indexPath {
    NCGroupMemberCellViewModel *cellViewModel = self.memberList[indexPath.row];
    if ([self.delegate respondsToSelector:@selector(groupMemberList:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate groupMemberList:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }
    NCProfileViewModel *viewModel = [NCUserProfileViewModel viewModelWithUserId:cellViewModel.memberInfo.userId];
    if ([viewModel isKindOfClass:NCUserProfileViewModel.class]) {
        [((NCUserProfileViewModel *)viewModel) showGroupMemberInfo:self.groupId];
    }
    NCProfileViewController *vc = [[NCProfileViewController alloc] initWithViewModel:viewModel];
    [viewController.navigationController pushViewController:vc animated:YES];
}

#pragma mark -- private

- (void)removeSeparatorWithArray:(NSArray *)array {
    if (array.count) {
        if ([self.lastBottomCellVM isKindOfClass:[NCBaseCellViewModel class]]) { // Last cell from the previous page.
            self.lastBottomCellVM.hideSeparatorLine = NO;
        }
        [self removeSeparatorLineIfNeed:@[array]];
        self.lastBottomCellVM = array.lastObject;
    }
}
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
    // Prevent concurrent search requests.
    if (self.isLoadingSearchMembers) {
        return;
    }
    
    if (self.searchMembersQuery && !self.hasMoreSearchMembers) {
        return;
    }
    
    // Mark search loading as active.
    self.isLoadingSearchMembers = YES;

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
            self.isLoadingSearchMembers = NO;
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
            dispatch_async(dispatch_get_main_queue(), ^{
                // Clear the search loading state and update the data.
                self.isLoadingSearchMembers = NO;
                [self.matchMemberList addObjectsFromArray:list];
                [self removeSeparatorWithArray:list];
                [self.responder reloadData:self.matchMemberList.count == 0];
            });
        }];
    }];
}

- (void)fetchGroupMembers {
    // Prevent concurrent page requests.
    if (self.isLoadingMembers) {
        return;
    }
    
    if (self.queryResult && self.queryResult.pageToken.length == 0) {
        return;
    }
    
    // Mark page loading as active.
    self.isLoadingMembers = YES;
    
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
            // Clear the loading state.
            self.isLoadingMembers = NO;
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
                // Clear the loading state and update the data.
                self.isLoadingMembers = NO;
                self.queryResult = result;
                [self.mutableMemberList addObjectsFromArray:list];
                [self removeSeparatorWithArray:list];
                [self.responder reloadData:NO];
            });
        }];
    }];
}

- (NSArray<NCRemoveGroupMemberCellViewModel *> *)getViewModelsWithMembers:(NSArray<NCGroupMemberInfo *> *)members friendInfos:(NSArray<NCFriendInfo *> *)friendInfos {
    NSMutableArray *list = [NSMutableArray array];
    for (NCGroupMemberInfo *member in members) {
        NCGroupMemberCellViewModel *cellVM = [[NCGroupMemberCellViewModel alloc] initWithMember:member];
        if (friendInfos.count > 0) {
            cellVM.remark = [NCGroupManager friendWithUserId:member.userId inFriendInfos:friendInfos].remark;
        }
        [list addObject:cellVM];
    }
    if ([self.delegate respondsToSelector:@selector(groupMemberList:willLoadItemsInDataSource:)]) {
        list = [self.delegate groupMemberList:self willLoadItemsInDataSource:list].mutableCopy;
    }
    return list;
}

#pragma mark -- setter

- (void)setPageCount:(NSInteger)pageCount {
    if (pageCount <= 0) {
        return;
    } else if (pageCount > 100) {
        pageCount = 100;
    }
    _pageCount = pageCount;
}

#pragma mark -- getter

- (NSArray<NCGroupMemberCellViewModel *> *)memberList {
    if (self.searchBarVM.searchBar.text.length > 0) {
        return self.matchMemberList;
    }
    return self.mutableMemberList;
}

- (NSMutableArray<NCGroupMemberCellViewModel *> *)matchMemberList {
    if (!_matchMemberList) {
        _matchMemberList = [NSMutableArray array];
    }
    return _matchMemberList;
}

- (NSMutableArray<NCGroupMemberCellViewModel *> *)mutableMemberList {
    if (!_mutableMemberList) {
        _mutableMemberList = [NSMutableArray array];
    }
    return _mutableMemberList;
}
@end
