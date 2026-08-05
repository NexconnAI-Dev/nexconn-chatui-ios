//
//  NCGroupNotificationView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSearchBarListView.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCGroupNotificationView : NCSearchBarListView
/// Adds the refresh event handler
- (void)addRefreshingTarget:(id)target withSelector:(SEL)selector;

/// Stops the refresh indicator
- (void)stopRefreshing;
@end

NS_ASSUME_NONNULL_END
