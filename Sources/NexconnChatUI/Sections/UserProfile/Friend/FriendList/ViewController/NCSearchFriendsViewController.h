//
//  NCSearchFriendsViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//
#import "NCBaseViewController.h"
#import "NCSearchFriendsViewModel.h"

NS_ASSUME_NONNULL_BEGIN
/// Search friends view controller
@interface NCSearchFriendsViewController : NCBaseViewController

/// Creates an `NCSearchFriendsViewController` instance
- (instancetype)initWithViewModel:(NCSearchFriendsViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
