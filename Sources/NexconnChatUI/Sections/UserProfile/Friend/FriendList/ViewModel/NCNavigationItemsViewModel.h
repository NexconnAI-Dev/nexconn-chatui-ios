//
//  NCUFriendListNaviItemsViewModel.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseViewModel.h"

NS_ASSUME_NONNULL_BEGIN
/// Navigation items view model
@interface NCNavigationItemsViewModel : NCBaseViewModel

/// Responder
@property (nonatomic, weak) UIViewController *responder;

/// Initializes the instance
- (instancetype)initWithResponder:(UIViewController *)responder;

/// Right navigation button
- (NSArray *)rightNavigationBarItems;
@end

NS_ASSUME_NONNULL_END
