//
//  NCFriendListCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"
#import "NCCellViewModelProtocol.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
NS_ASSUME_NONNULL_BEGIN


/// Friend list cell view model
@interface NCFriendListCellViewModel : NCBaseCellViewModel<NCCellViewModelProtocol>

/// Friend info
@property (nonatomic, strong) NCFriendInfo *friendInfo;

/// Whether to display presence status
@property (nonatomic, assign) BOOL displayOnlineStatus;

/// Presence status
@property (nonatomic, strong) NCSubscribeUserOnlineStatus *onlineStatus;

/// Registers the cell
+ (void)registerCellForTableView:(UITableView *)tableView;

/// Initializes the instance
- (instancetype)initWithFriend:(NCFriendInfo  * _Nullable )friendInfo;

/// Refreshes the friend list
- (void)refreshWithFriend:(NCFriendInfo *)friendInfo;

/// Refreshes the presence status
- (void)refreshOnlineStatus:(NCSubscribeUserOnlineStatus *)onlineStatus;

@end

NS_ASSUME_NONNULL_END
