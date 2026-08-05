//
//  NCMenuViewController.h
//  PopMenu
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NCMenuItem;

/**
 * NCMenuViewController controls showing and hiding NCMenuView.
 * Its behavior is similar to UIMenuController, with a triangular indicator.
 */
@interface NCMenuController : NSObject

/// Singleton instance.
+ (instancetype)sharedMenuController;

/// Whether the menu is visible.
@property (nonatomic, assign, readonly, getter=isMenuVisible) BOOL menuVisible;

/**
 * Shows the menu from the specified view.
 * @param targetView The target view that triggers the menu.
 * @param menuItems The menu item array.
 * @param actionHandler The menu item tap callback.
 */
- (void)showMenuFromView:(UIView *)targetView
               menuItems:(NSArray<UIMenuItem *> *)menuItems
           actionHandler:(void (^)(NCMenuItem *menuItem, NSInteger index))actionHandler;

/**
 * Shows the menu from the specified view and rectangle.
 * @param targetRect The target rectangle in targetView's coordinate system.
 * @param targetView The target view that triggers the menu.
 * @param menuItems The menu item array.
 * @param actionHandler The menu item tap callback.
 */
- (void)showMenuFromRect:(CGRect)targetRect
                  inView:(UIView *)targetView
               menuItems:(NSArray<NCMenuItem *> *)menuItems
           actionHandler:(void (^)(NCMenuItem *menuItem, NSInteger index))actionHandler;

/**
 * Hides the menu.
 * @param animated Whether to animate the change.
 */
- (void)hideMenuAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
