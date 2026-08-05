//
//  NCGroupManagersController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCGroupManagerListViewModel.h"

NS_ASSUME_NONNULL_BEGIN
/// Group admin list view controller
@interface NCGroupManagerListController : NCBaseViewController
/// Creates an `NCGroupManagerListController` instance
///
/// @param viewModel viewModel
- (instancetype)initWithViewModel:(NCGroupManagerListViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
