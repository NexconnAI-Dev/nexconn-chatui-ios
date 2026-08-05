//
//  NCGroupMentionViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupMentionViewModel.h"
#import "NCGroupMemberCell.h"
#import "NCGroupManager.h"
#import "NCChatUICommonDefine.h"

NSString  * const NCMentionAllUsersID = @"All";

@interface NCGroupMentionViewModel ()<NCSearchBarViewModelDelegate>


@property (nonatomic, strong) NSMutableArray <NCGroupMemberCellViewModel *>*mutableMemberList;

@property (nonatomic, strong) NSMutableArray <NCGroupMemberCellViewModel *>*matchMemberList;

@property (nonatomic, strong) NSMutableArray <NSMutableArray *>*mutableMemberDataSource;
@property (nonatomic, strong) NSMutableArray <NSMutableArray *>*matchMemberDataSource;
@property (nonatomic, strong) NSMutableArray <NSMutableArray *>*dataSource;

@property (nonatomic, strong) NCSearchBarViewModel *searchBarVM;

@property (nonatomic, strong) NCUIPagingQueryResult<NCGroupMemberInfo *> *queryResult;

@property (nonatomic, strong) NCSearchGroupMembersQuery *searchMembersQuery;

@property (nonatomic, assign) NSInteger loadedSearchMemberCount;

@property (nonatomic, assign) BOOL hasMoreSearchMembers;

@property (nonatomic, weak) id<NCListViewModelResponder> responder;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, assign) BOOL isLoadingMembers;

@property (nonatomic, assign) BOOL isLoadingSearchMembers;

@property (nonatomic, weak) NCBaseCellViewModel *lastBottomCellVM;

@property (nonatomic, strong) NCGroupMemberCellViewModel *mentionAllCellVM;

@property (nonatomic, copy) void (^selectedBlock)(NCChatUIUserInfo *selectedUserInfo);
@property (nonatomic, copy) void (^cancelBlock)(void);
@end

@implementation NCGroupMentionViewModel
@dynamic delegate;

+ (instancetype)viewModelWithGroupId:(NSString *)groupId
                       selectedBlock:(void (^)(NCChatUIUserInfo *selectedUserInfo))selectedBlock
                              cancel:(void (^)(void))cancelBlock{
    NCGroupMentionViewModel *viewModel = [[self.class alloc] init];
    viewModel.groupId = groupId;
    viewModel.selectedBlock = selectedBlock;
    viewModel.cancelBlock = cancelBlock;
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
    return self.searchBarVM.searchBar;
}

- (NCSearchBarViewModel *)searchBarVM {
    if (!_searchBarVM) {
        _searchBarVM =  [[NCSearchBarViewModel alloc] init];
        _searchBarVM.delegate = self;
    }
    return _searchBarVM;
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

- (void)selectionCanceled {
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

#pragma mark - NCSearchBarViewModelDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchMembersQuery = nil;
    self.loadedSearchMemberCount = 0;
    self.hasMoreSearchMembers = YES;
    [self.matchMemberList removeAllObjects];
    if (searchText.length == 0) {
        [self removeSeparatorWithArray:self.memberList];
        [self reloadData:NO];
    } else {
        [self filterDataSource];
    }
}

- (void)searchBar:(UISearchBar *)searchBar editingStateChanged:(BOOL)inSearching {
    if (!inSearching) {
        [self endEditingState];
        [self reloadData:NO];
    }
}

- (void)reloadData:(BOOL)empty {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        [self.responder reloadData:empty];
    }

}
#pragma mark -- NCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCGroupMemberCell class]
      forCellReuseIdentifier:NCGroupMemberCellIdentifier];
}

- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    NCGroupMemberCellViewModel *cellViewModel = [self memberAtIndexPath:indexPath];
    if (self.selectedBlock) {
        NCChatUIUserInfo *info = [NCChatUIUserInfo new];
        info.userId = cellViewModel.memberInfo.userId;
        info.name = cellViewModel.memberInfo.nickname.length > 0 ? cellViewModel.memberInfo.nickname : cellViewModel.memberInfo.name;
        info.avatarUrl = cellViewModel.memberInfo.avatarUrl;
        self.selectedBlock(info);
    }
}

- (NSInteger)numberOfSections {
    return self.dataSource.count;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    if (self.dataSource.count > section) {
        NSArray *array = self.dataSource[section];
        return array.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCGroupMemberCellViewModel *vm = [self memberAtIndexPath:indexPath];
    return [vm tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCGroupMemberCellViewModel *vm = [self memberAtIndexPath:indexPath];
    return [vm tableView:tableView heightForRowAtIndexPath:indexPath];;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [UIView new];
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section {
    return section == 0 ? 0.01: 20;
}
#pragma mark -- private
- (NCGroupMemberCellViewModel *)memberAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *array = self.dataSource[indexPath.section];
    if (array.count> indexPath.row) {
        NCGroupMemberCellViewModel *vm = array[indexPath.row];
        return vm;
    }
    return nil;
}

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
            // Clear the search loading state.
            self.isLoadingSearchMembers = NO;
            return;
        }
        NSArray<NCGroupMemberInfo *> *memberList = members ?: @[];
        self.loadedSearchMemberCount += memberList.count;
        self.hasMoreSearchMembers = [self searchHasMoreWithCurrentPageCount:memberList.count];
        NSArray *list = [self getViewModelsWithMembers:memberList];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Clear the search loading state and update the data.
            self.isLoadingSearchMembers = NO;
            [self.matchMemberList addObjectsFromArray:list];
            [self removeSeparatorWithArray:list];
            [self reloadData:self.matchMemberList.count == 0];
        });
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
        
        NSArray *list = [self getViewModelsWithMembers:result.data];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Clear the loading state and update the data.
            self.isLoadingMembers = NO;
            self.queryResult = result;
            [self.mutableMemberList addObjectsFromArray:list];
            [self removeSeparatorWithArray:list];
            [self.responder reloadData:NO];
        });
    }];
}

- (NSArray<NCGroupMemberCellViewModel *> *)getViewModelsWithMembers:(NSArray<NCGroupMemberInfo *> *)members {
    NSMutableArray *list = [NSMutableArray array];
    for (NCGroupMemberInfo *member in members) {
        member.role = NCGroupMemberRoleUndef;
        NCGroupMemberCellViewModel *cellVM = [[NCGroupMemberCellViewModel alloc] initWithMember:member];
        cellVM.hiddenArrow = YES;
        [list addObject:cellVM];
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

- (NSMutableArray<NSMutableArray *> *)mutableMemberDataSource {
    if (!_mutableMemberDataSource) {
        _mutableMemberDataSource = [NSMutableArray array];
        if (self.mentionAllCellVM) {
            NSMutableArray *array = [NSMutableArray array];
            [array addObject:self.mentionAllCellVM];
            [_mutableMemberDataSource addObject:array];
        }
        if (self.mutableMemberList) {
            [_mutableMemberDataSource addObject:self.mutableMemberList];
        }
    }
    return _mutableMemberDataSource;
}

- (NSMutableArray<NSMutableArray *> *)matchMemberDataSource {
    if (!_matchMemberDataSource) {
        _matchMemberDataSource = [NSMutableArray array];
       
        if (self.matchMemberList) {
            [_matchMemberDataSource addObject:self.matchMemberList];
        }
    }
    return _matchMemberDataSource;
}

- (NSMutableArray<NSMutableArray *> *)dataSource {
    if (self.searchBarVM.searchBar.text.length > 0) {
        return self.matchMemberDataSource;
    }
    return self.mutableMemberDataSource;
}

- (NCGroupMemberCellViewModel *)mentionAllCellVM {
    if (!_mentionAllCellVM) {
        NCGroupMemberInfo *all = [[NCGroupMemberInfo alloc] init];
        all.userId = NCMentionAllUsersID;
        all.name = NCUILocalizedString(@"group_mention_all");
        all.role = NCGroupMemberRoleUndef;
        _mentionAllCellVM = [[NCGroupMemberCellViewModel alloc] initWithMember:all];
        _mentionAllCellVM.hiddenArrow = YES;
        _mentionAllCellVM.hideSeparatorLine = YES;
        _mentionAllCellVM.cellPortraitImage = NCDynamicImage(@"group_mention_all_img");
        _mentionAllCellVM.remark = NCUILocalizedString(@"group_mention_all");
    }
    return _mentionAllCellVM;
}

@end
