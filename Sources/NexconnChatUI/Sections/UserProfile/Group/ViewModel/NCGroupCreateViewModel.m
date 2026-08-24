//
//  NCGroupCreateViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupCreateViewModel.h"
#import "NCAlertView.h"
#import "NCChannelViewController.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIErrorCode.h"
#import "NCGroupManager.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <NexconnChatUI/NCChatUILog.h>

@interface NCGroupCreateViewModel ()

@property (nonatomic, strong) NSArray<NSString *> *inviteeUserIds;

@property (nonatomic, copy) NSString *portraitUrl;

@property (nonatomic, assign) NSInteger groupNameLimit;

@end

@implementation NCGroupCreateViewModel
@dynamic delegate;

+ (instancetype)viewModelWithInviteeUserIds:(NSArray<NSString *> *)inviteeUserIds {
    NCGroupCreateViewModel *viewModel = [self.class new];
    viewModel.inviteeUserIds = inviteeUserIds;
    viewModel.groupNameLimit = 64;
    return viewModel;
}

- (void)createGroup:(NSString *)groupName inViewController:(UIViewController *)viewController {
    NSString *validGroupName = [groupName
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (validGroupName.length < 1) {
        [NCAlertView showAlertController:nil
                                 message:NCUILocalizedString(@"group_name_empty_tip")
                        hiddenAfterDelay:2];
        return;
    }
    NCGroupInfo *group = [[NCGroupInfo alloc] init];
    if ([self.delegate respondsToSelector:@selector(generateGroupId)]) {
        group.groupId = [self.delegate generateGroupId];
    }
    group.groupId = [self p_validGroupIdFromGroupId:group.groupId];
    if (group.groupId.length < 1) {
        NCLogE(@"create group, groupId is empty");
        [self stopLoading];
        [NCAlertView showAlertController:nil
                                 message:NCUILocalizedString(@"group_create_error")
                        hiddenAfterDelay:2];
        return;
    }
    group.groupName = validGroupName;
    group.avatarUrl = self.portraitUrl;
    group.joinPermission = NCGroupJoinPermissionFree;
    NCCreateGroupParams *params = [[NCCreateGroupParams alloc] initWithGroupId:group.groupId
                                                                     groupName:group.groupName];
    params.avatarUrl = group.avatarUrl;
    params.inviteeUserIds = self.inviteeUserIds ?: @[];
    params.joinPermission = NCGroupJoinPermissionFree;
    [self loadingWithTip:NCUILocalizedString(@"saving")];
    [NCGroupChannel
        createGroupWithParams:params
                   completion:^(NSInteger processCode, NSArray<NSString *> *_Nullable errorKeys,
                                NCError *_Nullable error) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                       [self stopLoading];
                       if (error == nil) {
                           if ([self.delegate
                                   respondsToSelector:@selector(groupCreateDidSuccess:processCode:
                                                                inViewController:)]) {
                               BOOL intercept =
                                   [self.delegate groupCreateDidSuccess:group
                                                            processCode:processCode
                                                       inViewController:viewController];
                               if (intercept) {
                                   return;
                               }
                           }
                           NSString *validGroupId = [self p_validGroupIdFromGroupId:group.groupId];
                           if (validGroupId.length < 1) {
                               NCLogE(@"create group success, groupId is empty");
                               [NCAlertView
                                   showAlertController:nil
                                               message:NCUILocalizedString(@"group_create_error")
                                      hiddenAfterDelay:2];
                               return;
                           }
                           group.groupId = validGroupId;
                           NCChannelViewController *conversationVC =
                               [[NCChannelViewController alloc]
                                   initWithChannelType:NCChannelTypeGroup
                                             channelId:group.groupId];
                           conversationVC.navigationItem.title = validGroupName;
                           [viewController.navigationController pushViewController:conversationVC
                                                                          animated:YES];
                           if (processCode == NCChatUIErrorCodeGroupNeedInviteeAccept) {
                               [NCAlertView showAlertController:nil
                                                        message:NCUILocalizedString(
                                                                    @"create_success_and_need_"
                                                                    @"invitee_accept_tip")
                                               hiddenAfterDelay:2];
                           }
                           return;
                       }
                       NSString *tips = NCUILocalizedString(@"group_create_error");
                       if (error.code == NCChatUIErrorCodeInformationAuditFailed) {
                           tips = NCUILocalizedString(@"content_contains_sensitive");
                       }
                       [NCAlertView showAlertController:nil message:tips hiddenAfterDelay:2];
                     });
                   }];
}

- (void)portraitImageViewDidClick:(UIViewController *)inViewController {
    if ([self.delegate respondsToSelector:@selector(groupPortraitDidClick:resultBlock:)]) {
        [self.delegate
            groupPortraitDidClick:inViewController
                      resultBlock:^(NSString *_Nonnull portraitUrl) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                          self.portraitUrl = portraitUrl;
                          if ([self.responder
                                  respondsToSelector:@selector(groupPortraitDidUpdate:)]) {
                              [self.responder groupPortraitDidUpdate:portraitUrl];
                          }
                        });
                      }];
    }
}

- (NSString *)p_validGroupIdFromGroupId:(NSString *)groupId {
    return
        [groupId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
@end
