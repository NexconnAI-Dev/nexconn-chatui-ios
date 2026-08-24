//
//  NCRemoveGroupMembersViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCRemoveGroupMembersViewModel.h"
#import "NCAlertView.h"
#import "NCChatUI.h"
#import "NCChatUICommonDefine.h"
#import "NCGroupManager.h"
#import "NCRemoveGroupMemberCellViewModel.h"
@interface NCRemoveGroupMembersViewModel () <NCSearchBarViewModelDelegate>

@property (nonatomic, strong) NSMutableArray<NCRemoveGroupMemberCellViewModel *> *mutableMemberList;

@property (nonatomic, strong) NSMutableArray<NCRemoveGroupMemberCellViewModel *> *matchMemberList;

@property (nonatomic, strong) NSMutableArray<NSString *> *selectUserIds;

@property (nonatomic, strong) NCSearchBarViewModel *searchBarVM;

@property (nonatomic, strong) NCUIPagingQueryResult<NCGroupMemberInfo *> *queryResult;

@property (nonatomic, strong) NCSearchGroupMembersQuery *searchMembersQuery;

@property (nonatomic, assign) NSInteger loadedSearchMemberCount;

@property (nonatomic, assign) BOOL hasMoreSearchMembers;

@property (nonatomic, assign) BOOL isLoadingSearchMembers;

@property (nonatomic, weak) id<NCListViewModelResponder> responder;

@property (nonatomic, assign) NSInteger pageCount;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, strong) NCGroupInfo *group;

@property (nonatomic, weak) NCRemoveGroupMemberCellViewModel *lastBottomCellVM;
@end

@implementation NCRemoveGroupMembersViewModel

@dynamic delegate;

+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    NCRemoveGroupMembersViewModel *viewModel = [[self.class alloc] init];
    viewModel.groupId = groupId;
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.pageCount = 100;
        self.maxSelectCount = 30;
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
    self.isLoadingSearchMembers = NO;
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
    self.isLoadingSearchMembers = NO;
    [self.matchMemberList removeAllObjects];
    if (searchText.length == 0) {
        [self.responder reloadData:NO];
        [self removeSeparatorWithArray:self.memberList];

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

#pragma mark-- NCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [NCRemoveGroupMemberCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    NCRemoveGroupMemberCellViewModel *vm =
        (NCRemoveGroupMemberCellViewModel *)self.memberList[indexPath.row];

    if ([self.delegate respondsToSelector:@selector(groupRemoveMembers:viewController:tableView:
                                                    didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate groupRemoveMembers:self
                                            viewController:[self.responder currentViewController]
                                                 tableView:tableView
                                              didSelectRow:indexPath
                                             cellViewModel:vm];
        if (intercept) {
            return;
        }
    }

    if (vm.selectState != NCSelectStateDisable) {
        if ((vm.selectState == NCSelectStateUnselect) &&
            self.selectUserIds.count >= self.maxSelectCount) {
            [NCAlertView
                showAlertController:nil
                            message:[NSString stringWithFormat:NCUILocalizedString(
                                                                   @"group_member_select_max_tip"),
                                                               @(self.maxSelectCount)]
                   hiddenAfterDelay:2];
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

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCRemoveGroupMemberCellViewModel *cellVM =
        (NCRemoveGroupMemberCellViewModel *)self.memberList[indexPath.row];
    UITableViewCell *cell = [cellVM tableView:tableView cellForRowAtIndexPath:indexPath];
    [self updateCellViewModelSelectState:cellVM
                                complete:^(NCSelectState state) {
                                  [cellVM updateCell:cell state:state];
                                }];
    return cell;
}

#pragma mark-- private

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
    if (self.isLoadingSearchMembers) {
        return;
    }
    if (self.searchMembersQuery && !self.hasMoreSearchMembers) {
        return;
    }
    NSString *searchKeyword = self.searchBarVM.searchBar.text ?: @"";
    if (!self.searchMembersQuery) {
        NCSearchGroupMembersQueryParams *params = [NCSearchGroupMembersQueryParams new];
        params.groupId = self.groupId;
        params.memberName = searchKeyword;
        params.pageSize = self.pageCount;
        self.searchMembersQuery = [NCGroupChannel createSearchGroupMembersQueryWithParams:params];
    }
    NCSearchGroupMembersQuery *searchQuery = self.searchMembersQuery;
    self.isLoadingSearchMembers = YES;
    [searchQuery loadNextPageWithCompletion:^(NSArray<NCGroupMemberInfo *> *_Nullable members,
                                              NCError *_Nullable error) {
      BOOL queryIsCurrent = self.searchMembersQuery == searchQuery;
      BOOL keywordIsCurrent =
          [searchKeyword isEqualToString:self.searchBarVM.searchBar.text ?: @""];
      if (!queryIsCurrent || !keywordIsCurrent) {
          if (queryIsCurrent) {
              self.isLoadingSearchMembers = NO;
          }
          return;
      }
      if (error) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (self.searchMembersQuery != searchQuery ||
                ![searchKeyword isEqualToString:self.searchBarVM.searchBar.text ?: @""]) {
                return;
            }
            self.isLoadingSearchMembers = NO;
            if ([self.responder respondsToSelector:@selector(refreshingFinished:withTips:)]) {
                [self.responder refreshingFinished:NO withTips:nil];
            }
            [self.responder reloadData:self.matchMemberList.count == 0];
          });
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
      [NCGroupManager
          fetchFriendInfosWithUserIds:userIds.copy
                             complete:^(NSArray<NCFriendInfo *> *_Nullable friendInfos) {
                               NSArray *list = [self getViewModelsWithMembers:memberList
                                                                  friendInfos:friendInfos];
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 if (self.searchMembersQuery != searchQuery ||
                                     ![searchKeyword
                                         isEqualToString:self.searchBarVM.searchBar.text ?: @""]) {
                                     return;
                                 }
                                 self.isLoadingSearchMembers = NO;
                                 [self.matchMemberList addObjectsFromArray:list];
                                 [self removeSeparatorWithArray:list];
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
    // The first page includes the owner and admins. Once queryResult exists, later pages load
    // regular members only.
    if (self.queryResult) {
        role = NCGroupMemberRoleNormal;
    } else {
        role = NCGroupMemberRoleUndef;
    }
    option.order = YES;
    [NCGroupManager
        getGroupMemberInfos:self.groupId
                     option:option
                       role:role
                   complete:^(NCUIPagingQueryResult<NCGroupMemberInfo *> *_Nonnull result) {
                     if (result.data.count == 0) {
                         return;
                     }
                     NSMutableArray<NSString *> *userIds = [NSMutableArray array];
                     for (NCGroupMemberInfo *member in result.data) {
                         if (member.userId.length > 0) {
                             [userIds addObject:member.userId];
                         }
                     }
                     [NCGroupManager
                         fetchFriendInfosWithUserIds:userIds.copy
                                            complete:^(
                                                NSArray<NCFriendInfo *> *_Nullable friendInfos) {
                                              NSArray *list =
                                                  [self getViewModelsWithMembers:result.data
                                                                     friendInfos:friendInfos];
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                self.queryResult = result;
                                                [self.mutableMemberList addObjectsFromArray:list];
                                                [self removeSeparatorWithArray:list];
                                                [self.responder reloadData:NO];
                                              });
                                            }];
                   }];
}

- (void)removeSeparatorWithArray:(NSArray *)array {
    if (array.count) {
        if ([self.lastBottomCellVM
                isKindOfClass:[NCBaseCellViewModel class]]) { // Last cell from the previous page.
            self.lastBottomCellVM.hideSeparatorLine = NO;
        }
        [self removeSeparatorLineIfNeed:@[ array ]];
        self.lastBottomCellVM = [array lastObject];
    }
}
#pragma mark-- public

- (UISearchBar *)configureSearchBar {
    NCSearchBarViewModel *vm = [[NCSearchBarViewModel alloc] init];
    vm.delegate = self;
    if ([self.delegate
            respondsToSelector:@selector(groupRemoveMembers:willLoadSearchBarViewModel:)]) {
        self.searchBarVM = [self.delegate groupRemoveMembers:self willLoadSearchBarViewModel:vm];
    } else {
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (void)selectionDidDone {
    if ([self.delegate respondsToSelector:@selector(groupRemoveMembersDidSelectComplete:
                                                    selectUserIds:viewController:)]) {
        BOOL intercept = [self.delegate
            groupRemoveMembersDidSelectComplete:self
                                  selectUserIds:self.selectUserIds
                                 viewController:[self.responder currentViewController]];
        if (intercept) {
            return;
        }
    }
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId ?: @""];
    if (!channel) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [NCAlertView showAlertController:nil
                                   message:NCUILocalizedString(@"group_members_kick_failed")
                          hiddenAfterDelay:2];
        });
        return;
    }
    NCKickGroupMembersParams *params = [NCKickGroupMembersParams new];
    params.userIds = self.selectUserIds.copy;
    [channel
        kickMembersWithParams:params
                   completion:^(NCError *_Nullable error) {
                     if (error) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                           [NCAlertView
                               showAlertController:nil
                                           message:NCUILocalizedString(@"group_members_kick_failed")
                                  hiddenAfterDelay:2];
                         });
                         return;
                     }
                     dispatch_async(dispatch_get_main_queue(), ^{
                       [[self.responder currentViewController].navigationController
                           popViewControllerAnimated:YES];
                       [NCAlertView
                           showAlertController:nil
                                       message:NCUILocalizedString(@"group_members_kick_success")
                              hiddenAfterDelay:2];
                     });
                   }];
}

- (NSArray<NCRemoveGroupMemberCellViewModel *> *)
    getViewModelsWithMembers:(NSArray<NCGroupMemberInfo *> *)members
                 friendInfos:(NSArray<NCFriendInfo *> *)friendInfos {
    NSMutableArray *list = [NSMutableArray array];
    for (NCGroupMemberInfo *member in members) {
        NCRemoveGroupMemberCellViewModel *cellVM =
            [[NCRemoveGroupMemberCellViewModel alloc] initWithMember:member];
        if (friendInfos.count > 0) {
            cellVM.remark =
                [NCGroupManager friendWithUserId:member.userId inFriendInfos:friendInfos].remark;
        }
        [list addObject:cellVM];
    }
    if ([self.delegate
            respondsToSelector:@selector(groupRemoveMembers:willLoadItemsInDataSource:)]) {
        list = [self.delegate groupRemoveMembers:self willLoadItemsInDataSource:list].mutableCopy;
    }
    return list;
}

- (void)updateCellViewModelSelectState:(NCRemoveGroupMemberCellViewModel *)cellVM
                              complete:(void (^)(NCSelectState state))complete {
    if ([cellVM.member.userId isEqualToString:[NCEngine getCurrentUserId]]) {
        complete(NCSelectStateDisable);
        return;
    }

    if ([self.selectUserIds containsObject:cellVM.member.userId]) {
        complete(NCSelectStateSelect);
        return;
    }

    [self getMyGroupRole:^(NCGroupMemberRole role) {
      if (role != NCGroupMemberRoleOwner) {
          if (cellVM.member.role != NCGroupMemberRoleNormal) {
              complete(NCSelectStateDisable);
              return;
          }
      }
      complete(NCSelectStateUnselect);
      return;
    }];
}

- (void)getMyGroupRole:(void (^)(NCGroupMemberRole role))successBlock {
    if (self.group) {
        successBlock(self.group.role);
        return;
    }
    [NCGroupChannel getGroupsInfoWithGroupIds:@[ self.groupId ?: @"" ]
                                   completion:^(NSArray<NCGroupInfo *> *_Nullable groupInfos,
                                                NCError *_Nullable error) {
                                     if (error) {
                                         return;
                                     }
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       self.group = groupInfos.firstObject;
                                       successBlock(self.group.role);
                                     });
                                   }];
}

#pragma mark-- setter

- (void)setMaxSelectCount:(NSInteger)maxSelectCount {
    if (maxSelectCount <= 0) {
        return;
    }
    if (maxSelectCount > 100) {
        maxSelectCount = 100;
    }
    _maxSelectCount = maxSelectCount;
}

#pragma mark-- getter

- (NSMutableArray<NSString *> *)selectUserIds {
    if (!_selectUserIds) {
        _selectUserIds = [NSMutableArray array];
    }
    return _selectUserIds;
}

- (NSArray<NCRemoveGroupMemberCellViewModel *> *)memberList {
    if (self.searchBarVM.searchBar.text.length != 0) {
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
