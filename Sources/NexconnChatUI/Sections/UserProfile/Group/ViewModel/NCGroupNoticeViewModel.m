//
//  NCGroupNoticeViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupNoticeViewModel.h"
#import "NCChatUICommonDefine.h"
#import "NCAlertView.h"
#import "NCChatUIErrorCode.h"
@interface NCGroupNoticeViewModel ()

@property (nonatomic, strong) NCGroupInfo *group;

@property (nonatomic, assign) BOOL canEdit;

@property (nonatomic, assign) NSInteger limit;

@end

@implementation NCGroupNoticeViewModel
@dynamic delegate;

- (instancetype)initWithGroup:(NCGroupInfo *)group {
    self = [super init];
    if (self) {
        self.group = group;
        self.canEdit = [self canEditProfile];
        self.limit = 1024;
    }
    return self;
}

- (void)updateNotice:(NSString *)notice inViewController:(nonnull UIViewController *)viewController{
    NCGroupInfo *group = [self updatedGroupWithNotice:notice];
    if ([self.delegate respondsToSelector:@selector(groupNoticeWillUpdate:viewModel:inViewController:)]) {
        BOOL intercept = [self.delegate groupNoticeWillUpdate:group viewModel:self inViewController:viewController];
        if (intercept) {
            return;
        }
    }
    [NCAlertView showAlertController:nil message:NCUILocalizedString(@"group_notice_update_alert") actionTitles:nil cancelTitle:NCUILocalizedString(@"cancel") confirmTitle:NCUILocalizedString(@"confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
        [self updateGroup:group inViewController:viewController];
    } inViewController:viewController];
    
}

- (NSString *)tip {
    if (self.canEdit) {
        return nil;
    }
    if (self.group.groupInfoEditPermission == NCGroupOperationPermissionOwner) {
        return NCUILocalizedString(@"group_operation_only_owner");
    }
    if (self.group.groupInfoEditPermission == NCGroupOperationPermissionOwnerOrAdmin) {
        return NCUILocalizedString(@"group_operation_owner_and_manager");
    }
    return nil;
}

#pragma mark -- private

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

- (NCGroupInfo *)updatedGroupWithNotice:(NSString *)notice {
    NCGroupInfo *group = [NCGroupInfo new];
    group.groupId = self.group.groupId;
    group.groupName = self.group.groupName;
    group.avatarUrl = self.group.avatarUrl;
    group.introduction = self.group.introduction;
    group.notice = notice;
    group.extProfile = self.group.extProfile;
    group.joinPermission = self.group.joinPermission;
    group.removeMemberPermission = self.group.removeMemberPermission;
    group.invitePermission = self.group.invitePermission;
    group.inviteHandlePermission = self.group.inviteHandlePermission;
    group.groupInfoEditPermission = self.group.groupInfoEditPermission;
    group.memberInfoEditPermission = self.group.memberInfoEditPermission;
    group.creatorId = self.group.creatorId;
    group.ownerId = self.group.ownerId;
    group.createTime = self.group.createTime;
    group.membersCount = self.group.membersCount;
    group.joinedTime = self.group.joinedTime;
    group.role = self.group.role;
    return group;
}

- (void)updateGroup:(NCGroupInfo *)group inViewController:(nonnull UIViewController *)viewController {
    [self loadingWithTip:NCUILocalizedString(@"saving")];
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:group.groupId];
    NCUpdateGroupInfoParams *params = [NCUpdateGroupInfoParams new];
    params.notice = group.notice;
    [channel updateInfoWithParams:params completion:^(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopLoading];
            if (!error) {
                self.group = group;
                if ([self.delegate respondsToSelector:@selector(groupNoticeDidUpdate:viewModel:inViewController:)]) {
                    BOOL intercept = [self.delegate groupNoticeDidUpdate:group viewModel:self inViewController:viewController];
                    if (intercept) {
                        return;
                    }
                }
                [viewController.navigationController popViewControllerAnimated:YES];
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"group_notice_success") hiddenAfterDelay:2];
                return;
            }
            NSString *tips = NCUILocalizedString(@"set_failed");
            if (error.code == NCChatUIErrorCodeInformationAuditFailed) {
                tips = NCUILocalizedString(@"content_contains_sensitive");
            }

            [NCAlertView showAlertController:nil message:tips hiddenAfterDelay:2];
        });
    }];
}
@end
