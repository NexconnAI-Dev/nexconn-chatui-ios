//
//  NCGroupFollowsViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCGroupFollowsViewModel.h"

NS_ASSUME_NONNULL_BEGIN
/// Group favorites view controller
@interface NCGroupFollowsViewController : NCBaseViewController
/// Creates an `NCGroupFollowsViewController` instance
///
/// @param viewModel viewModel
- (instancetype)initWithViewModel:(NCGroupFollowsViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
