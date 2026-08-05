//
//  NCButtonItemModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

/// Button item model
@interface NCButtonItem : NSObject

/// Button title
@property (nonatomic, copy, nullable) NSString *title;

/// Button title color
@property (nonatomic, strong, nullable) UIColor *titleColor;

/// Button background color
@property (nonatomic, strong, nullable) UIColor *backgroundColor;

/// Button border color
@property (nonatomic, strong, nullable) UIColor *borderColor;

/// Button icon image
@property (nonatomic, strong, nullable) UIImage *buttonIcon;

/// Button tap callback
@property (nonatomic, copy) void (^clickBlock)(void);

/// Creates an `NCButtonItem` instance
///
/// @param title The button title
/// @param titleColor The button title color
/// @param backgroundColor The button background color
+ (instancetype)itemWithTitle:(NSString *)title
                   titleColor:(nullable UIColor *)titleColor
              backgroundColor:(nullable UIColor *)backgroundColor;

@end

NS_ASSUME_NONNULL_END
