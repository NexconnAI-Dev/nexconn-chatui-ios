//
//  NCGroupManagementViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCGroupManagementViewModel.h"

NS_ASSUME_NONNULL_BEGIN
/// Group management view controller
@interface NCGroupManagementViewController : NCBaseViewController
/// Creates an `NCGroupManagementViewController` instance
///
/// @param viewModel viewModel
- (instancetype)initWithViewModel:(NCGroupManagementViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
