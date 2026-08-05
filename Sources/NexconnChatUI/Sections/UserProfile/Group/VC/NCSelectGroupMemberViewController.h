//
//  NCSelectGroupMemberViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCSelectGroupMemberViewModel.h"
NS_ASSUME_NONNULL_BEGIN
/// Select group member view controller
@interface NCSelectGroupMemberViewController : NCBaseViewController
/// Creates an `NCSelectGroupMemberViewController` instance
///
/// @param viewModel viewModel
- (instancetype)initWithViewModel:(NCSelectGroupMemberViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
