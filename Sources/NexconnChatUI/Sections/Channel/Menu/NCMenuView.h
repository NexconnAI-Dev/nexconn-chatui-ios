//
//  NCMenuView.h
//  PopMenu
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NCMenuItem;

/**
 * NCMenuView is the container view for NCMenuItemView.
 * It uses UIStackView for a multi-row layout, with up to five menu items per row.
 */
@interface NCMenuView : UIView

/// The menu item array.
@property (nonatomic, strong, readonly) NSArray<NCMenuItem *> *menuItems;

/// The maximum number of menu items displayed per row. Defaults to 5.
@property (nonatomic, assign) NSInteger maxItemsPerRow;

/// The spacing between menu items. Defaults to 0.
@property (nonatomic, assign) CGFloat itemSpacing;

/// The spacing between rows. Defaults to 0.
@property (nonatomic, assign) CGFloat rowSpacing;

/**
 * Configures the view with the menu item array.
 * @param menuItems The menu item array.
 * @param actionHandler The menu item tap callback, with the tapped item and index.
 */
- (void)configureWithMenuItems:(NSArray<NCMenuItem *> *)menuItems
                 actionHandler:(void (^)(NCMenuItem *menuItem, NSInteger index))actionHandler;

@end

NS_ASSUME_NONNULL_END
