//
//  NCGroupProfileViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupProfileViewModel.h"
#import "NCProfileCommonCellViewModel.h"
#import "NCProfileCommonTextCell.h"
#import "NCProfileCommonImageCell.h"
#import "NCGroupProfileMembersCell.h"
#import "NCGroupProfileMembersCellViewModel.h"
#import "NCGroupMembersCollectionViewModel.h"
#import "NCNameEditViewController.h"
#import "NCGroupMemberListViewController.h"
#import "NCGroupManager.h"
#import "NCGroupNoticeViewController.h"
#import "NCProfileCommonSwitchCell.h"
#import "NCProfileSwitchCellViewModel.h"
#import "NCProfileViewModel+private.h"
#import "NCChatUICommonDefine.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCAlertView.h"
#import "NCGroupFollowsViewController.h"
#import "NCGroupManagementViewController.h"

static NSString *NCGroupProfileCurrentUserId(void) {
    return [NCEngine getCurrentUserId] ?: @"";
}

static BOOL NCGroupProfileOperationInvalidatesCurrentUser(NCGroupOperationEvent *event) {
    if (event.operation == NCGroupOperationDismiss) {
        return YES;
    }
    if (event.operation != NCGroupOperationKick && event.operation != NCGroupOperationQuit) {
        return NO;
    }
    NSString *currentUserId = NCGroupProfileCurrentUserId();
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

@interface NCGroupProfileViewModel ()<NCGroupChannelHandler, NCChannelHandler>

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, strong) NCGroupProfileMembersCellViewModel *membersViewModel;

@property (nonatomic, strong) NCGroupInfo *group;

@property (nonatomic, assign) BOOL showGroupFollowsCell;
@property (nonatomic, copy) NSString *groupEventHandlerId;
@property (nonatomic, copy) NSString *channelEventHandlerId;

- (void)p_leaveProfileForInvalidGroupOperation;

@end

@implementation NCGroupProfileViewModel
+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    NCGroupProfileViewModel *viewModel = [[self.class alloc] init];
    viewModel.groupId = groupId;
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.displayMaxMemberCount = 30;
        self.groupEventHandlerId = [NSString stringWithFormat:@"nc.group.profile.group.%p", self];
        self.channelEventHandlerId = [NSString stringWithFormat:@"nc.group.profile.channel.%p", self];
        [NCEngine addGroupChannelHandlerWithIdentifier:self.groupEventHandlerId handler:self];
        [NCEngine addChannelHandlerWithIdentifier:self.channelEventHandlerId handler:self];
    }
    return self;
}

- (void)dealloc {
    [NCEngine removeGroupChannelHandlerForIdentifier:self.groupEventHandlerId];
    [NCEngine removeChannelHandlerForIdentifier:self.channelEventHandlerId];
}

- (void)updateProfile {
    if (self.groupId.length == 0) {
        return;
    }
    
    [self fetchGroupInfo];
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCProfileCommonTextCell class]
      forCellReuseIdentifier:NCProfileTextCellIdentifier];
    [tableView registerClass:[NCProfileCommonImageCell class]
      forCellReuseIdentifier:NCProfileImageCellIdentifier];
    [tableView registerClass:[NCGroupProfileMembersCell class]
      forCellReuseIdentifier:NCGroupProfileMembersCellIdentifier];
    [tableView registerClass:[NCProfileCommonSwitchCell class]
      forCellReuseIdentifier:NCProfileCommonSwitchCellIdentifier];
}

- (void)viewController:(UIViewController *)viewController tableView:(UITableView *)tableView didSelectRow:(NSIndexPath *)indexPath {
    NCProfileCellViewModel *cellViewModel = self.profileList[indexPath.section][indexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(profileViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate profileViewModel:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }
    
    if (![cellViewModel isKindOfClass:NCProfileCommonCellViewModel.class]) {
        return;
    }
    NCProfileCommonCellViewModel *commonCellViewModel = (NCProfileCommonCellViewModel *)cellViewModel;
    if ([commonCellViewModel.title isEqualToString:NCUILocalizedString(@"group_name_title")]) {
        if (![self canEditProfile]) {
            [NCAlertView showAlertController:nil message:NCUILocalizedString(@"no_edit_group_permission") hiddenAfterDelay:1];
            return;
        }
        NCNameEditViewModel *viewModel = [NCNameEditViewModel viewModelWithUserId:NCGroupProfileCurrentUserId() groupId:self.groupId type:NCNameEditTypeGroupName];
        NCNameEditViewController *nameEditVC = [[NCNameEditViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:nameEditVC animated:YES];
    } else if ([commonCellViewModel.title isEqualToString:NCUILocalizedString(@"group_for_my_name")]) {
        NCNameEditViewModel *viewModel = [NCNameEditViewModel viewModelWithUserId:NCGroupProfileCurrentUserId() groupId:self.groupId type:NCNameEditTypeGroupMemberNickname];
        NCNameEditViewController *nameEditVC = [[NCNameEditViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:nameEditVC animated:YES];
    } else if ([commonCellViewModel.title hasPrefix:NCUILocalizedString(@"group_members")]) {
        NCGroupMemberListViewModel *viewModel = [NCGroupMemberListViewModel viewModelWithGroupId:self.groupId];
        NCGroupMemberListViewController *membersVC = [[NCGroupMemberListViewController alloc] initWithViewModel:viewModel];
        membersVC.title = commonCellViewModel.title;
        [viewController.navigationController pushViewController:membersVC animated:YES];
    } else if ([commonCellViewModel.title isEqualToString:NCUILocalizedString(@"group_notice")]) {
        NCGroupNoticeViewModel *viewModel = [[NCGroupNoticeViewModel alloc] initWithGroup:self.group];
        NCGroupNoticeViewController *membersVC = [[NCGroupNoticeViewController alloc] initWithViewModel:viewModel];
        membersVC.title = commonCellViewModel.title;
        [viewController.navigationController pushViewController:membersVC animated:YES];
    } else if ([commonCellViewModel.title hasSuffix:NCUILocalizedString(@"group_follows_cell_title")]) {
        NCGroupFollowsViewModel *viewModel = [NCGroupFollowsViewModel viewModelWithGroupId:self.groupId];
        NCGroupFollowsViewController *vc = [[NCGroupFollowsViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:vc animated:YES];
    } else if ([commonCellViewModel.title isEqualToString:NCUILocalizedString(@"group_management")]) {
        NCGroupManagementViewModel *viewModel = [NCGroupManagementViewModel viewModelWithGroupId:self.groupId];
        NCGroupManagementViewController *vc = [[NCGroupManagementViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark -- NCChannelHandler

- (void)onChannelPinnedSync:(NCChannelPinnedSyncEvent *)event {
    [self updateProfile];
}

- (void)onChannelNoDisturbLevelSync:(NCChannelNoDisturbLevelSyncEvent *)event {
    [self updateProfile];
}

- (void)onChannelTranslateStrategySync:(NCChannelTranslateStrategySyncEvent *)event {
    [self updateProfile];
}

#pragma mark -- NCGroupChannelHandler
- (void)onGroupInfoChanged:(NCGroupInfoChangedEvent *)event {
    if ([event.groupInfo.groupId isEqualToString:self.groupId]) {
        [self updateProfile];
    }
}

- (void)onGroupOperation:(NCGroupOperationEvent *)event {
    if ([event.groupId isEqualToString:self.groupId]) {
        if (NCGroupProfileOperationInvalidatesCurrentUser(event)) {
            [self p_leaveProfileForInvalidGroupOperation];
        } else {
            [self updateProfile];
        }
    }
}

#pragma mark -- private

- (void)p_leaveProfileForInvalidGroupOperation {
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

- (void)fetchGroupInfo {
    [NCGroupChannel getGroupsInfoWithGroupIds:@[self.groupId]
                                   completion:^(NSArray<NCGroupInfo *> * _Nullable groupInfos, NCError * _Nullable error) {
        if (error) {
            return;
        }
        self.group = groupInfos.firstObject;
        [self reloadDataSource:self.group];
        [self fetchMembers:self.group];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder updateTitle:[NSString stringWithFormat: NCUILocalizedString(@"group_profile_title"),@(self.group.membersCount)]];
        });
    }];
}

- (void)fetchMembers:(NCGroupInfo *)group {
    NCUIPagingQueryOption *option = [NCUIPagingQueryOption new];
    option.count = self.displayMaxMemberCount;
    option.order = YES;
    __weak typeof(self) weakSelf = self;
    [NCGroupManager getGroupMemberInfos:self.groupId option:option role:NCGroupMemberRoleUndef complete:^(NCUIPagingQueryResult<NCGroupMemberInfo *> * _Nonnull result) {
        if (!result) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NCGroupMembersCollectionViewModel *membersViewModel = [NCGroupMembersCollectionViewModel viewModelWithGroupId:weakSelf.groupId members:result.data ?: @[] allowAdd:[weakSelf showAdd:group] allowRemove:[weakSelf showRemove:group] inViewController:[weakSelf.responder currentViewController]];
            [weakSelf.membersViewModel configViewModel:membersViewModel];
            [weakSelf.responder reloadData:NO];
        });
    }];
}

- (void)reloadDataSource:(NCGroupInfo *)group {
    NSString *groupId = group.groupId.length > 0 ? group.groupId : self.groupId;
    
    NCProfileCommonCellViewModel *memberVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:[NSString stringWithFormat: NCUILocalizedString(@"group_members_with_count"), @(group.membersCount)] detail:nil];
    memberVM.hideSeparatorLine = YES;
    
    self.membersViewModel = [[NCGroupProfileMembersCellViewModel alloc] initWithItemCount:[self showItemCount:group]];
    
    NCProfileCommonCellViewModel *portraitVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeImage title:NCUILocalizedString(@"group_portrait") detail:group.avatarUrl];
    portraitVM.hiddenArrow = YES;
    portraitVM.channelType = NCChannelTypeGroup;
    NCProfileCommonCellViewModel *nameVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"group_name_title") detail:group.groupName];
    NCProfileCommonCellViewModel *noticeVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"group_notice") detail:nil];
    NCProfileCommonCellViewModel *memberNameVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"group_for_my_name") detail:nil];
    [self showMyNameInGroup:memberNameVM];
    NCProfileSwitchCellViewModel *disturbVM = [self disturbVM];
    NCProfileSwitchCellViewModel *topVM = [self topVM];
    
    NSMutableArray *switchVMList = [NSMutableArray array];
    [switchVMList addObject:disturbVM];
    if (self.showGroupFollowsCell) {
        NCProfileCommonCellViewModel *followsVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:[NSString stringWithFormat:@"    %@", NCUILocalizedString(@"group_follows_cell_title")] detail:nil];
        [switchVMList addObject:followsVM];
    }
    [switchVMList addObject:topVM];
    
    NSArray *list = @[
    @[memberVM, self.membersViewModel],
    @[portraitVM, nameVM, noticeVM, memberNameVM],
    switchVMList
    ];
    
    if (group.role == NCGroupMemberRoleOwner || group.role == NCGroupMemberRoleAdmin) {
        NCProfileCommonCellViewModel *managementVM = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"group_management") detail:nil];
        list = @[
        @[memberVM, self.membersViewModel],
        @[portraitVM, nameVM, noticeVM, memberNameVM],
        @[managementVM],
        switchVMList
        ];
    }
    
    NCProfileFooterViewType type = NCProfileFooterViewTypeGroupMember;
    if ([group.ownerId isEqualToString:NCGroupProfileCurrentUserId()]) {
       type = NCProfileFooterViewTypeGroupOwner;
    }
    
    [self configFooterViewModel:[[NCProfileFooterViewModel alloc] initWithResponder:[self.responder currentViewController] type:type channelId:groupId]];
        
    dispatch_async(dispatch_get_main_queue(), ^{
        self.profileList = list;
        [self.responder reloadData:NO];
    });
}

- (void)showMyNameInGroup:(NCProfileCommonCellViewModel *)memberNameVM {
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId];
    [channel getMembersWithUserIds:@[NCGroupProfileCurrentUserId()]
                        completion:^(NSArray<NCGroupMemberInfo *> * _Nullable groupMembers, NCError * _Nullable error) {
        if (error) {
            return;
        }
        memberNameVM.detail = groupMembers.firstObject.nickname;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder reloadData:NO];
        });
    }];
}

- (NCProfileSwitchCellViewModel *)topVM {
    NCProfileSwitchCellViewModel *topVM = [NCProfileSwitchCellViewModel new];
    topVM.title = NCUILocalizedString(@"set_top");
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId];
    [channel reloadWithCompletion:^(NCBaseChannel * _Nullable latestChannel, NSError * _Nullable error) {
        if (error && !latestChannel) {
            return;
        }
        NCBaseChannel *activeChannel = latestChannel ?: channel;
        dispatch_async(dispatch_get_main_queue(), ^{
            topVM.switchOn = activeChannel.isPinned;
            [self.responder reloadData:NO];
        });
    }];
    __weak typeof(self) weakSelf = self;
    topVM.switchValueChanged = ^(BOOL on) {
        NCGroupChannel *activeChannel = [[NCGroupChannel alloc] initWithChannelId:weakSelf.groupId];
        if (on) {
            NCPinParams *params = [[NCPinParams alloc] initWithUpdateOperationTime:NO];
            [activeChannel pinWithParams:params completion:^(NCError * _Nullable error) {
            }];
        } else {
            [activeChannel unpinWithCompletion:^(NCError * _Nullable error) {
            }];
        }
    };
    return topVM;
}

- (NCProfileSwitchCellViewModel *)disturbVM {
    NCProfileSwitchCellViewModel *disturbVM = [NCProfileSwitchCellViewModel new];
    disturbVM.title = NCUILocalizedString(@"set_not_disturb");
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId];
    [channel reloadWithCompletion:^(NCBaseChannel * _Nullable latestChannel, NSError * _Nullable error) {
        if (error && !latestChannel) {
            return;
        }
        NCBaseChannel *activeChannel = latestChannel ?: channel;
        dispatch_async(dispatch_get_main_queue(), ^{
            disturbVM.switchOn = activeChannel.noDisturbLevel == NCChannelNoDisturbLevelMuted;
            [self showGroupFollows:disturbVM.switchOn];
            [self.responder reloadData:NO];
        });
    }];
    __weak typeof(self) weakSelf = self;
    disturbVM.switchValueChanged = ^(BOOL on) {
        NCGroupChannel *activeChannel = [[NCGroupChannel alloc] initWithChannelId:weakSelf.groupId];
        [activeChannel setNoDisturbLevel:(on ? NCChannelNoDisturbLevelMuted : NCChannelNoDisturbLevelAllMessage) completion:^(NCError * _Nullable error) {
            if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showGroupFollows:on];
            });
            } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.responder reloadData:NO];
            });
            }
        }];
    };
    return disturbVM;
}

- (void)showGroupFollows:(BOOL)show {
    if (self.showGroupFollowsCell != show) {
        self.showGroupFollowsCell = show;
        [self reloadDataSource:self.group];
    }
}

- (NSInteger)showItemCount:(NCGroupInfo *)group {
    NSInteger count = (group.membersCount <= self.displayMaxMemberCount ? group.membersCount : self.displayMaxMemberCount);
    if ([self showAdd:group]) {
        count += 1;
    }
    if ([self showRemove:group]) {
        count += 1;
    }
    return count;
}

- (BOOL)showAdd:(NCGroupInfo *)group {
    if (group.invitePermission == NCGroupOperationPermissionOwner && group.role == NCGroupMemberRoleOwner) {
        return YES;
    }
    
    if (group.invitePermission == NCGroupOperationPermissionOwnerOrAdmin && (group.role == NCGroupMemberRoleOwner || group.role ==  NCGroupMemberRoleAdmin)) {
        return YES;
    }
    
    if (group.invitePermission == NCGroupOperationPermissionEveryone) {
        return YES;
    }
    return NO;
}

- (BOOL)showRemove:(NCGroupInfo *)group {
    if (group.removeMemberPermission == NCGroupOperationPermissionOwner && group.role == NCGroupMemberRoleOwner) {
        return YES;
    }
    
    if (group.removeMemberPermission == NCGroupOperationPermissionOwnerOrAdmin && (group.role == NCGroupMemberRoleOwner || group.role ==  NCGroupMemberRoleAdmin)) {
        return YES;
    }
    
    if (group.removeMemberPermission == NCGroupOperationPermissionEveryone) {
        return YES;
    }
    return NO;
}


- (BOOL)canEditProfile {
    if (self.group.groupInfoEditPermission == NCGroupOperationPermissionOwner && self.group.role == NCGroupMemberRoleOwner) {
        return YES;
    }
    if (self.group.groupInfoEditPermission == NCGroupOperationPermissionOwnerOrAdmin && (self.group.role == NCGroupMemberRoleOwner || self.group.role == NCGroupMemberRoleAdmin)) {
        return YES;
    }
    if (self.group.groupInfoEditPermission == NCGroupOperationPermissionEveryone) {
        return YES;
    }
    return NO;
}

#pragma mark -- setter

- (void)setDisplayMaxMemberCount:(NSInteger)displayMaxMemberCount {
    // Clamp the value to the supported range of 5 through 50.
    if (displayMaxMemberCount < 5 || displayMaxMemberCount > 50) {
        return;
    }
    _displayMaxMemberCount = displayMaxMemberCount;
}

@end
