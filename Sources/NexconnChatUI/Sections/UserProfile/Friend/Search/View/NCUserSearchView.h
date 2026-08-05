//
//  NCAddFriendView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"

NS_ASSUME_NONNULL_BEGIN
/// Search view
@interface NCUserSearchView : NCBaseView

/// searchBar
@property (nonatomic, strong) UIView *searchBar;

/// Empty state view
@property (nonatomic, strong) UILabel *labEmpty;

/// Configures the search bar on the view
- (void)configureSearchBar:(UIView *)bar;

- (void)displayEmptyView:(BOOL)display;
@end

NS_ASSUME_NONNULL_END
