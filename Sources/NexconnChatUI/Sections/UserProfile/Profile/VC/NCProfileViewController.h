//
//  NCUUserProfileViewController.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCProfileViewModel.h"
NS_ASSUME_NONNULL_BEGIN

/// Profile view controller
@interface NCProfileViewController : NCBaseViewController

/// Creates an `NCProfileViewController` instance
///
/// @param viewModel viewModel
- (instancetype)initWithViewModel:(NCProfileViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
