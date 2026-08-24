//
//  NCMyGroupsViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//
#import "NCBaseViewController.h"
#import "NCMyGroupsViewModel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCMyGroupsViewController : NCBaseViewController
/// Creates an `NCMyGroupsViewController` instance
- (instancetype)initWithViewModel:(NCMyGroupsViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
