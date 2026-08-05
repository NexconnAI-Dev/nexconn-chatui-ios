//
//  NCFriendApplyCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCPaddingTableViewCell.h"
#import "NCApplyFriendCellViewModel.h"
#import "NCSizeCalculateLabel.h"
UIKIT_EXTERN NSString * _Nullable const NCFriendApplyCellIdentifier;
UIKIT_EXTERN NSInteger const NCFriendApplyCellMargin;

@class NCImageView;

NS_ASSUME_NONNULL_BEGIN

/// Friend request operation cell
@interface NCApplyFriendCell : NCPaddingTableViewCell
/*!
Avatar of the message sender
*/
@property (nonatomic, strong) NCImageView *portraitImageView;
@property (nonatomic, strong) UILabel *labName;
@property (nonatomic, strong) NCSizeCalculateLabel *labRemark;
@property (nonatomic, strong) UIButton *btnExpand;
@property (nonatomic, strong) UILabel *labStatus;
@property (nonatomic, strong) NCApplyFriendCellViewModel *viewModel;
/// Top container view with title and status buttons
@property (nonatomic, strong) UIStackView *topStackView;

- (void)updateWithViewModel:(NCApplyFriendCellViewModel *)viewModel;
@end
NS_ASSUME_NONNULL_END
