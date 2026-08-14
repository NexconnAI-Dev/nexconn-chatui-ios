//
//  NCGroupManagementViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupManagementViewModel.h"
#import "NCProfileSwitchCellViewModel.h"
#import "NCProfileCommonCellViewModel.h"
#import "NCProfileCommonSwitchCell.h"
#import "NCGroupManager.h"
#import "NCChatUICommonDefine.h"
#import "NCSelectGroupMemberViewController.h"
#import "NCAlertView.h"
#import "NCActionSheetView.h"
#import "NCGroupManagerListController.h"
#import "NCGroupTransferViewController.h"
#import "NCChatUIErrorCode.h"

static BOOL NCGroupManagementOperationInvalidatesCurrentUser(NCGroupOperationEvent *event) {
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

@interface NCGroupManagementViewModel ()<NCGroupChannelHandler>
@property (nonatomic, copy) NSString *groupId;
@property (nonatomic, strong) NSArray<NSArray <NCBaseCellViewModel *>*> *dataSources;
@property (nonatomic, weak) id<NCListViewModelResponder> responder;
@property (nonatomic, copy) NSString *groupEventHandlerId;
@end

@implementation NCGroupManagementViewModel
@dynamic delegate;
+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    NCGroupManagementViewModel *viewModel = [NCGroupManagementViewModel new];
    viewModel.groupId = groupId;
    viewModel.groupEventHandlerId = [NSString stringWithFormat:@"nc.group.management.%p", viewModel];
    [NCEngine addGroupChannelHandlerWithIdentifier:viewModel.groupEventHandlerId handler:viewModel];
    return viewModel;
}

- (void)dealloc {
    [NCEngine removeGroupChannelHandlerForIdentifier:self.groupEventHandlerId];
}

- (void)fetchDataSources {
    if (self.groupId.length == 0) {
        return;
    }
    [NCGroupChannel getGroupsInfoWithGroupIds:@[self.groupId] completion:^(NSArray<NCGroupInfo *> * _Nullable groupInfos, NCError * _Nullable error) {
        if (error) {
            return;
        }
        if (groupInfos.firstObject && (groupInfos.firstObject.role == NCGroupMemberRoleOwner || groupInfos.firstObject.role == NCGroupMemberRoleAdmin)) {
            [self reloadDataSources:groupInfos.firstObject];
        }
    }];
}

- (void)bindResponder:(id<NCListViewModelResponder>)responder {
    self.responder = responder;
}

#pragma mark -- NCGroupChannelHandler

- (void)onGroupInfoChanged:(NCGroupInfoChangedEvent *)event {
    if ([event.groupInfo.groupId isEqualToString:self.groupId]) {
        [self fetchDataSources];
    }
}

- (void)onGroupOperation:(NCGroupOperationEvent *)event {
    if ([event.groupId isEqualToString:self.groupId]) {
        if (NCGroupManagementOperationInvalidatesCurrentUser(event)) {
            [self p_leaveForInvalidGroupOperation];
        } else {
            [self fetchDataSources];
        }
    }
}

- (void)p_leaveForInvalidGroupOperation {
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

#pragma mark -- NCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [NCProfileCommonCellViewModel registerCellForTableView:tableView];
    [tableView registerClass:NCProfileCommonSwitchCell.class forCellReuseIdentifier:NCProfileCommonSwitchCellIdentifier];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    NCBaseCellViewModel *cellViewModel = self.dataSources[indexPath.section][indexPath.row];
    if ([self.delegate respondsToSelector:@selector(groupManagement:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate groupManagement:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }
    if (![cellViewModel isKindOfClass:NCProfileCommonCellViewModel.class]) {
        return;
    }
    NCProfileCommonCellViewModel *commonCellVM = (NCProfileCommonCellViewModel *)cellViewModel;
    if ([commonCellVM.title isEqualToString:NCUILocalizedString(@"group_manager_title")]) {
        NCGroupManagerListViewModel *viewModel = [NCGroupManagerListViewModel viewModelWithGroupId:self.groupId];
        NCGroupManagerListController *vc = [[NCGroupManagerListController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:vc animated:YES];
    } else if ([commonCellVM.title isEqualToString:NCUILocalizedString(@"set_group_info_edit_per")]) {
        [self setGroupInfoPermission];
    } else if ([commonCellVM.title isEqualToString:NCUILocalizedString(@"set_add_group_member_per")]) {
        [self setAddGroupMemberPermission];
    } else if ([commonCellVM.title isEqualToString:NCUILocalizedString(@"set_remove_group_member_per")]) {
        [self setRemoveGroupMemberPermission];
    } else if ([commonCellVM.title isEqualToString:NCUILocalizedString(@"set_group_member_info_edit_per")]) {
        [self setGroupMemberInfoPermission];
    } else if ([commonCellVM.title isEqualToString:NCUILocalizedString(@"group_transfer")]) {
        NCGroupTransferViewModel *viewModel = [NCGroupTransferViewModel viewModelWithGroupId:self.groupId];
        NCGroupTransferViewController *vc = [[NCGroupTransferViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:vc animated:YES];
    }
}

- (NSInteger)numberOfSections {
    return self.dataSources.count;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return self.dataSources[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSources[indexPath.section][indexPath.row] tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSources[indexPath.section][indexPath.row] tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark -- private

- (void)reloadDataSources:(NCGroupInfo *)group {
    NSMutableArray *list = [NSMutableArray array];
    NCProfileCommonCellViewModel *adminVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"group_manager_title") detail:nil];
    [list addObject:@[adminVM]];
    if (group.role == NCGroupMemberRoleOwner) {
        NCProfileCommonCellViewModel *groupInfoEditPerVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"set_group_info_edit_per") detail:[self groupOperationPerStr:group.groupInfoEditPermission]];
        NCProfileCommonCellViewModel *addGroupMemberPerVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"set_add_group_member_per") detail:[self groupOperationPerStr:group.invitePermission]];
        NCProfileCommonCellViewModel *removeGroupMemberPerVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"set_remove_group_member_per") detail:[self groupOperationPerStr:group.removeMemberPermission]];
        NCProfileCommonCellViewModel *memberInfoEditPerVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"set_group_member_info_edit_per") detail:[self getMemberInfoPerStr:group.memberInfoEditPermission]];
        [list addObject:@[groupInfoEditPerVM, addGroupMemberPerVM, removeGroupMemberPerVM, memberInfoEditPerVM]];
        
        NCProfileSwitchCellViewModel *inviteVM = [NCProfileSwitchCellViewModel new];
        inviteVM.title = NCUILocalizedString(@"invite_group_confirm");
        inviteVM.switchOn = group.joinPermission == NCGroupJoinPermissionFree ? NO : YES;
        __weak typeof(self) weakSelf = self;
        [inviteVM setSwitchValueChanged:^(BOOL on) {
            [weakSelf updateGroupJoinPermission:on];
        }];
        [list addObject:@[inviteVM]];

        
        NCProfileCommonCellViewModel *groupTransferVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"group_transfer") detail:nil];
        [list addObject:@[groupTransferVM]];
    }

    if ([self.delegate respondsToSelector:@selector(groupManagement:willLoadItemsInDataSource:)]) {
        list = [self.delegate groupManagement:self willLoadItemsInDataSource:list].mutableCopy;
    }
    [self removeSeparatorLineIfNeed:list];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataSources = list;
        [self.responder reloadData:self.dataSources.count == 0];
    });
}

- (void)updateGroupJoinPermission:(BOOL)open {
    NCUpdateGroupInfoParams *params = [NCUpdateGroupInfoParams new];
    params.joinPermissionValue = @(open ? NCGroupJoinPermissionOwnerOrAdminVerify : NCGroupJoinPermissionFree);
    [self updateGroupInfo:params reloadWithFailed:YES];
}

- (NSString *)groupOperationPerStr:(NCGroupOperationPermission)permisson {
    switch (permisson) {
        case NCGroupOperationPermissionOwner:
            return NCUILocalizedString(@"only_group_owner_operation");
        case NCGroupOperationPermissionOwnerOrAdmin:
            return NCUILocalizedString(@"group_owner_or_manager_operation");
        case NCGroupOperationPermissionEveryone:
            return NCUILocalizedString(@"all_group_member_operation");
        default:
            return @"";
    }
}

- (NSString *)getMemberInfoPerStr:(NCGroupMemberInfoEditPermission)permisson {
    switch (permisson) {
        case NCGroupMemberInfoEditPermissionOwnerOrAdminOrSelf:
            return NCUILocalizedString(@"group_member_info_edit_owner_or_admin_or_self");
        case NCGroupMemberInfoEditPermissionOwnerOrSelf:
            return NCUILocalizedString(@"group_member_info_edit_owner_or_self");
        case NCGroupMemberInfoEditPermissionSelfOnly:
            return NCUILocalizedString(@"group_member_info_edit_self_only");
        default:
            return @"";
    }
}

- (void)setGroupInfoPermission {
    NSArray *permissonStrs = @[NCUILocalizedString(@"only_group_owner_operation"), NCUILocalizedString(@"group_owner_or_manager_operation"), NCUILocalizedString(@"all_group_member_operation")];
    [NCActionSheetView showActionSheetView:nil cellArray:permissonStrs cancelTitle:NCUILocalizedString(@"cancel") selectedBlock:^(NSInteger index) {
        if (index < 0 || index >= (NSInteger)permissonStrs.count) {
            return;
        }
        NCUpdateGroupInfoParams *params = [NCUpdateGroupInfoParams new];
        params.groupInfoEditPermissionValue = @((NCGroupOperationPermission)index);
        [self updateGroupInfo:params reloadWithFailed:NO];
    } cancelBlock:^{
        
    }];
}

- (void)setAddGroupMemberPermission {
    NSArray *permissonStrs = @[NCUILocalizedString(@"only_group_owner_operation"), NCUILocalizedString(@"group_owner_or_manager_operation"), NCUILocalizedString(@"all_group_member_operation")];
    [NCActionSheetView showActionSheetView:nil cellArray:permissonStrs cancelTitle:NCUILocalizedString(@"cancel") selectedBlock:^(NSInteger index) {
        if (index < 0 || index >= (NSInteger)permissonStrs.count) {
            return;
        }
        NCUpdateGroupInfoParams *params = [NCUpdateGroupInfoParams new];
        params.invitePermissionValue = @((NCGroupOperationPermission)index);
        [self updateGroupInfo:params reloadWithFailed:NO];
    } cancelBlock:^{
        
    }];
}

- (void)setRemoveGroupMemberPermission {
    NSArray *permissonStrs = @[NCUILocalizedString(@"only_group_owner_operation"), NCUILocalizedString(@"group_owner_or_manager_operation"), NCUILocalizedString(@"all_group_member_operation")];
    [NCActionSheetView showActionSheetView:nil cellArray:permissonStrs cancelTitle:NCUILocalizedString(@"cancel") selectedBlock:^(NSInteger index) {
        if (index < 0 || index >= (NSInteger)permissonStrs.count) {
            return;
        }
        NCUpdateGroupInfoParams *params = [NCUpdateGroupInfoParams new];
        params.removeMemberPermissionValue = @((NCGroupOperationPermission)index);
        [self updateGroupInfo:params reloadWithFailed:NO];
    } cancelBlock:^{
        
    }];
}

- (void)setGroupMemberInfoPermission {
    NSArray *permissonStrs = @[
        NCUILocalizedString(@"group_member_info_edit_owner_or_admin_or_self"),
        NCUILocalizedString(@"group_member_info_edit_owner_or_self"),
        NCUILocalizedString(@"group_member_info_edit_self_only")
    ];
    [NCActionSheetView showActionSheetView:nil cellArray:permissonStrs cancelTitle:NCUILocalizedString(@"cancel") selectedBlock:^(NSInteger index) {
        if (index < 0 || index >= (NSInteger)permissonStrs.count) {
            return;
        }
        NCUpdateGroupInfoParams *params = [NCUpdateGroupInfoParams new];
        params.memberInfoEditPermissionValue = @((NCGroupMemberInfoEditPermission)index);
        [self updateGroupInfo:params reloadWithFailed:NO];
    } cancelBlock:^{
        
    }];
}

- (void)updateGroupInfo:(NCUpdateGroupInfoParams *)params reloadWithFailed:(BOOL)reloadWithFailed{
    [self loadingWithTip:NCUILocalizedString(@"saving")];
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId ?: @""];
    if (!channel) {
        [self stopLoading];
        return;
    }
    [channel updateInfoWithParams:params completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        if (!error) {
        [self stopLoading];
        [self fetchDataSources];
        dispatch_async(dispatch_get_main_queue(), ^{
            [NCAlertView showAlertController:nil message:NCUILocalizedString(@"set_success") hiddenAfterDelay:1];
        });
            return;
        }
        [self stopLoading];
        if (reloadWithFailed) {
            [self fetchDataSources];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *tips = NCUILocalizedString(@"set_failed");
            if (error.code == NCChatUIErrorCodeInformationAuditFailed) {
                tips = NCUILocalizedString(@"content_contains_sensitive");
            }
            [NCAlertView showAlertController:nil message:tips hiddenAfterDelay:1];
        });
    }];
}
@end
