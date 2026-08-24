//
//  NCGroupNotificationCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"
#import "NCCellViewModelProtocol.h"
#import "NCListViewModelProtocol.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCGroupNotificationCellViewModel : NCBaseCellViewModel
/// Request info
@property (nonatomic, strong) NCGroupApplicationInfo *application;
/// Initializes the instance
- (instancetype)initWithApplicationInfo:(NCGroupApplicationInfo *)application;

/// Registers the cell
+ (void)registerCellForTableView:(UITableView *)tableView;

/// Binds the responder
- (void)bindResponder:(UIViewController<NCListViewModelResponder> *)responder;

/// Accepts the request
- (void)approveApplication;

/// Rejects the request
- (void)rejectApplication;
@end

NS_ASSUME_NONNULL_END
