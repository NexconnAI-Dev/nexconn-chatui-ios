//
//  NCNameEditViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCNameEditViewModel.h"
#import "NCAlertView.h"
#import "NCChatUI.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIErrorCode.h"
#import "NCInfoManagement.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#define NCNameOverSize 64
#define NCRemarkNameOverSize 32

@interface NCNameEditViewModel ()

@property (nonatomic, assign) NCNameEditType type;

@property (nonatomic, copy) NSString *userId;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, assign) NSInteger limit;

@end

@implementation NCNameEditViewModel
@dynamic delegate;

+ (instancetype)viewModelWithUserId:(NSString *)userId
                            groupId:(NSString *)groupId
                               type:(NCNameEditType)type {
    NCNameEditViewModel *viewModel = [[self.class alloc] init];
    viewModel.type = type;
    viewModel.userId = userId ?: @"";
    viewModel.groupId = groupId;
    if (type == NCNameEditTypeRemark) {
        viewModel.limit = NCRemarkNameOverSize;
    } else {
        viewModel.limit = NCNameOverSize;
    }
    return viewModel;
}

- (void)getCurrentName:(void (^)(NSString *))block {
    if (!block) {
        return;
    }
    switch (self.type) {
    case NCNameEditTypeName: {
        [[NCEngine userModule] getMyUserProfileWithCompletion:^(
                                   NCUserProfile *_Nullable userProfile, NCError *_Nullable error) {
          if (error) {
              block(@"");
              return;
          }
          block(userProfile.name);
        }];
    } break;
    case NCNameEditTypeRemark:
        if (self.userId) {
            [[NCEngine userModule]
                getFriendsInfoWithUserIds:@[ self.userId ]
                               completion:^(NSArray<NCFriendInfo *> *_Nullable friendInfos,
                                            NCError *_Nullable error) {
                                 if (error) {
                                     block(@"");
                                     return;
                                 }
                                 NSString *name = @"";
                                 if (friendInfos.count) {
                                     NCFriendInfo *info = [friendInfos firstObject];
                                     name = info.remark;
                                 }
                                 block(name);
                               }];
        }
        break;
    case NCNameEditTypeGroupMemberNickname: {
        if (self.userId && self.groupId) {
            NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId];
            [channel getMembersWithUserIds:@[ self.userId ]
                                completion:^(NSArray<NCGroupMemberInfo *> *_Nullable groupMembers,
                                             NCError *_Nullable error) {
                                  if (error) {
                                      block(@"");
                                      return;
                                  }
                                  NSString *name = @"";
                                  if (groupMembers.count) {
                                      NCGroupMemberInfo *info = [groupMembers firstObject];
                                      name = info.nickname;
                                  }
                                  block(name);
                                }];
        }
    } break;
    case NCNameEditTypeGroupName: {
        if (self.groupId) {
            [NCGroupChannel
                getGroupsInfoWithGroupIds:@[ self.groupId ]
                               completion:^(NSArray<NCGroupInfo *> *_Nullable groupInfos,
                                            NCError *_Nullable error) {
                                 if (error) {
                                     block(@"");
                                     return;
                                 }
                                 NSString *name = @"";
                                 if (groupInfos.count) {
                                     NCGroupInfo *info = [groupInfos firstObject];
                                     name = info.groupName;
                                 }
                                 block(name);
                               }];
        }
    } break;
    default:
        break;
    }
}
- (void)updateName:(NSString *)name {
    switch (self.type) {
    case NCNameEditTypeName:
        [self updateMyName:name];
        break;
    case NCNameEditTypeRemark:
        [self updateRemark:name];
        break;
    case NCNameEditTypeGroupMemberNickname:
        [self updateGroupMemberNickname:name];
        break;
    case NCNameEditTypeGroupName:
        [self updateGroupName:name];
        break;
    default:
        break;
    }
}

- (NSString *)title {
    if (!_title) {
        switch (self.type) {
        case NCNameEditTypeName:
            _title = NCUILocalizedString(@"name_edit_title");
            break;
        case NCNameEditTypeRemark:
            _title = NCUILocalizedString(@"remark_edit_title");
            break;
        case NCNameEditTypeGroupMemberNickname:
            _title = NCUILocalizedString(@"member_name_edit_title");
            break;
        case NCNameEditTypeGroupName:
            _title = NCUILocalizedString(@"group_name_edit_title");
            break;
        default:
            break;
        }
    }
    return _title;
}

- (NSString *)tip {
    if (!_tip) {
        switch (self.type) {
        case NCNameEditTypeGroupMemberNickname:
            _tip = NCUILocalizedString(@"member_name_edit_tip");
            break;
        default:
            break;
        }
    }
    return _tip;
}

- (NSString *)content {
    if (!_content) {
        switch (self.type) {
        case NCNameEditTypeName:
            _content = NCUILocalizedString(@"name");
            break;
        case NCNameEditTypeGroupMemberNickname:
            _content = NCUILocalizedString(@"group_member_nickname");
            break;
        case NCNameEditTypeRemark:
            _content = NCUILocalizedString(@"remark");
            break;
        case NCNameEditTypeGroupName:
            _content = NCUILocalizedString(@"group_name");
            break;
        default:
            break;
        }
    }
    return _content;
}

- (NSString *)placeHolder {
    if (!_placeHolder) {
        switch (self.type) {
        case NCNameEditTypeRemark:
            _placeHolder = NCUILocalizedString(@"remark_edit_placeholder");
            break;
        case NCNameEditTypeGroupName:
            _placeHolder = NCUILocalizedString(@"group_name_edit_placeholder");
            break;
        case NCNameEditTypeName:
            _placeHolder = NCUILocalizedString(@"input_name_placeholder");
            break;
        case NCNameEditTypeGroupMemberNickname:
            _placeHolder = NCUILocalizedString(@"input_nick_name_placeholder");
            break;
        default:
            break;
        }
    }
    return _placeHolder;
}

#pragma mark-- private

- (void)updateMyName:(NSString *)name {
    NCUserProfile *profile = [NCUserProfile new];
    profile.userId = self.userId ?: @"";
    profile.name = name;
    [self loadingWithTip:NCUILocalizedString(@"saving")];
    [[NCEngine userModule]
        updateMyUserProfile:profile
                 completion:^(NSArray<NSString *> *_Nullable errorKeys, NCError *_Nullable error) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                     [self stopLoading];
                     if (!error) {
                         [self updateDidComplete];
                         return;
                     }
                     if ([self.delegate respondsToSelector:@selector(nameUpdateDidError:)]) {
                         NSString *tips = NCUILocalizedString(@"set_failed");
                         if (error.code == NCChatUIErrorCodeInformationAuditFailed) {
                             tips = NCUILocalizedString(@"content_contains_sensitive");
                         }
                         [self.delegate nameUpdateDidError:tips];
                     }
                   });
                 }];
}

- (void)updateRemark:(NSString *)name {
    [self loadingWithTip:NCUILocalizedString(@"saving")];
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        [[NCInfoManagement sharedInstance] setFriendInfo:self.userId ?: @""
            remark:name
            extProfile:nil
            successBlock:^{
              dispatch_async(dispatch_get_main_queue(), ^{
                [self stopLoading];
                [self updateDidComplete];
              });
            }
            errorBlock:^(NSInteger errorCode, NSArray<NSString *> *_Nullable errorKeys) {
              (void)errorKeys;
              dispatch_async(dispatch_get_main_queue(), ^{
                [self stopLoading];
                if ([self.delegate respondsToSelector:@selector(nameUpdateDidError:)]) {
                    NSString *tips = NCUILocalizedString(@"set_failed");
                    if (errorCode == NCChatUIErrorCodeInformationAuditFailed) {
                        tips = NCUILocalizedString(@"content_contains_sensitive");
                    }
                    [self.delegate nameUpdateDidError:tips];
                }
              });
            }];
        return;
    }

    NCSetFriendInfoParams *params =
        [[NCSetFriendInfoParams alloc] initWithUserId:self.userId ?: @""];
    params.remark = name;
    [[NCEngine userModule]
        setFriendInfoWithParams:params
                     completion:^(NSArray<NSString *> *_Nullable errorKeys,
                                  NCError *_Nullable error) {
                       dispatch_async(dispatch_get_main_queue(), ^{
                         [self stopLoading];
                         if (!error) {
                             [self updateDidComplete];
                             return;
                         }
                         if ([self.delegate respondsToSelector:@selector(nameUpdateDidError:)]) {
                             NSString *tips = NCUILocalizedString(@"set_failed");
                             if (error.code == NCChatUIErrorCodeInformationAuditFailed) {
                                 tips = NCUILocalizedString(@"content_contains_sensitive");
                             }
                             [self.delegate nameUpdateDidError:tips];
                         }
                       });
                     }];
}

- (void)updateGroupMemberNickname:(NSString *)name {
    [self loadingWithTip:NCUILocalizedString(@"saving")];
    [[NCChatUI shared]
        setGroupMemberInfo:self.groupId ?: @""
                    userId:self.userId ?: @""
                  nickname:name
                     extra:nil
                completion:^(NSArray<NSString *> *_Nullable errorKeys, NCError *_Nullable error) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopLoading];
                    if (!error) {
                        [self updateDidComplete];
                        return;
                    }
                    if ([self.delegate respondsToSelector:@selector(nameUpdateDidError:)]) {
                        NSString *tips = NCUILocalizedString(@"set_failed");
                        if (error.code == NCChatUIErrorCodeInformationAuditFailed) {
                            tips = NCUILocalizedString(@"content_contains_sensitive");
                        }
                        [self.delegate nameUpdateDidError:tips];
                    }
                  });
                }];
}

- (void)updateGroupName:(NSString *)name {
    if (name.length == 0) {
        [NCAlertView showAlertController:nil
                                 message:NCUILocalizedString(@"group_name_empty_tip")
                        hiddenAfterDelay:2];
        return;
    }

    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId ?: @""];
    NCUpdateGroupInfoParams *params = [NCUpdateGroupInfoParams new];
    params.groupName = name;

    [self loadingWithTip:NCUILocalizedString(@"saving")];
    [channel
        updateInfoWithParams:params
                  completion:^(NSArray<NSString *> *_Nullable errorKeys, NCError *_Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                      [self stopLoading];
                      if (!error) {
                          [self updateDidComplete];
                          return;
                      }
                      if ([self.delegate respondsToSelector:@selector(nameUpdateDidError:)]) {
                          NSString *tips = NCUILocalizedString(@"set_failed");
                          if (error.code == NCChatUIErrorCodeInformationAuditFailed) {
                              tips = NCUILocalizedString(@"content_contains_sensitive");
                          }
                          [self.delegate nameUpdateDidError:tips];
                      }
                    });
                  }];
}

- (void)updateDidComplete {
    dispatch_async(dispatch_get_main_queue(), ^{
      if ([self.delegate respondsToSelector:@selector(nameUpdateDidSuccess)]) {
          [self.delegate nameUpdateDidSuccess];
      }
    });
}
@end
