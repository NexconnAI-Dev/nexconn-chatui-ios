//
//  NCGroupManagersViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupManagerListViewModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCGroupFollowCellViewModel.h"
#import "NCGroupManager.h"
#import "NCChatUICommonDefine.h"
#import "NCSelectGroupMemberViewController.h"
#import "NCGroupMemberAdditionalCellViewModel.h"
#import "NCAlertView.h"
#import "NCChatUI.h"

static BOOL NCGroupManagerListOperationInvalidatesCurrentUser(NCGroupOperationEvent *event) {
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

@interface NCGroupManagerListViewModel ()<NCGroupFollowCellViewModelDelegate, NCGroupChannelHandler>
@property (nonatomic, copy) NSString *groupId;
@property (nonatomic, strong) NSArray <NSArray <NCBaseCellViewModel *>*> *dataSources;
@property (nonatomic, strong) NSArray *adminIdList;
@property (nonatomic, weak) id<NCListViewModelResponder> responder;
@property (nonatomic, copy) NSString *groupEventHandlerId;
@end

@implementation NCGroupManagerListViewModel
@dynamic delegate;
+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    NCGroupManagerListViewModel *viewModel = [NCGroupManagerListViewModel new];
    viewModel.groupId = groupId;
    viewModel.groupEventHandlerId = [NSString stringWithFormat:@"nc.group.admin.list.%p", viewModel];
    [NCEngine addGroupChannelHandlerWithIdentifier:viewModel.groupEventHandlerId handler:viewModel];
    return viewModel;
}

- (void)dealloc {
    [NCEngine removeGroupChannelHandlerForIdentifier:self.groupEventHandlerId];
}

- (void)fetchGroupAdmins {
    NCUIPagingQueryOption *option = [NCUIPagingQueryOption new];
    option.count = 100;
    option.order = YES;
    [NCGroupManager getGroupMemberInfos:self.groupId option:option role:NCGroupMemberRoleAdmin complete:^(NCUIPagingQueryResult<NCGroupMemberInfo *> * _Nullable result) {
        if (!result) {
            return;
        }
        [self reloadGroupMemberData:result.data];
    }];
}

- (void)bindResponder:(id<NCListViewModelResponder>)responder {
    self.responder = responder;
}

#pragma mark -- NCGroupChannelHandler

- (void)onGroupOperation:(NCGroupOperationEvent *)event {
    if ([event.groupId isEqualToString:self.groupId]) {
        if (NCGroupManagerListOperationInvalidatesCurrentUser(event)) {
            [self p_leaveForInvalidGroupOperation];
        } else {
            [self fetchGroupAdmins];
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


#pragma mark -- NCGroupFollowCellViewModelDelegate

- (void)actionButtonDidClick:(NCGroupFollowCellViewModel *)cellViewModel {
    if ([self.delegate respondsToSelector:@selector(groupAdminsWillRemove:removeUserIds:viewController:)]) {
        BOOL intercept = [self.delegate groupAdminsWillRemove:self.groupId removeUserIds:@[cellViewModel.memberInfo.userId] viewController:[self.responder currentViewController]];
        if (intercept) {
            return;
        }
    }
    NSString *name;
    if (cellViewModel.remark.length > 0) {
        name = cellViewModel.remark;
    } else if (cellViewModel.memberInfo.nickname.length > 0) {
        name = cellViewModel.memberInfo.nickname;
    } else {
        name = cellViewModel.memberInfo.name;
    }
    NSString *message = [NSString stringWithFormat:NCUILocalizedString(@"remove_group_admins_alert"), name];
    [NCAlertView showAlertController:nil message:message actionTitles:nil cancelTitle:NCUILocalizedString(@"cancel") confirmTitle:NCUILocalizedString(@"confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
        NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId ?: @""];
        [channel removeAdminsWithUserIds:@[cellViewModel.memberInfo.userId ?: @""] completion:^(NCError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NCAlertView showAlertController:nil message:NCUILocalizedString(@"remove_failed") hiddenAfterDelay:1];
                });
                return;
            }
            [self fetchGroupAdmins];
            if ([self.delegate respondsToSelector:@selector(groupAdminsDidRemove:removeUserIds:viewController:)]) {
                BOOL intercept = [self.delegate groupAdminsDidRemove:self.groupId removeUserIds:@[cellViewModel.memberInfo.userId] viewController:[self.responder currentViewController]];
                if (intercept) {
                    return;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"remove_success") hiddenAfterDelay:1];
            });
        }];
    } inViewController:[self.responder currentViewController]];
}

#pragma mark -- NCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [NCGroupFollowCellViewModel registerCellForTableView:tableView];
    [NCGroupMemberAdditionalCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    NCBaseCellViewModel *cellViewModel = self.dataSources[indexPath.section][indexPath.row];
    if ([self.delegate respondsToSelector:@selector(groupAdmins:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate groupAdmins:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }
    if (![cellViewModel isKindOfClass:NCGroupMemberAdditionalCellViewModel.class]) {
        return;
    }
    NCGroupMemberAdditionalCellViewModel *commonCellVM = (NCGroupMemberAdditionalCellViewModel *)cellViewModel;
    if ([commonCellVM.title isEqualToString:NCUILocalizedString(@"add_group_managers")]) {
        [self pushSelectVC:viewController];
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
- (void)reloadGroupMemberData:(NSArray<NCGroupMemberInfo *> *)members {
    if (members.count == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSources = nil;
            [self.responder reloadData:YES];
        });
    }
    NSMutableArray *idList = [NSMutableArray new];
    for (NCGroupMemberInfo *member in members) {
        if (member.userId) {
            [idList addObject:member.userId];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.adminIdList = idList.copy;
    });
    [NCGroupManager fetchFriendInfosWithUserIds:idList complete:^(NSArray<NCFriendInfo *> * _Nullable friendInfos) {
        [self reloadDataSources:members friends:friendInfos];
    }];
}
   
- (void)reloadDataSources:(NSArray<NCGroupMemberInfo *> *)members friends:(NSArray<NCFriendInfo *> *)friends {
    [NCGroupChannel getGroupsInfoWithGroupIds:@[self.groupId] completion:^(NSArray<NCGroupInfo *> * _Nullable groupInfos,
                                                                           NCError * _Nullable error) {
        if (error || groupInfos.count == 0) {
            return;
        }
        NCGroupInfo *groupInfo = groupInfos.firstObject;
        NSMutableArray *adminsList = [NSMutableArray array];
        for (NCGroupMemberInfo *member in members) {
            NCGroupFollowCellViewModel *cellVM = [[NCGroupFollowCellViewModel alloc] initWithMember:member];
            cellVM.delegate = self;
            cellVM.hiddenButton = (groupInfo.role == NCGroupMemberRoleOwner ? NO : YES);
            if (friends.count > 0) {
                cellVM.remark = [NCGroupManager friendWithUserId:member.userId inFriendInfos:friends].remark;
            }
            [adminsList addObject:cellVM];
        }
        NSMutableArray *addList = [NSMutableArray array];
        if (groupInfo.role == NCGroupMemberRoleOwner) {
            UIImage *image = NCDynamicImage(@"group_manage_add_member_img");
            NCGroupMemberAdditionalCellViewModel *addVM = [[NCGroupMemberAdditionalCellViewModel alloc] initWithTitle:NCUILocalizedString(@"add_group_managers")
                                                                                                             portrait:image];
            [addList addObject:addVM];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (addList.count > 0) {
                self.dataSources = @[addList, adminsList];
            } else {
                self.dataSources = @[adminsList];
            }
            
            if (adminsList.count == 0) {
                [self removeSeparatorLineIfNeed:@[addList]];
            } else {
                [self removeSeparatorLineIfNeed:@[adminsList]];
            }
            
            [self.responder reloadData:adminsList.count == 0];
        });
    }];
    
}

- (void)pushSelectVC:(UIViewController *)viewController {
    NCSelectGroupMemberViewModel *viewModel = [NCSelectGroupMemberViewModel viewModelWithGroupId:self.groupId existingUserIds:self.adminIdList];
    viewModel.hideUserIds = @[[NCEngine getCurrentUserId]];
    NSInteger maxAdminLimit = 10;
    viewModel.maxSelectCount = 10 - self.adminIdList.count;
    viewModel.tip = [NSString stringWithFormat:NCUILocalizedString(@"group_member_select_max_tip"), @(maxAdminLimit)];
    __weak typeof(self) weakSelf = self;
    [viewModel setSelectionDidCompelteBlock:^(NSArray<NSString *> * _Nonnull selectUserIds, UIViewController * _Nonnull selectVC) {
        NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:weakSelf.groupId ?: @""];
        [channel addAdminsWithUserIds:selectUserIds completion:^(NCError * _Nullable error) {
            if (error) {
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"add_failed") hiddenAfterDelay:1];
                return;
            }
            [self fetchGroupAdmins];
            if ([self.delegate respondsToSelector:@selector(groupAdminsDidAdd:addUserIds:viewController:)]) {
                BOOL intercept = [self.delegate groupAdminsDidAdd:self.groupId addUserIds:selectUserIds viewController:[self.responder currentViewController]];
                if (intercept) {
                    return;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [selectVC.navigationController popViewControllerAnimated:YES];
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"add_success") hiddenAfterDelay:1];
            });
        }];
    }];
    NCSelectGroupMemberViewController *vc = [[NCSelectGroupMemberViewController alloc] initWithViewModel:viewModel];
    vc.title = NCUILocalizedString(@"select_group_member_vc_title");
    [viewController.navigationController pushViewController:vc animated:YES];
}

- (void)getNamesString:(NSArray *)userIds complete:(void(^)(NSString *names))complete {
    [NCGroupManager getGroupMemberInfos:self.groupId userIds:userIds complete:^(NSArray<NCGroupMemberInfo *> * _Nullable groupMembers) {
        if (!groupMembers) {
            return;
        }
        [NCGroupManager fetchFriendInfosWithUserIds:userIds complete:^(NSArray<NCFriendInfo *> * _Nullable friendInfos) {
            NSMutableArray *names = [NSMutableArray array];
            for (NCGroupMemberInfo *member in groupMembers) {
                NSString *name = [NCGroupManager friendWithUserId:member.userId inFriendInfos:friendInfos].remark;
                if (name.length > 0) {
                    [names addObject:name];
                    continue;
                }
                if (member.nickname.length > 0) {
                    name = member.nickname;
                } else if (member.name.length > 0) {
                    name = member.name;
                } else {
                    name = member.userId;
                }
                [names addObject:name];
            }
            NSString *separator = NCUILocalizedString(@"group_member_name_list_separator");
            NSString *namesStr = [names componentsJoinedByString:separator];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) {
                    complete(namesStr);
                }
            });
        }];
    }];
}
@end
