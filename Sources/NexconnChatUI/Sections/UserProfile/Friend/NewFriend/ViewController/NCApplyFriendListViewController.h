//
//  NCFriendApplyListViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCApplyFriendListViewModel.h"
#import "NCBaseViewController.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCApplyFriendListViewController : NCBaseViewController
- (instancetype)initWithViewModel:(NCApplyFriendListViewModel *)viewModel;
@end

NS_ASSUME_NONNULL_END
