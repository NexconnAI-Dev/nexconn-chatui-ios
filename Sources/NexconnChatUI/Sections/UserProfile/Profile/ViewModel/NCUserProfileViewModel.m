//
//  NCUserProfileViewModel.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <NexconnChatSDK/NexconnChatSDK.h>
#import <NexconnChatUI/NCChatUILog.h>

#import "NCChatUI.h"
#import "NCChatUICommonDefine.h"
#import "NCMyProfileViewModel.h"
#import "NCNameEditViewController.h"
#import "NCProfileCommonCellViewModel.h"
#import "NCProfileCommonSwitchCell.h"
#import "NCProfileCommonTextCell.h"
#import "NCProfileFooterViewModel.h"
#import "NCProfileSwitchCellViewModel.h"
#import "NCProfileViewModel+private.h"
#import "NCUserOnlineStatusManager.h"
#import "NCUserOnlineStatusUtil.h"
#import "NCUserProfileHeaderCell.h"
#import "NCUserProfileHeaderCellViewModel.h"
#import "NCUserProfileViewModel.h"

#define NCUserProfileViewFooterChatTop 100
#define NCUserProfileViewFooterLeadingOrTrailing 25
#define NCUserProfileViewFooterBtnheight 40
#define NCUserProfileViewFooterAddFriendBtnTop 15

@interface NCUserProfileViewModel () <NCChannelHandler>

@property (nonatomic, copy) NSString *userId;

@property (nonatomic, assign) BOOL isFriend;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, strong) NCGroupInfo *group;

@property (nonatomic, strong) NCGroupMemberInfo *member;

@property (nonatomic, copy) NSString *channelEventHandlerId;

@end

static NSString *NCProfileCurrentUserId(void) { return [NCEngine getCurrentUserId] ?: @""; }

@implementation NCUserProfileViewModel
+ (NCProfileViewModel *)viewModelWithUserId:(NSString *)userId {
    if ([userId isEqualToString:NCProfileCurrentUserId()]) {
        return [NCMyProfileViewModel new];
    }
    NCUserProfileViewModel *viewModel = [[self.class alloc] init];
    viewModel.userId = userId;
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.verifyFriend = YES;
        self.channelEventHandlerId =
            [NSString stringWithFormat:@"nc.user.profile.channel.%p", self];
        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(onUserOnlineStatusChanged:)
                   name:NCChatUIUserOnlineStatusChangedNotification
                 object:nil];
        [NCEngine addChannelHandlerWithIdentifier:self.channelEventHandlerId handler:self];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NCEngine removeChannelHandlerForIdentifier:self.channelEventHandlerId];
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCProfileCommonTextCell class]
        forCellReuseIdentifier:NCProfileTextCellIdentifier];
    [tableView registerClass:[NCUserProfileHeaderCell class]
        forCellReuseIdentifier:NCUserProfileHeaderCellIdentifier];
    [tableView registerClass:[NCProfileCommonSwitchCell class]
        forCellReuseIdentifier:NCProfileCommonSwitchCellIdentifier];
}

- (void)showGroupMemberInfo:(NSString *)groupId {
    if (groupId.length == 0 || self.userId.length == 0) {
        return;
    }
    if ([self.userId isEqualToString:NCProfileCurrentUserId()]) {
        return;
    }
    self.groupId = groupId;
}

#pragma mark-- NCListViewModelProtocol

- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    NCProfileCellViewModel *cellViewModel = self.profileList[indexPath.section][indexPath.row];

    if ([self.delegate respondsToSelector:@selector(profileViewModel:viewController:tableView:
                                                    didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate profileViewModel:self
                                          viewController:viewController
                                               tableView:tableView
                                            didSelectRow:indexPath
                                           cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }

    if (![cellViewModel isKindOfClass:NCProfileCommonCellViewModel.class]) {
        return;
    }
    NCProfileCommonCellViewModel *commonCellViewModel =
        (NCProfileCommonCellViewModel *)cellViewModel;
    if ([commonCellViewModel.title isEqualToString:NCUILocalizedString(@"set_remark")]) {
        NCNameEditViewModel *viewModel =
            [NCNameEditViewModel viewModelWithUserId:self.userId
                                             groupId:nil
                                                type:NCNameEditTypeRemark];
        NCNameEditViewController *nameEditVC =
            [[NCNameEditViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:nameEditVC animated:YES];
    } else if ([commonCellViewModel.title
                   isEqualToString:NCUILocalizedString(@"group_member_nickname")] &&
               [self canEditGroupMemberNickname]) {
        NCNameEditViewModel *viewModel =
            [NCNameEditViewModel viewModelWithUserId:self.userId
                                             groupId:self.group.groupId
                                                type:NCNameEditTypeGroupMemberNickname];
        viewModel.title = NCUILocalizedString(@"group_member_nickname");
        NCNameEditViewController *nameEditVC =
            [[NCNameEditViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:nameEditVC animated:YES];
    }
}

- (void)updateProfile {
    if (self.userId.length == 0) {
        return;
    }
    [self updateGroupMemberInfo];
    if (self.verifyFriend) {
        [[NCEngine userModule]
            checkFriendsWithUserIds:@[ self.userId ]
                         completion:^(NSArray<NCFriendRelationInfo *> *_Nullable friendRelations,
                                      NCError *_Nullable error) {
                           if (error) {
                               [self getUserProfile];
                               return;
                           }
                           NCFriendRelationInfo *relationInfo = friendRelations.firstObject;
                           if (relationInfo.relationType == NCFriendRelationTypeInMyFriendList ||
                               relationInfo.relationType == NCFriendRelationTypeBothWay) {
                               self.isFriend = YES;
                               [self getFriendInfo];
                           } else {
                               [self getUserProfile];
                           }
                         }];
    } else {
        [self getUserProfile];
    }
}

- (void)getUserProfile {
    [[NCEngine userModule]
        getUserProfilesWithUserIds:@[ self.userId ?: @"" ]
                        completion:^(NSArray<NCUserProfile *> *_Nullable userProfiles,
                                     NCError *_Nullable error) {
                          if (error) {
                              NCLogE(@"get User Profiles error");
                              return;
                          }
                          dispatch_async(dispatch_get_main_queue(), ^{
                            [self loadFooterViewModel];
                            self.profileList = [self reloadDataSource:userProfiles.firstObject];
                            [self.responder reloadData:NO];
                          });
                        }];
}

- (void)getFriendInfo {
    [[NCEngine userModule]
        getFriendsInfoWithUserIds:@[ self.userId ?: @"" ]
                       completion:^(NSArray<NCFriendInfo *> *_Nullable friendInfos,
                                    NCError *_Nullable error) {
                         if (error) {
                             return;
                         }
                         NCFriendInfo *friend = friendInfos.firstObject;
                         dispatch_async(dispatch_get_main_queue(), ^{
                           [self loadFooterViewModel];
                           self.profileList = [self reloadFriendDataSource:friend];
                           [self.responder reloadData:NO];
                         });
                       }];
}

- (void)loadFooterViewModel {
    NCProfileFooterViewType type = NCProfileFooterViewTypeChat;
    if (self.verifyFriend && !self.isFriend) {
        type = NCProfileFooterViewTypeAddFriend;
    }
    NCProfileFooterViewModel *footerViewModel =
        [[NCProfileFooterViewModel alloc] initWithResponder:[self.responder currentViewController]
                                                       type:type
                                                  channelId:self.userId];
    footerViewModel.verifyFriend = self.verifyFriend;
    [self configFooterViewModel:footerViewModel];
}

- (void)onUserOnlineStatusChanged:(NSNotification *)notification {
    NSArray<NSString *> *changedUserIds =
        notification.userInfo[NCChatUIUserOnlineStatusChangedUserIdsKey];
    for (NSString *userId in changedUserIds) {
        if ([userId isEqualToString:self.userId]) {
            if (self.profileList.count == 0 || self.profileList.firstObject.count == 0) {
                continue;
            }
            NCProfileCellViewModel *headerVM = self.profileList[0][0];
            if ([headerVM isKindOfClass:NCUserProfileHeaderCellViewModel.class]) {
                NCUserProfileHeaderCellViewModel *headerCellVM =
                    (NCUserProfileHeaderCellViewModel *)headerVM;
                NCSubscribeUserOnlineStatus *onlineStatus =
                    [NCUserOnlineStatusManager.sharedManager getCachedOnlineStatus:userId];
                headerCellVM.hasOnlineStatus = (onlineStatus != nil);
                headerCellVM.isOnline = onlineStatus.isOnline;
                [self.responder reloadData:NO];
            }
        }
    }
}

#pragma mark-- NCChannelHandler

- (void)onChannelPinnedSync:(NCChannelPinnedSyncEvent *)event {
    if (!self.showsChannelSettings) {
        return;
    }
    if (event.channelIdentifier.channelType != NCChannelTypeDirect) {
        return;
    }
    if (![event.channelIdentifier.channelId isEqualToString:self.userId]) {
        return;
    }
    [self updateProfile];
}

#pragma mark - private

- (NSArray<NSArray<NCProfileCellViewModel *> *> *)reloadFriendDataSource:
    (NCFriendInfo *)friendInfo {

    NSMutableArray *profileList = [NSMutableArray array];

    NCUserProfileHeaderCellViewModel *headerVM =
        [[NCUserProfileHeaderCellViewModel alloc] initWithPortrait:friendInfo.avatarUrl
                                                              name:friendInfo.name
                                                            remark:friendInfo.remark];
    // Online status.
    [self setupViewModelOnlineStatus:headerVM];

    NCProfileCommonCellViewModel *setRemarkVM =
        [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText
                                                         title:NCUILocalizedString(@"set_remark")
                                                        detail:nil];
    setRemarkVM.hideSeparatorLine = YES;

    [profileList addObject:@[ headerVM ]];
    [profileList addObject:@[ setRemarkVM ]];

    if (self.member) {
        NCProfileCommonCellViewModel *memberNicknameVM = [[NCProfileCommonCellViewModel alloc]
            initWithCellType:NCUProfileCellTypeText
                       title:NCUILocalizedString(@"group_member_nickname")
                      detail:self.member.nickname];
        memberNicknameVM.hiddenArrow = ![self canEditGroupMemberNickname];
        [profileList addObject:@[ memberNicknameVM ]];
    }

    NSArray<NCProfileCellViewModel *> *channelSettingItems = [self channelSettingCellViewModels];
    if (channelSettingItems.count > 0) {
        [profileList addObject:channelSettingItems];
    }
    return profileList;
}

- (NSArray<NSArray<NCProfileCellViewModel *> *> *)reloadDataSource:(NCUserProfile *)userProfile {
    if (!userProfile) {
        userProfile = [[NCUserProfile alloc] init];
        userProfile.userId = self.userId;
    }
    NSMutableArray *profileList = [NSMutableArray array];

    NCUserProfileHeaderCellViewModel *headerVM =
        [[NCUserProfileHeaderCellViewModel alloc] initWithPortrait:userProfile.avatarUrl
                                                              name:userProfile.name
                                                            remark:userProfile.email];

    [self setupViewModelOnlineStatus:headerVM];

    [profileList addObject:@[ headerVM ]];
    if (self.verifyFriend && self.isFriend) {
        NCProfileCommonCellViewModel *setRemarkVM = [[NCProfileCommonCellViewModel alloc]
            initWithCellType:NCUProfileCellTypeText
                       title:NCUILocalizedString(@"set_remark")
                      detail:nil];
        [profileList addObject:@[ setRemarkVM ]];
    }

    if (self.member) {
        NCProfileCommonCellViewModel *memberNicknameVM = [[NCProfileCommonCellViewModel alloc]
            initWithCellType:NCUProfileCellTypeText
                       title:NCUILocalizedString(@"group_member_nickname")
                      detail:self.member.nickname];
        memberNicknameVM.hiddenArrow = ![self canEditGroupMemberNickname];
        [profileList addObject:@[ memberNicknameVM ]];
    }

    NSArray<NCProfileCellViewModel *> *channelSettingItems = [self channelSettingCellViewModels];
    if (channelSettingItems.count > 0) {
        [profileList addObject:channelSettingItems];
    }
    return profileList;
}

- (void)updateGroupMemberInfo {
    if (self.groupId.length == 0) {
        return;
    }
    [NCGroupChannel
        getGroupsInfoWithGroupIds:@[ self.groupId ]
                       completion:^(NSArray<NCGroupInfo *> *_Nullable groupInfos,
                                    NCError *_Nullable error) {
                         if (error) {
                             return;
                         }
                         self.group = groupInfos.firstObject;
                         NCGroupChannel *channel =
                             [[NCGroupChannel alloc] initWithChannelId:self.groupId];
                         [channel
                             getMembersWithUserIds:@[ self.userId ]
                                        completion:^(
                                            NSArray<NCGroupMemberInfo *> *_Nullable groupMembers,
                                            NCError *_Nullable error) {
                                          if (error) {
                                              return;
                                          }
                                          self.member = groupMembers.firstObject;
                                        }];
                       }];
}

- (BOOL)canEditGroupMemberNickname {
    if ([self.member.userId isEqualToString:NCProfileCurrentUserId()]) {
        return YES;
    }
    if (self.group.memberInfoEditPermission == NCGroupMemberInfoEditPermissionOwnerOrAdminOrSelf &&
        (self.group.role == NCGroupMemberRoleOwner || self.group.role == NCGroupMemberRoleAdmin)) {
        return YES;
    }
    if (self.group.memberInfoEditPermission == NCGroupMemberInfoEditPermissionOwnerOrSelf &&
        (self.group.role == NCGroupMemberRoleOwner)) {
        return YES;
    }
    return NO;
}

- (NSArray<NCProfileCellViewModel *> *)channelSettingCellViewModels {
    if (!self.showsChannelSettings || self.userId.length == 0 || self.groupId.length > 0) {
        return @[];
    }
    return @[ [self topVM] ];
}

- (NCProfileSwitchCellViewModel *)topVM {
    NCProfileSwitchCellViewModel *topVM = [NCProfileSwitchCellViewModel new];
    topVM.title = NCUILocalizedString(@"set_top");
    NCDirectChannel *channel = [[NCDirectChannel alloc] initWithChannelId:self.userId];
    __weak typeof(self) weakSelf = self;
    [channel
        reloadWithCompletion:^(NCBaseChannel *_Nullable latestChannel, NSError *_Nullable error) {
          if (error && !latestChannel) {
              return;
          }
          NCBaseChannel *activeChannel = latestChannel ?: channel;
          dispatch_async(dispatch_get_main_queue(), ^{
            topVM.switchOn = activeChannel.isPinned;
            [weakSelf.responder reloadData:NO];
          });
        }];
    topVM.switchValueChanged = ^(BOOL on) {
      NCDirectChannel *activeChannel = [[NCDirectChannel alloc] initWithChannelId:weakSelf.userId];
      if (on) {
          NCPinParams *params = [[NCPinParams alloc] initWithUpdateOperationTime:NO];
          [activeChannel pinWithParams:params
                            completion:^(NCError *_Nullable error){
                            }];
      } else {
          [activeChannel unpinWithCompletion:^(NCError *_Nullable error){
          }];
      }
    };
    return topVM;
}

- (void)setupViewModelOnlineStatus:(NCUserProfileHeaderCellViewModel *)headerVM {
    if (![NCUserOnlineStatusUtil shouldDisplayOnlineStatus]) {
        headerVM.displayOnlineStatus = NO;
        return;
    }
    NCSubscribeUserOnlineStatus *onlineStatus = [self getUserOnlineStatus:self.userId];
    headerVM.hasOnlineStatus = (onlineStatus != nil);
    headerVM.isOnline = onlineStatus.isOnline;
    headerVM.displayOnlineStatus = YES;
}

- (NCSubscribeUserOnlineStatus *)getUserOnlineStatus:(NSString *)userId {
    if (userId.length == 0) {
        return nil;
    }
    NCSubscribeUserOnlineStatus *onlineStatus =
        [NCUserOnlineStatusManager.sharedManager getCachedOnlineStatus:userId];
    if (!onlineStatus) {
        if (self.isFriend && self.verifyFriend) {
            [NCUserOnlineStatusManager.sharedManager fetchFriendOnlineStatus:@[ userId ]];
        } else {
            [NCUserOnlineStatusManager.sharedManager fetchOnlineStatus:userId
                                                 processSubscribeLimit:NO];
        }
    }
    return onlineStatus;
}

@end
