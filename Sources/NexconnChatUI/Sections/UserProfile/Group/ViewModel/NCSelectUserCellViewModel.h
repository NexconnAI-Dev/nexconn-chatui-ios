//
//  NCSelectUserCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"
#import "NCUserProfileDefine.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN
/// Select user cell view model
@interface NCSelectUserCellViewModel : NCBaseCellViewModel <NCCellViewModelProtocol>

/// Friend info
@property (nonatomic, strong, readonly) NCFriendInfo *friendInfo;

/// Current displayed selection state
@property (nonatomic, assign) NCSelectState selectState;

/// Registers the current cell
+ (void)registerCellForTableView:(UITableView *)tableView;

/// Creates an `NCSelectUserCellViewModel` instance
- (instancetype)initWithFriend:(NCFriendInfo *)friendInfo groupId:(NSString *)groupId;

/// Updates the cell
- (void)updateCell:(UITableViewCell *)cell state:(NCSelectState)state;
@end

NS_ASSUME_NONNULL_END
