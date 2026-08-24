//
//  NCProfileFooterViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileFooterViewModel.h"
#import "NCAlertView.h"
#import "NCApplyFriendAlertView.h"
#import "NCChannelViewController.h"
#import "NCChatUICommonDefine.h"
#import "NCProfileFooterView.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <NexconnChatUI/NCChatUILog.h>
@interface NCProfileFooterViewModel ()

@property (nonatomic, weak) UIViewController *responder;

@property (nonatomic, assign) NCProfileFooterViewType type;

@property (nonatomic, copy) NSString *channelId;

@end

@implementation NCProfileFooterViewModel
@dynamic delegate;

- (instancetype)initWithResponder:(UIViewController *)responder
                             type:(NCProfileFooterViewType)type
                        channelId:(NSString *)channelId {
    self = [super init];
    if (self) {
        self.responder = responder;
        self.channelId = channelId;
        self.type = type;
    }
    return self;
}

- (UIView *)loadView {
    NCProfileFooterView *footerView =
        [[NCProfileFooterView alloc] initWithTopSpace:[self topSpace]
                                          buttonSpace:[self buttonSpace]
                                                items:[self items]];
    return footerView;
}

- (CGFloat)topSpace {
    CGFloat space = 0;
    switch (self.type) {
    case NCProfileFooterViewTypeAddFriend:
        space = 0;
        break;
    case NCProfileFooterViewTypeChat:
        space = 56;
        break;
    case NCProfileFooterViewTypeGroupOwner:
    case NCProfileFooterViewTypeGroupMember:
        space = 25;
        break;
    default:
        break;
    }
    return space;
}

- (CGFloat)buttonSpace {
    return 10;
}

- (NSArray *)items {
    NSArray *array = [NSArray array];
    switch (self.type) {
    case NCProfileFooterViewTypeAddFriend:
        array = [self addFriendItems];
        break;
    case NCProfileFooterViewTypeChat:
        array = [self userItems];
        break;
    case NCProfileFooterViewTypeGroupOwner:
        array = [self groupOwnerItems];
        break;
    case NCProfileFooterViewTypeGroupMember:
        array = [self groupMemberItems];
        break;
    default:
        break;
    }
    if ([self.delegate
            respondsToSelector:@selector(profileFooterViewModel:willLoadButtonItemsViewModels:)]) {
        array = [self.delegate profileFooterViewModel:self willLoadButtonItemsViewModels:array];
    }
    return array;
}

- (NSArray *)addFriendItems {
    NCButtonItem *item = [NCButtonItem itemWithTitle:NCUILocalizedString(@"add_friend")
                                          titleColor:NCDynamicColor(@"control_title_white_color")
                                     backgroundColor:NCDynamicColor(@"primary_color")];
    __weak typeof(self) weakSelf = self;
    [item setClickBlock:^{
      [NCApplyFriendAlertView showAlert:NCUILocalizedString(@"add_friend")
                            placeholder:NCUILocalizedString(@"add_friend_extra_placeholder")
                            lengthLimit:64
                             completion:^(NSString *text) {
                               [weakSelf addFriend:text];
                             }];
    }];
    return @[ item ];
}

- (NSArray *)userItems {
    NCButtonItem *chatItem =
        [NCButtonItem itemWithTitle:NCUILocalizedString(@"start_chat")
                         titleColor:NCDynamicColor(@"primary_color")
                    backgroundColor:NCDynamicColor(@"common_background_color")];
    __weak typeof(self) weakSelf = self;
    UIImage *icon = NCDynamicImage(@"user_profile_start_chat_img");
    chatItem.buttonIcon = icon;
    [chatItem setClickBlock:^{
      NCChannelViewController *conversationVC =
          [[NCChannelViewController alloc] initWithChannelType:NCChannelTypeDirect
                                                     channelId:weakSelf.channelId];
      [weakSelf.responder.navigationController pushViewController:conversationVC animated:YES];
    }];

    if (self.verifyFriend) {
        NCButtonItem *deleteItem =
            [NCButtonItem itemWithTitle:NCUILocalizedString(@"delete_friend")
                             titleColor:NCDynamicColor(@"hint_color")
                        backgroundColor:NCDynamicColor(@"common_background_color")];
        deleteItem.borderColor = NCDynamicColor(@"clear_color");
        [deleteItem setClickBlock:^{
          [[NCEngine userModule]
              getUserProfilesWithUserIds:@[ weakSelf.channelId ]
                              completion:^(NSArray<NCUserProfile *> *_Nullable userProfiles,
                                           NCError *_Nullable error) {
                                if (error) {
                                    return;
                                }
                                dispatch_async(dispatch_get_main_queue(), ^{
                                  [NCAlertView showAlertController:NCUILocalizedString(@"tip")
                                      message:[NSString
                                                  stringWithFormat:NCUILocalizedString(
                                                                       @"delete_friend_alert"),
                                                                   userProfiles.firstObject.name]
                                      actionTitles:nil
                                      cancelTitle:NCUILocalizedString(@"cancel")
                                      confirmTitle:NCUILocalizedString(@"confirm")
                                      preferredStyle:UIAlertControllerStyleAlert
                                      actionsBlock:nil
                                      cancelBlock:^{
                                      }
                                      confirmBlock:^{
                                        [weakSelf deleteFriend];
                                      }
                                      inViewController:weakSelf.responder];
                                });
                              }];
        }];
        return @[ chatItem, deleteItem ];
    }
    return @[ chatItem ];
}

- (void)deleteFriend {
    [[NCEngine userModule]
        removeFriendsWithUserIds:@[ self.channelId ?: @"" ]
                      completion:^(NCError *_Nullable error) {
                        if (error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                              [NCAlertView
                                  showAlertController:nil
                                              message:NCUILocalizedString(@"delete_friend_failed")
                                     hiddenAfterDelay:2];
                            });
                            return;
                        }
                        NCDirectChannel *channel =
                            [[NCDirectChannel alloc] initWithChannelId:self.channelId ?: @""];
                        [channel deleteWithCompletion:^(BOOL isSuccess, NCError *_Nullable error) {
                          if (!isSuccess || error) {
                              NCLogE(@"Contact deleted, but clearing the channel failed");
                          }
                        }];
                        NCDeleteMessagesForMeByTimestampParams *params =
                            [[NCDeleteMessagesForMeByTimestampParams alloc]
                                initWithTimestamp:0
                                           policy:NCMessageOperationPolicyLocalRemote];
                        [channel
                            deleteMessagesForMeByTimestampWithParams:params
                                                          completion:^(NCError *_Nullable error) {
                                                            if (error) {
                                                                NCLogE(@"Contact deleted, but "
                                                                       @"clearing messages failed");
                                                            }
                                                          }];
                        dispatch_async(dispatch_get_main_queue(), ^{
                          [self.responder.navigationController
                              popToViewController:self.responder.navigationController
                                                      .viewControllers.firstObject
                                         animated:YES];
                          [NCAlertView
                              showAlertController:nil
                                          message:NCUILocalizedString(@"delete_friend_success")
                                 hiddenAfterDelay:1];
                        });
                      }];
}

- (NSArray *)groupOwnerItems {
    NCButtonItem *item = [NCButtonItem itemWithTitle:NCUILocalizedString(@"group_action_dismiss")
                                          titleColor:NCDynamicColor(@"control_title_white_color")
                                     backgroundColor:NCDynamicColor(@"hint_color")];
    item.borderColor = NCDynamicColor(@"clear_color");
    __weak typeof(self) weakSelf = self;
    [item setClickBlock:^{
      [weakSelf dismissGroup];
    }];
    return @[ item ];
}

- (NSArray *)groupMemberItems {
    NCButtonItem *item = [NCButtonItem itemWithTitle:NCUILocalizedString(@"group_action_quit")
                                          titleColor:NCDynamicColor(@"control_title_white_color")
                                     backgroundColor:NCDynamicColor(@"hint_color")];
    item.borderColor = NCDynamicColor(@"clear_color");
    __weak typeof(self) weakSelf = self;
    [item setClickBlock:^{
      [weakSelf quitGroup];
    }];
    return @[ item ];
}

- (void)dismissGroup {
    __weak typeof(self) weakSelf = self;
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.channelId ?: @""];
    [channel dismissWithCompletion:^(NCError *_Nullable error) {
      if (error) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [NCAlertView showAlertController:nil
                                     message:NCUILocalizedString(@"group_dismiss_failed")
                            hiddenAfterDelay:2];
          });
          return;
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.responder.navigationController popViewControllerAnimated:YES];
        [NCAlertView showAlertController:nil
                                 message:NCUILocalizedString(@"group_dismiss_success")
                        hiddenAfterDelay:1];
      });
    }];
}

- (void)quitGroup {
    __weak typeof(self) weakSelf = self;
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.channelId ?: @""];
    [channel leaveWithConfig:nil
                  completion:^(NCError *_Nullable error) {
                    if (error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                          [NCAlertView showAlertController:nil
                                                   message:NCUILocalizedString(@"group_quit_failed")
                                          hiddenAfterDelay:2];
                        });
                        return;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                      [weakSelf.responder.navigationController popViewControllerAnimated:YES];
                      [NCAlertView showAlertController:nil
                                               message:NCUILocalizedString(@"group_quit_success")
                                      hiddenAfterDelay:2];
                    });
                  }];
}

- (void)addFriend:(NSString *)text {
    NCAddFriendParams *params = [[NCAddFriendParams alloc] initWithUserId:self.channelId ?: @""];
    params.extra = text;
    [[NCEngine userModule]
        addFriendWithParams:params
                 completion:^(NSInteger processCode, NCError *_Nullable error) {
                   if (error) {
                       dispatch_async(dispatch_get_main_queue(), ^{
                         [NCAlertView showAlertController:nil
                                                  message:NCUILocalizedString(@"add_friend_failed")
                                         hiddenAfterDelay:2];
                       });
                       return;
                   }
                   dispatch_async(dispatch_get_main_queue(), ^{
                     [NCAlertView
                         showAlertController:nil
                                     message:NCUILocalizedString(@"friend_request_has_sent")
                            hiddenAfterDelay:2];
                   });
                 }];
}
@end
