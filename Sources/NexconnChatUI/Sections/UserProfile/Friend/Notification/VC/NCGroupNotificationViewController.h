//
//  NCGroupNotificationViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCGroupNotificationViewModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface NCGroupNotificationViewController : NCBaseViewController
/// Creates an `NCGroupNotificationViewController` instance
- (instancetype)initWithViewModel:(NCGroupNotificationViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
