//
//  NCGroupMembersCollectionViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupMembersCollectionViewModel.h"
#import "NCGroupMemberHeaderCell.h"
#import "NCSelectUserViewController.h"
#import "NCRemoveGroupMembersViewController.h"
#import "NCGroupManager.h"
#import "NCProfileViewController.h"
#import "NCUserProfileViewModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCChatUICommonDefine.h"
#import "NCAlertView.h"
#import "NCChatUIErrorCode.h"

@interface NCGroupMembersCollectionViewModel ()

@property (nonatomic, weak) UIViewController *inViewController;

@property (nonatomic, strong) NSArray <NCGroupMemberInfo *> *members;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, assign) BOOL allowAdd;

@property (nonatomic, assign) BOOL allowRemove;

@property (nonatomic, copy) NSArray <NCFriendInfo *> *friends;

@end

@implementation NCGroupMembersCollectionViewModel
@dynamic delegate;

+ (instancetype)viewModelWithGroupId:(NSString *)groupId
                             members:(NSArray <NCGroupMemberInfo *> *)members
                            allowAdd:(BOOL)allowAdd
                         allowRemove:(BOOL)allowRemove
                    inViewController:(UIViewController *)inViewController {
    NCGroupMembersCollectionViewModel *viewModel = [self.class new];
    viewModel.groupId = groupId;
    viewModel.members = members;
    viewModel.allowAdd = allowAdd;
    viewModel.allowRemove = allowRemove;
    viewModel.inViewController = inViewController;
    [viewModel fetchFriendInfos];
    return viewModel;
}

#pragma mark -- NCCollectionViewModelProtocol

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    NSInteger count = self.members.count;
    if (self.allowAdd) {
        count += 1;
    }
    if (self.allowRemove) {
        count += 1;
    }
    return count;
}

+ (void)registerCollectionViewCell:(UICollectionView *)collectionView {
    [collectionView registerClass:NCGroupMemberHeaderCell.class forCellWithReuseIdentifier:NCGroupMemberHeaderCellIdentifier];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NCGroupMemberHeaderCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NCGroupMemberHeaderCellIdentifier forIndexPath:indexPath];
    if (self.members.count > indexPath.row) {
        NCGroupMemberInfo *member = self.members[indexPath.row];
        cell.nameLabel.hidden = NO;
        cell.portraitImageView.placeholderImage = NCDynamicImage(@"channel-list_cell_portrait_msg_img");
        cell.portraitImageView.imageURL = [NSURL URLWithString:member.avatarUrl];
        NSString *remark = [self remarkWithUserId:member.userId];
        if (remark.length > 0) {
            cell.nameLabel.text = remark;
        } else if (member.nickname.length > 0) {
            cell.nameLabel.text = member.nickname;
        } else {
            cell.nameLabel.text = member.name;
        }
    } else if ([self isAddItem:indexPath.row]) {
        cell.nameLabel.hidden = YES;
        cell.portraitImageView.placeholderImage = NCDynamicImage(@"group_member_add_img");
    } else if ([self isRemoveItem:indexPath.row]) {
        cell.nameLabel.hidden = YES;
        cell.portraitImageView.placeholderImage = NCDynamicImage(@"group_member_remove_img");
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.members.count > indexPath.row) {
        [self showMemberDetailVC:self.members[indexPath.row]];
    } else if ([self isAddItem:indexPath.row]) {
        [self addGroupMember];
    } else if ([self isRemoveItem:indexPath.row]) {
        [self removeGroupMember];
    }
}

#pragma mark -- private

- (void)fetchFriendInfos {
    NSMutableArray<NSString *> *userIds = [NSMutableArray arrayWithCapacity:self.members.count];
    for (NCGroupMemberInfo *member in self.members) {
        if (member.userId.length > 0) {
            [userIds addObject:member.userId];
        }
    }
    [NCGroupManager fetchFriendInfosWithUserIds:userIds.copy complete:^(NSArray<NCFriendInfo *> * _Nullable friendInfos) {
        if (friendInfos.count <= 0) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.friends = friendInfos;
            if ([self.responder respondsToSelector:@selector(reloadCollectionViewData)]) {
                [self.responder reloadCollectionViewData];
            }
        });
    }];
}

- (NSString *)remarkWithUserId:(NSString *)userId {
    if (self.friends.count <= 0) {
        return nil;
    }
    return [NCGroupManager friendWithUserId:userId inFriendInfos:self.friends].remark;
}

- (void)showMemberDetailVC:(NCGroupMemberInfo *)member {
    if ([self.delegate respondsToSelector:@selector(groupMembersCollectionViewModel:viewController:didSelectMember:)]) {
        BOOL intercept = [self.delegate groupMembersCollectionViewModel:self viewController:self.inViewController didSelectMember:member];
        if (intercept) {
            return;
        }
    }
    NCProfileViewModel *viewModel = [NCUserProfileViewModel viewModelWithUserId:member.userId];
    if ([viewModel isKindOfClass:NCUserProfileViewModel.class]) {
        [((NCUserProfileViewModel *)viewModel) showGroupMemberInfo:self.groupId];
    }
    NCProfileViewController *viewController = [[NCProfileViewController alloc] initWithViewModel:viewModel];
    [self.inViewController.navigationController pushViewController:viewController animated:YES];
}

- (void)addGroupMember {
    if ([self.delegate respondsToSelector:@selector(groupMembersCollectionViewModel:didSelectAdd:)]) {
        BOOL intercept = [self.delegate groupMembersCollectionViewModel:self didSelectAdd: self.inViewController];
        if (intercept) {
            return;
        }
    }
    NCSelectUserViewModel *vm = [NCSelectUserViewModel viewModelWithType:NCSelectUserTypeInviteJoinGroup groupId:self.groupId];
    __weak typeof(self) weakSelf = self;
    vm.selectionDidCompelteBlock = ^(NSArray<NSString *> * _Nonnull selectUserIds, UIViewController * _Nonnull selectVC) {
        [weakSelf inviteJoinGroup:selectUserIds viewController:selectVC];
    };
    NCSelectUserViewController *vc = [[NCSelectUserViewController alloc] initWithViewModel:vm];
    [self.inViewController.navigationController pushViewController:vc animated:YES];
}

- (void)inviteJoinGroup:(NSArray *)selectUserIds viewController:(UIViewController *)viewController {
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId ?: @""];
    if (!channel) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NCAlertView showAlertController:nil message:NCUILocalizedString(@"invite_join_group_error") hiddenAfterDelay:2];
        });
        return;
    }
    [channel inviteUsersWithUserIds:selectUserIds completion:^(NSInteger processCode, NCError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"invite_join_group_error") hiddenAfterDelay:2];
            });
            return;
        }
        if ([self.delegate respondsToSelector:@selector(groupMembersCollectionViewModel:didInviteUsers:processCode:viewController:)]) {
            BOOL intercept = [self.delegate groupMembersCollectionViewModel:self didInviteUsers:selectUserIds processCode:processCode viewController:viewController];
            if (intercept) {
                return;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [viewController.navigationController popViewControllerAnimated:YES];
            if (processCode == NCChatUIErrorCodeGroupJoinNeedManagerAccept) {
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"invite_join_group_need_owner_or_manager_accept_tip") hiddenAfterDelay:2];
            } else if (processCode == NCChatUIErrorCodeGroupNeedInviteeAccept) {
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"invite_join_group_need_invitee_accept_tip") hiddenAfterDelay:2];
            } else {
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"invite_join_group_success") hiddenAfterDelay:2];
            }
        });
    }];
}

- (void)removeGroupMember {
    if ([self.delegate respondsToSelector:@selector(groupMembersCollectionViewModel:didSelectRemove:)]) {
        BOOL intercept = [self.delegate groupMembersCollectionViewModel:self didSelectRemove:self.inViewController];
        if (intercept) {
            return;
        }
    }
    NCRemoveGroupMembersViewModel *vm = [NCRemoveGroupMembersViewModel viewModelWithGroupId:self.groupId];
    NCRemoveGroupMembersViewController *vc = [[NCRemoveGroupMembersViewController alloc] initWithViewModel:vm];
    [self.inViewController.navigationController pushViewController:vc animated:YES];
}

- (BOOL)isAddItem:(NSInteger)index {
    if (self.allowAdd && index == self.members.count) {
        return YES;
    }
    return NO;
}

- (BOOL)isRemoveItem:(NSInteger)index {
    if (!self.allowRemove)  {
        return NO;
    }
    if (self.allowAdd) {
        if (index == self.members.count + 1) {
            return YES;
        }
    } else {
        if (index == self.members.count) {
            return YES;
        }
    }
    return NO;
}

@end
