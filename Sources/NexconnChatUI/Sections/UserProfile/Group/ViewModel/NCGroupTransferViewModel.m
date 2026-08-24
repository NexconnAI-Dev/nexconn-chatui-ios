//
//  NCGroupTransferViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupTransferViewModel.h"
#import "NCAlertView.h"
#import "NCChatUI.h"
#import "NCChatUICommonDefine.h"
#import "NCGroupManager.h"
#import "NCGroupMemberCell.h"
#import "NCProfileViewController.h"
#import "NCRemoveGroupMemberCellViewModel.h"
#import "NCUserProfileViewModel.h"
@interface NCGroupTransferViewModel () <NCSearchBarViewModelDelegate>

@property (nonatomic, strong) NSMutableArray<NCGroupMemberCellViewModel *> *mutableMemberList;

@property (nonatomic, strong) NSMutableArray<NCGroupMemberCellViewModel *> *matchMemberList;

@property (nonatomic, strong) NCSearchBarViewModel *searchBarVM;

@property (nonatomic, strong) NCUIPagingQueryResult<NCGroupMemberInfo *> *queryResult;

@property (nonatomic, strong) NCSearchGroupMembersQuery *searchMembersQuery;

@property (nonatomic, assign) NSInteger loadedSearchMemberCount;

@property (nonatomic, assign) BOOL hasMoreSearchMembers;

@property (nonatomic, assign) BOOL isLoadingSearchMembers;

@property (nonatomic, weak) id<NCListViewModelResponder> responder;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, weak) NCGroupMemberCellViewModel *lastBottomCellVM;
@end

@implementation NCGroupTransferViewModel
@dynamic delegate;

+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    NCGroupTransferViewModel *viewModel = [[self.class alloc] init];
    viewModel.groupId = groupId;
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
        [self removeSeparatorWithArray:[self memberList]];
        [self.responder reloadData:NO];
    } else {
        [self filterDataSource];
    }
}

- (void)searchBar:(UISearchBar *)searchBar editingStateChanged:(BOOL)inSearching {
    if (!inSearching) {
        [self endEditingState];
    }
    [self removeSeparatorWithArray:[self memberList]];
    [self.responder reloadData:NO];
}

#pragma mark-- NCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCGroupMemberCell class]
        forCellReuseIdentifier:NCGroupMemberCellIdentifier];
}

- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    NCGroupMemberCellViewModel *cellViewModel = self.memberList[indexPath.row];
    if ([self.delegate respondsToSelector:@selector(groupMemberList:viewController:tableView:
                                                    didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate groupMemberList:self
                                         viewController:[self.responder currentViewController]
                                              tableView:tableView
                                           didSelectRow:indexPath
                                          cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }
    if ([[NCEngine getCurrentUserId] isEqualToString:cellViewModel.memberInfo.userId]) {
        return;
    }
    NSString *name;
    if (cellViewModel.remark.length > 0) {
        name = cellViewModel.remark;
    } else if (cellViewModel.memberInfo.nickname.length > 0) {
        name = cellViewModel.memberInfo.nickname;
    } else {
        name = cellViewModel.memberInfo.name;
    }
    NSString *message =
        [NSString stringWithFormat:NCUILocalizedString(@"group_transfer_alert"), name];
    [NCAlertView showAlertController:nil
                             message:message
                        actionTitles:nil
                         cancelTitle:NCUILocalizedString(@"cancel")
                        confirmTitle:NCUILocalizedString(@"confirm")
                      preferredStyle:(UIAlertControllerStyleAlert)actionsBlock:nil
                         cancelBlock:nil
                        confirmBlock:^{
                          [self groupTranfer:cellViewModel.memberInfo.userId];
                        }
                    inViewController:viewController];
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
        self.lastBottomCellVM = array.lastObject;
    }
}

- (NSArray<NCRemoveGroupMemberCellViewModel *> *)
    getViewModelsWithMembers:(NSArray<NCGroupMemberInfo *> *)members
                 friendInfos:(NSArray<NCFriendInfo *> *)friendInfos {
    NSMutableArray *list = [NSMutableArray array];
    for (NCGroupMemberInfo *member in members) {
        if ([member.userId isEqualToString:[NCEngine getCurrentUserId]]) {
            continue;
        }
        NCGroupMemberCellViewModel *cellVM =
            [[NCGroupMemberCellViewModel alloc] initWithMember:member];
        if (friendInfos.count > 0) {
            cellVM.remark =
                [NCGroupManager friendWithUserId:member.userId inFriendInfos:friendInfos].remark;
        }
        cellVM.hiddenArrow = YES;
        [list addObject:cellVM];
    }
    if ([self.delegate respondsToSelector:@selector(groupMemberList:willLoadItemsInDataSource:)]) {
        list = [self.delegate groupMemberList:self willLoadItemsInDataSource:list].mutableCopy;
    }
    return list;
}

- (void)groupTranfer:(NSString *)userId {
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId ?: @""];
    if (!channel) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [NCAlertView showAlertController:nil
                                   message:NCUILocalizedString(@"group_transfer_failed")
                          hiddenAfterDelay:1];
        });
        return;
    }
    NCTransferGroupOwnerParams *params = [NCTransferGroupOwnerParams new];
    params.newOwnerId = userId ?: @"";
    params.leaveAfterTransfer = NO;
    [channel
        transferOwnerWithParams:params
                     completion:^(NCError *_Nullable error) {
                       if (error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                             [NCAlertView
                                 showAlertController:nil
                                             message:NCUILocalizedString(@"group_transfer_failed")
                                    hiddenAfterDelay:1];
                           });
                           return;
                       }
                       if ([self.delegate
                               respondsToSelector:
                                   @selector(groupOwnerDidTransfer:newOwnerId:viewController:)]) {
                           BOOL intercept = [self.delegate
                               groupOwnerDidTransfer:self.groupId
                                          newOwnerId:userId
                                      viewController:[self.responder currentViewController]];
                           if (intercept) {
                               return;
                           }
                       }
                       dispatch_async(dispatch_get_main_queue(), ^{
                         NSArray *viewControllers = [self.responder currentViewController]
                                                        .navigationController.viewControllers;
                         if (viewControllers.count > 2) {
                             [[self.responder currentViewController].navigationController
                                 popToViewController:viewControllers[viewControllers.count - 3]
                                            animated:YES];
                         }

                         [NCAlertView
                             showAlertController:nil
                                         message:NCUILocalizedString(@"group_transfer_success")
                                hiddenAfterDelay:1];
                       });
                     }];
}

#pragma mark-- setter

- (void)setPageCount:(NSInteger)pageCount {
    if (pageCount <= 0) {
        return;
    } else if (pageCount > 100) {
        pageCount = 100;
    }
    _pageCount = pageCount;
}

#pragma mark-- getter

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
