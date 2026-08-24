//
//  NCGroupMembersCollectionViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCCollectionViewModelProtocol.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN

#define NCGroupMembersCollectionViewModelItemWidth 48
#define NCGroupMembersCollectionViewModelItemHeight 70
#define NCGroupMembersCollectionViewModelLineSpace 12
#define NCGroupMembersCollectionViewModelPortraitLineCount 5

@class NCGroupMembersCollectionViewModel;
@protocol NCGroupMembersCollectionViewModelDelegate <NSObject>

@optional
/// Handles tap on a group member's avatar
///
/// @param viewModel viewModel
/// @param viewController The current view controller
/// @param member The member info
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupMembersCollectionViewModel:(NCGroupMembersCollectionViewModel *)viewModel
                         viewController:(UIViewController *)viewController
                        didSelectMember:(NCGroupMemberInfo *)member;

/// Handles tap on add button
///
/// @param viewModel viewModel
/// @param viewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupMembersCollectionViewModel:(NCGroupMembersCollectionViewModel *)viewModel
                           didSelectAdd:(UIViewController *)viewController;

/// Handles tap on remove button
///
/// @param viewModel viewModel
/// @param viewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupMembersCollectionViewModel:(NCGroupMembersCollectionViewModel *)viewModel
                        didSelectRemove:(UIViewController *)viewController;

/// Adds group members
///
/// @param viewModel viewModel
/// @param viewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupMembersCollectionViewModel:(NCGroupMembersCollectionViewModel *)viewModel
                         didInviteUsers:(NSArray<NSString *> *)userIds
                            processCode:(NSInteger)processCode
                         viewController:(UIViewController *)viewController;
@end

/// Group profile members cell view model
@interface NCGroupMembersCollectionViewModel : NCBaseViewModel <NCCollectionViewModelProtocol>

/// Delegate
@property (nonatomic, weak) id<NCGroupMembersCollectionViewModelDelegate> delegate;

/// Delegate
@property (nonatomic, weak) id<NCCollectionViewModelResponder> responder;

/// Group identifier
@property (nonatomic, copy, readonly) NSString *groupId;

/// Data source
@property (nonatomic, strong, readonly) NSArray<NCGroupMemberInfo *> *members;

/// Whether adding members is allowed
@property (nonatomic, assign, readonly) BOOL allowAdd;

/// Whether removing members is allowed
@property (nonatomic, assign, readonly) BOOL allowRemove;

/// Creates an `NCGroupProfileMembersCellViewModel` instance
///
/// @param groupId The group identifier
/// @param members The data source
/// @param allowAdd Whether adding members is allowed
/// @param allowRemove Whether removing members is allowed
/// @param inViewController The current view controller
+ (instancetype)viewModelWithGroupId:(NSString *)groupId
                             members:(NSArray<NCGroupMemberInfo *> *)members
                            allowAdd:(BOOL)allowAdd
                         allowRemove:(BOOL)allowRemove
                    inViewController:(UIViewController *)inViewController;

+ (void)registerCollectionViewCell:(UICollectionView *)collectionView;

@end

NS_ASSUME_NONNULL_END
