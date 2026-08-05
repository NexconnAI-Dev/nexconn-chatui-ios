//
//  NCGroupTransferOwnerViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCGroupTransferViewModel.h"
NS_ASSUME_NONNULL_BEGIN
/// Group ownership transfer view controller
@interface NCGroupTransferViewController : NCBaseViewController
/// Creates an `NCGroupTransferViewController` instance
///
/// @param viewModel viewModel
- (instancetype)initWithViewModel:(NCGroupTransferViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
