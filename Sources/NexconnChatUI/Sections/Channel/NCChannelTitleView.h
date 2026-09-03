//
//  NCChannelTitleView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NCOnlineStatusView;

NS_ASSUME_NONNULL_BEGIN

/**
 * Channel navigation bar title view.
 *
 * @discussion
 *   - Supports displaying an online status indicator.
 *   - Supports displaying title text.
 *   - Uses UIStackView for layout.
 */
@interface NCChannelTitleView : UIView

/// Online status view.
@property (nonatomic, strong, readonly) NCOnlineStatusView *onlineStatusView;

/// Title label.
@property (nonatomic, strong, readonly) UILabel *titleLabel;

/**
 * Sets the title text.
 *
 * @param title Title text.
 */
- (void)setTitle:(NSString *)title;

/**
 * Updates the online status.
 *
 * @param isOnline YES for online, NO for offline.
 */
- (void)updateOnlineStatus:(BOOL)isOnline;

/// Hides the online status indicator for an unknown/unloaded status.
- (void)hideOnlineStatus;

@end

NS_ASSUME_NONNULL_END
