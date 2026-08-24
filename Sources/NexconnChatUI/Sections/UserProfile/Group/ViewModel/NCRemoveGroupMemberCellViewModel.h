//
//  NCSelectGroupMemberCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"
#import "NCUserProfileDefine.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN
/// Select group member cell
@interface NCRemoveGroupMemberCellViewModel : NCBaseCellViewModel <NCCellViewModelProtocol>

/// Group member
@property (nonatomic, strong, readonly) NCGroupMemberInfo *member;

/// Remark (available only if set by the friend)
@property (nonatomic, strong, nullable) NSString *remark;

/// Cell current selection state
@property (nonatomic, assign, readonly) NCSelectState selectState;

/// Whether to hide the role label
@property (nonatomic, assign) BOOL hiddenRole;

/// Registers the cell
+ (void)registerCellForTableView:(UITableView *)tableView;

/// Creates an `NCRemoveGroupMemberCellViewModel` instance
- (instancetype)initWithMember:(NCGroupMemberInfo *)member;

/// Updates the cell
- (void)updateCell:(UITableViewCell *)cell state:(NCSelectState)state;

@end

NS_ASSUME_NONNULL_END
