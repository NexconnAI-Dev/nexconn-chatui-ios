//
//  NCGroupFollowCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN
@class NCGroupFollowCellViewModel;
@protocol NCGroupFollowCellViewModelDelegate <NSObject>
/// Called when the remove button is tapped.
- (void)actionButtonDidClick:(NCGroupFollowCellViewModel *)cellViewModel;

@end
/// cellViewModel
@interface NCGroupFollowCellViewModel : NCBaseCellViewModel<NCCellViewModelProtocol>
/// Group member.
@property (nonatomic, strong, readonly) NCGroupMemberInfo *memberInfo;

/// Remark, available only when a friend remark is set.
@property (nonatomic, copy, nullable) NSString *remark;

/// Delegate.
@property (nonatomic, weak) id<NCGroupFollowCellViewModelDelegate> delegate;

/// Whether to hide the button.
@property (nonatomic, assign) BOOL hiddenButton;

/// Registers the cell.
+ (void)registerCellForTableView:(UITableView *)tableView;

/// Creates an NCGroupFollowCellViewModel instance.
- (instancetype)initWithMember:(NCGroupMemberInfo *)memberInfo;

@end

NS_ASSUME_NONNULL_END
