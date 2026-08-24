//
//  NCMessageReadDetailView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageReadDetailTabView.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NCMessageReadDetailView;
@class NCMessageModel;

/// Read receipt detail view delegate protocol
@protocol NCMessageReadDetailViewDelegate <NSObject>

@optional

/// Called when the user switches a tab
/// @param view The current view
/// @param tabType The tab type to switch to
- (void)readReceiptUserListView:(NCMessageReadDetailView *)view
                 didSwitchToTab:(NCMessageReadDetailTabType)tabType;

/// Loads more data when needed
/// @param view The current view
/// @param tabType The current tab type
- (void)readReceiptUserListView:(NCMessageReadDetailView *)view
         needLoadMoreForTabType:(NCMessageReadDetailTabType)tabType;

@end

/// Read receipt detail view
@interface NCMessageReadDetailView : UIView

/// Delegate
@property (nonatomic, weak) id<NCMessageReadDetailViewDelegate> delegate;

/// Read/unread tab switch view
@property (nonatomic, strong, readonly) NCMessageReadDetailTabView *tabView;

/// Read users list view
@property (nonatomic, strong, readonly) UITableView *readTableView;

/// Unread users list view
@property (nonatomic, strong, readonly) UITableView *unreadTableView;

/// Initializes the instance
/// @param frame The frame
/// @param tabHeight The tab height
- (instancetype)initWithFrame:(CGRect)frame tabHeight:(CGFloat)tabHeight;

/// Sets the read/unread count for the tab
/// @param readCount The read count
/// @param unreadCount The unread count
- (void)setupReadCount:(NSInteger)readCount unreadCount:(NSInteger)unreadCount;

/// Switches the tab display
/// @param tabType The tab type
/// @param isEmpty Whether the current list is empty
- (void)switchToTabType:(NCMessageReadDetailTabType)tabType isEmpty:(BOOL)isEmpty;

/// Updates the empty state view text
/// @param text The text content
- (void)updateEmptyViewText:(NSString *)text;

/// Reloads the list data for the specified tab
/// @param tabType The tab type
/// @param hasMoreData Whether more data is available
- (void)reloadDataForTabType:(NCMessageReadDetailTabType)tabType hasMoreData:(BOOL)hasMoreData;

/// Returns the tab type for the given table view
/// @param tableView The UITableView instance
/// @return The tab type
- (NCMessageReadDetailTabType)tabTypeForTableView:(UITableView *)tableView;

@end

NS_ASSUME_NONNULL_END
