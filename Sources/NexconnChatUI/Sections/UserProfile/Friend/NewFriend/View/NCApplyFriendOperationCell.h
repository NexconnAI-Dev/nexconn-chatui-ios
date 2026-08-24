//
//  NCFriendApplyOperationCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCApplyFriendCell.h"

UIKIT_EXTERN NSString *_Nullable const NCFriendApplyOperationCellIdentifier;

NS_ASSUME_NONNULL_BEGIN
/// Friend request operation cell
@interface NCApplyFriendOperationCell : NCApplyFriendCell

/// Reject button
@property (nonatomic, strong) UIButton *btnReject;

/// Accept button
@property (nonatomic, strong) UIButton *btnApprove;

@end

NS_ASSUME_NONNULL_END
