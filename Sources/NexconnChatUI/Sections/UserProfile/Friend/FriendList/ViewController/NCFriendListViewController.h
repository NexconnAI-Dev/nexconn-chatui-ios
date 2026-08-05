//
//  NCUFriendListViewController.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCFriendListViewModel.h"

NS_ASSUME_NONNULL_BEGIN
/// Friend list view controller
@interface NCFriendListViewController : NCBaseViewController

/// Creates an `NCFriendListViewController` instance
- (instancetype)initWithViewModel:(NCFriendListViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
