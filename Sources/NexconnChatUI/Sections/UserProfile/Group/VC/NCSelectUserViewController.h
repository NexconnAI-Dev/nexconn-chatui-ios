//
//  NCSelectUserViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCSelectUserViewModel.h"
NS_ASSUME_NONNULL_BEGIN
/// Select user view controller
@interface NCSelectUserViewController : NCBaseViewController

/// Creates an `NCSelectUserViewController` instance
- (instancetype)initWithViewModel:(NCSelectUserViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
