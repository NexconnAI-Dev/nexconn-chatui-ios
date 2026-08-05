//
//  NCGroupCreateViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCGroupCreateViewModel.h"

NS_ASSUME_NONNULL_BEGIN
/// Group creation view controller
@interface NCGroupCreateViewController : NCBaseViewController

/// Creates an `NCGroupCreateViewController` instance
- (instancetype)initWithViewModel:(NCGroupCreateViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
