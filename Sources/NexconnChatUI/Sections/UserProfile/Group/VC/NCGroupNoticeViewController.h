//
//  NCGroupNoticeViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCGroupNoticeViewModel.h"
NS_ASSUME_NONNULL_BEGIN
/// Group notice view controller
@interface NCGroupNoticeViewController : NCBaseViewController

/// Creates an `NCGroupNoticeViewController` instance
///
/// @param viewModel viewModel
- (instancetype)initWithViewModel:(NCGroupNoticeViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
