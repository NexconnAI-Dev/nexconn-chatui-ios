//
//  NCGroupNotificationCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupNotificationCellViewModel.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIErrorCode.h"
#import "NCGroupNotificationCell.h"
#import "NCReadWriteLock.h"

@interface NCGroupNotificationCellViewModel ()
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, weak) NCGroupNotificationCell *cell;
@property (nonatomic, strong) NCReadWriteLock *lock;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, weak) UIViewController<NCListViewModelResponder> *responder;
@property (nonatomic, assign) CGFloat cellHeight;

@end

@implementation NCGroupNotificationCellViewModel

- (instancetype)initWithApplicationInfo:(NCGroupApplicationInfo *)application {
    self = [super init];
    if (self) {
        self.application = application;
        self.lock = [NCReadWriteLock new];
    }
    return self;
}

/// Registers the cell class.
+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCGroupNotificationCell class]
        forCellReuseIdentifier:NCGroupNotificationCellIdentifier];
}

/// Binds the action responder.
- (void)bindResponder:(UIViewController<NCListViewModelResponder> *)responder {
    self.responder = responder;
}

- (void)fetchGroupNameIfNeed {
    __block NCGroupNotificationCell *cell = nil;
    __block NSString *groupName = nil;
    [self.lock performReadLockBlock:^{
      groupName = self.groupName;
      cell = self.cell;
    }];

    if (groupName) {
        cell.labName.text = groupName;
        return;
    }

    if (self.application.groupId) {
        [NCGroupChannel
            getGroupsInfoWithGroupIds:@[ self.application.groupId ]
                           completion:^(NSArray<NCGroupInfo *> *_Nullable groupInfos,
                                        NCError *_Nullable error) {
                             if (error) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                   cell.labName.text = nil;
                                 });
                                 return;
                             }
                             NSString *name = nil;
                             if (groupInfos.count) {
                                 NCGroupInfo *info = [groupInfos firstObject];
                                 name = info.groupName;
                             }
                             [self.lock performWriteLockBlock:^{
                               self.groupName = name;
                             }];

                             __block NCGroupNotificationCell *cell2 = nil;

                             dispatch_async(dispatch_get_main_queue(), ^{
                               [self.lock performReadLockBlock:^{
                                 cell2 = self.cell;
                               }];
                               if (cell2 != cell) { // The cell was reused; discard this update.
                                   return;
                               }
                               cell.labName.text = name;
                               [self reloadCell];
                             });
                           }];
    } else {
        cell.labName.text = nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.tableView = tableView;
    self.indexPath = indexPath;
    NCGroupNotificationCell *cell =
        [tableView dequeueReusableCellWithIdentifier:NCGroupNotificationCellIdentifier
                                        forIndexPath:indexPath];
    self.cell = cell;
    cell.hideSeparatorLine = self.hideSeparatorLine;
    [self fetchGroupNameIfNeed];
    [cell updateWithViewModel:self];
    cell.labTips.text = [self tipsOfOperator:self.application];
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellHeight;
}

/// Accepts the application.
- (void)approveApplication {
    NCGroupChannel *channel =
        [[NCGroupChannel alloc] initWithChannelId:self.application.groupId ?: @""];
    if (!channel) {
        return;
    }
    // Received invitation.
    if (self.application.direction == NCGroupApplicationDirectionInvitationReceived) {
        [channel acceptInviteWithInviterId:self.application.inviterInfo.userId ?: @""
                                completion:^(NCError *_Nullable error) {
                                  if (error) {
                                      [self showTips:NCUILocalizedString(
                                                         @"group_invitation_accept_failed")];
                                      return;
                                  }
                                  self.application.status = NCGroupApplicationStatusJoined;
                                  [self reloadCell];
                                }];
    } else if (self.application.direction == NCGroupApplicationDirectionApplicationReceived) {
        NCAcceptGroupApplicationParams *params = [[NCAcceptGroupApplicationParams alloc] init];
        params.inviterId = self.application.inviterInfo.userId;
        params.applicantId = self.application.joinMemberInfo.userId ?: @"";
        [channel
            acceptApplicationWithParams:params
                             completion:^(NSInteger processCode, NCError *_Nullable error) {
                               if (error) {
                                   [self showTips:NCUILocalizedString(
                                                      @"group_other_invitation_accept_failed")];
                                   return;
                               }
                               if (processCode ==
                                   NCChatUIErrorCodeGroupNeedInviteeAccept) { // An inviter is
                                                                              // present.
                                   self.application.status =
                                       NCGroupApplicationStatusInviteeUnhandled;
                               } else if (processCode ==
                                          NCChatUIErrorCodeSuccess) { // Join request.
                                   self.application.status = NCGroupApplicationStatusJoined;
                               }
                               [self reloadCell];
                             }];
    }
}

/// Rejects the application.
- (void)rejectApplication {
    NCGroupChannel *channel =
        [[NCGroupChannel alloc] initWithChannelId:self.application.groupId ?: @""];
    if (!channel) {
        return;
    }
    // Received invitation.
    if (self.application.direction == NCGroupApplicationDirectionInvitationReceived) {
        NCRefuseGroupInviteParams *params = [[NCRefuseGroupInviteParams alloc] init];
        params.inviterId = self.application.inviterInfo.userId ?: @"";
        params.reason = @"";
        [channel refuseInviteWithParams:params
                             completion:^(NCError *_Nullable error) {
                               if (error) {
                                   [self showTips:NCUILocalizedString(
                                                      @"group_invitation_refuse_failed")];
                                   return;
                               }
                               self.application.status = NCGroupApplicationStatusInviteeRefused;
                               [self reloadCell];
                             }];
    } else if (self.application.direction == NCGroupApplicationDirectionApplicationReceived) {
        NCRefuseGroupApplicationParams *params = [[NCRefuseGroupApplicationParams alloc] init];
        params.inviterId = self.application.inviterInfo.userId;
        params.applicantId = self.application.joinMemberInfo.userId ?: @"";
        params.reason = @"";
        [channel
            refuseApplicationWithParams:params
                             completion:^(NCError *_Nullable error) {
                               if (error) {
                                   [self showTips:NCUILocalizedString(
                                                      @"group_other_invitation_refuse_failed")];
                                   return;
                               }

                               if (self.application.status ==
                                   NCGroupApplicationStatusAdminUnhandled) {
                                   self.application.status = NCGroupApplicationStatusAdminRefused;
                               } else if (self.application.status ==
                                          NCGroupApplicationStatusInviteeRefused) {
                                   self.application.status = NCGroupApplicationStatusInviteeRefused;
                               }
                               [self reloadCell];
                             }];
    }
}

- (void)showTips:(NSString *)tips {
    if ([self.responder respondsToSelector:@selector(showTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.responder showTips:tips];
        });
    }
}

- (void)reloadCell {
    if (self.indexPath) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.tableView reloadRowsAtIndexPaths:@[ self.indexPath ]
                                withRowAnimation:UITableViewRowAnimationFade];
          [self.tableView setNeedsLayout];
          [self.tableView layoutIfNeeded];
        });
    }
}
#pragma mark - Private

- (NSString *)displayNameOf:(NCGroupMemberInfo *)info {
    NSString *name = info.nickname;
    if (name.length == 0) {
        name = info.name;
    }
    return name;
}

- (NSString *)nameOfOperator:(NCGroupApplicationInfo *)application {
    NSString *name = @"";
    switch (application.direction) {
        // Received invitation.
    case NCGroupApplicationDirectionInvitationReceived:
        name = [self displayNameOf:application.inviterInfo];
        break;
        // Received application.
    case NCGroupApplicationDirectionApplicationReceived:
        if (application.inviterInfo) {
            name = [self displayNameOf:application.inviterInfo];
        } else {
            name = [self displayNameOf:application.joinMemberInfo];
        }

        break;
    case NCGroupApplicationDirectionInvitationSent:
        name = [self displayNameOf:application.joinMemberInfo];
        break;
    case NCGroupApplicationDirectionApplicationSent:
        name = [self displayNameOf:application.joinMemberInfo];
        break;
    default:
        break;
    }
    return name;
}

- (NSString *)tipsOfOperator:(NCGroupApplicationInfo *)application {
    NSString *name = [self nameOfOperator:application];
    NSString *tips = @"";
    switch (application.direction) {
        // Received invitation.
    case NCGroupApplicationDirectionInvitationReceived:
        tips =
            [NSString stringWithFormat:NCUILocalizedString(@"group_notification_invite_me"), name];
        break;
        // Received application.
    case NCGroupApplicationDirectionApplicationReceived:
        if (application.inviterInfo) {
            tips = [NSString
                stringWithFormat:NCUILocalizedString(@"group_notification_invite_user_join_group"),
                                 name, application.joinMemberInfo.name];
        } else {
            tips = [NSString
                stringWithFormat:NCUILocalizedString(@"group_notification_apply_join_group"), name];
        }
        break;
    case NCGroupApplicationDirectionApplicationSent:
        tips = NCUILocalizedString(@"group_notification_apply_join_other_group");
        break;
    case NCGroupApplicationDirectionInvitationSent:
        tips = [NSString
            stringWithFormat:NCUILocalizedString(@"group_notification_invite_other"), name];
        break;
    default:
        break;
    }
    return tips;
}

- (CGFloat)cellHeight {
    if (_cellHeight == 0) {
        // Deprecated: row height is determined automatically.
        _cellHeight = 115;
    }
    return _cellHeight;
}

@end
