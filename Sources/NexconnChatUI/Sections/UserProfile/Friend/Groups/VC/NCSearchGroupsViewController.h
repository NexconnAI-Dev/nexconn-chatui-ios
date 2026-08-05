//
//  NCSearchGroupsViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCSearchGroupsViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCSearchGroupsViewController : NCBaseViewController
/// Creates an `NCSearchGroupsViewController` instance
- (instancetype)initWithViewModel:(NCSearchGroupsViewModel *)viewModel;
@end

NS_ASSUME_NONNULL_END
