//
//  NCGroupCreateViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/// Group creation delegate
@protocol NCGroupCreateViewModelDelegate <NSObject>
/// Configures the group identifier
///
/// @return The group identifier
///
- (NSString *)generateGroupId;

@optional

/// Avatar tap callback
///
/// @param inViewController The current view controller
/// @param resultBlock Callback after avatar upload. The block receives the avatar URL.
///
- (void)groupPortraitDidClick:(UIViewController *)inViewController
                  resultBlock:(void (^)(NSString *portraitUrl))resultBlock;

/// Group creation success callback
///
/// @param group The created group
/// @param processCode When the group's `inviteHandlePermission` requires invitee acceptance,
/// `processCode` returns `NCChatUIErrorCodeGroupNeedInviteeAccept` (25427). When acceptance is not
/// required, `processCode` returns `NCChatUIErrorCodeSuccess` (0) and the invitee joins directly.
/// @param inViewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupCreateDidSuccess:(NCGroupInfo *)group
                  processCode:(NSInteger)processCode
             inViewController:(UIViewController *)inViewController;

@end

@protocol NCGroupCreateViewModelResponder <NSObject>

/// Avatar update callback (notifies UI to refresh)
///
/// @param avatarUrl The avatar URL
///
- (void)groupPortraitDidUpdate:(NSString *)avatarUrl;

@end

/// Group creation view model
@interface NCGroupCreateViewModel : NCBaseViewModel

/// Delegate
@property (nonatomic, weak) id<NCGroupCreateViewModelDelegate> delegate;

/// Responder
@property (nonatomic, weak) id<NCGroupCreateViewModelResponder> responder;

/// Group name length limit
@property (nonatomic, assign, readonly) NSInteger groupNameLimit;

/// Creates a group creation instance
///
/// @param inviteeUserIds The list of user identifiers to invite
+ (instancetype)viewModelWithInviteeUserIds:(NSArray<NSString *> *)inviteeUserIds;

/// Group creation view controller
///
/// @param groupName The group name
/// @param viewController The current view controller
- (void)createGroup:(NSString *)groupName inViewController:(UIViewController *)viewController;

/// Handles avatar tap event
- (void)portraitImageViewDidClick:(UIViewController *)inViewController;
;

@end

NS_ASSUME_NONNULL_END
