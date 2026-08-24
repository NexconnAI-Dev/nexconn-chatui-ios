//
//  NCMenuItem.h
//  PopMenu
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * NCMenuItem extends UIMenuItem with an image property.
 * Represents a menu item data model.
 */
@interface NCMenuItem : UIMenuItem

/// Icon image of the menu item
@property (nonatomic, strong, nullable) UIImage *image;

/**
 * Convenience initializer
 * @param title  The menu item title
 * @param image  The menu item icon
 * @param action The selector to invoke when the menu item is tapped
 */
- (instancetype)initWithTitle:(NSString *)title image:(nullable UIImage *)image action:(SEL)action;

+ (instancetype)menuItemWithItem:(UIMenuItem *)item;
@end

NS_ASSUME_NONNULL_END
