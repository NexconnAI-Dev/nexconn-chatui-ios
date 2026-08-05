//
//  NCMenuItemView.h
//  PopMenu
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NCMenuItem;

/**
 * NCMenuItemView is the view implementation for a single menu item.
 * It contains an icon and text, and supports tap events.
 */
@interface NCMenuItemView : UIView

/// The icon view.
@property (nonatomic, strong, readonly) UIImageView *iconImageView;

/// The title label.
@property (nonatomic, strong, readonly) UILabel *titleLabel;

/// The tap callback.
@property (nonatomic, copy, nullable) void (^actionHandler)(void);

/**
 * Configures the view with an NCMenuItem.
 * @param menuItem The menu item data model.
 */
- (void)configureWithMenuItem:(NCMenuItem *)menuItem;

@end

NS_ASSUME_NONNULL_END
