//
//  NCGroupNotificationCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPaddingTableViewCell.h"
#import "NCGroupNotificationCellViewModel.h"
@class NCImageView;
UIKIT_EXTERN NSString * _Nullable const NCGroupNotificationCellIdentifier;
UIKIT_EXTERN NSInteger const NCGroupNotificationCellHorizontalMargin;
UIKIT_EXTERN NSInteger const NCGroupNotificationCellPortraitWidth;
UIKIT_EXTERN NSInteger const NCGroupNotificationCellVerticalMargin;

NS_ASSUME_NONNULL_BEGIN

@interface NCGroupNotificationCell : NCPaddingTableViewCell
/*!
Avatar of the message sender
*/
@property (nonatomic, strong) NCImageView *portraitImageView;
@property (nonatomic, strong) UILabel *labName;
@property (nonatomic, strong) UILabel *labTips;
@property (nonatomic, strong) UILabel *labStatus;
@property (nonatomic, strong) NCGroupNotificationCellViewModel *viewModel;
/// Reject button
@property (nonatomic, strong) UIButton *btnReject;

/// Confirm button
@property (nonatomic, strong) UIButton *btnApprove;

/// Updates cell info
/// @param viewModel vm
- (void)updateWithViewModel:(NCGroupNotificationCellViewModel *)viewModel;

/// Whether to display the avatar
/// @param url The avatar URL
- (void)showPortrait:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
