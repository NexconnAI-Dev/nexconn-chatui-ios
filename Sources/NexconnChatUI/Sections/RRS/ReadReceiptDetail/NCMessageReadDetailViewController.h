//
//  NCMessageReadDetailViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseViewController.h"
#import "NCMessageReadDetailViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class NCMessageReadDetailViewController;

/// Read receipt detail data source protocol
@protocol NCMessageReadDetailViewControllerDataSource <NSObject>

@optional

/// Returns the header view
/// @param viewController The current view controller
/// @param messageModel The message model
/// @return The header view, or `nil` to hide it
- (UIView *)viewController:(NCMessageReadDetailViewController *)viewController 
     headerViewWithMessage:(NCMessageModel *)messageModel;

@end

/// Read receipt detail view controller
@interface NCMessageReadDetailViewController : NCBaseViewController

/// Data source
@property (nonatomic, weak) id<NCMessageReadDetailViewControllerDataSource> dataSource;

/// Initializes the instance
/// @param viewModel The view model
- (instancetype)initWithViewModel:(NCMessageReadDetailViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
