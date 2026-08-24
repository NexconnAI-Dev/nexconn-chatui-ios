//
//  NCUAddFriendViewController.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCUserSearchViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// User search view controller
///
@interface NCUserSearchViewController : NCBaseViewController

/// Initializes an `NCUserSearchViewController` instance
///
/// @param viewModel viewModel
- (instancetype)initWithViewModel:(NCUserSearchViewModel *)viewModel;
@end

NS_ASSUME_NONNULL_END
