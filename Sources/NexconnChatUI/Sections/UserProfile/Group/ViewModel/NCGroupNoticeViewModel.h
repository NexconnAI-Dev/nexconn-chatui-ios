//
//  NCGroupNoticeViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN
@class NCGroupNoticeViewModel;
/// Group notice delegate
@protocol NCGroupNoticeViewModelDelegate <NSObject>

@optional

/// Called when the group notice is about to change
///
/// @param updatedGroup The updated group info
/// @param viewModel NCGroupNoticeViewModel
/// @param inViewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupNoticeWillUpdate:(NCGroupInfo *)updatedGroup
                    viewModel:(NCGroupNoticeViewModel *)viewModel
             inViewController:(UIViewController *)inViewController;

/// Called when the group notice has changed
///
/// @param updatedGroup The updated group info
/// @param viewModel NCGroupNoticeViewModel
/// @param inViewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupNoticeDidUpdate:(NCGroupInfo *)updatedGroup
                 viewModel:(NCGroupNoticeViewModel *)viewModel
          inViewController:(UIViewController *)inViewController;

@end

/// Group notice view model
@interface NCGroupNoticeViewModel : NCBaseViewModel

/// Delegate
@property (nonatomic, weak) id<NCGroupNoticeViewModelDelegate> delegate;

/// Group info
@property (nonatomic, strong, readonly) NCGroupInfo *group;

/// Whether the view is editable
@property (nonatomic, assign, readonly) BOOL canEdit;

/// Group notice text length limit. Defaults to 1024.
@property (nonatomic, assign, readonly) NSInteger limit;

/// Initializes the instance
///
/// @param group The group info
- (instancetype)initWithGroup:(NCGroupInfo *)group;

/// Updates the group notice
///
/// @param notice The group notice text
/// @param viewController The current view controller
- (void)updateNotice:(NSString *)notice inViewController:(UIViewController *)viewController;

/// Whether the given notice text can be saved.
///
/// Returns `YES` only when editing is allowed, the trimmed text is non-empty,
/// and the trimmed text differs from the current notice.
///
/// @param notice The group notice text to evaluate
/// @return `YES` if the notice can be saved
- (BOOL)canSaveNotice:(NSString *)notice;

/// Tip text
///
/// @return The tip text
- (NSString *)tip;

@end

NS_ASSUME_NONNULL_END
