//
//  NCChatUIThemeManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUITheme.h"
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NCChatUIBuiltInThemeType) {
    NCChatUIBuiltInThemeTypeLively // Lively theme
};

@protocol NCChatUIThemeDelegate <NSObject>

/// Called when the theme changes.
/// @param customTheme The new custom theme (nil if no custom theme is set).
/// @param type The new built-in theme type.
- (void)themeDidChanged:(NCChatUITheme *)customTheme baseOnTheme:(NCChatUIBuiltInThemeType)type;

@end

@interface NCChatUIThemeManager : NSObject

/// Add a theme change delegate.
/// @param delegate The delegate.
+ (void)addThemeDelegate:(id<NCChatUIThemeDelegate>)delegate;

/// Remove a theme change delegate.
/// @param delegate The delegate.
+ (void)removeThemeDelegate:(id<NCChatUIThemeDelegate>)delegate;

/// The current built-in theme type.
+ (NCChatUIBuiltInThemeType)currentInnerThemesType;

/// Change the built-in theme.
/// @param type The theme type.
+ (BOOL)changeInnerTheme:(NCChatUIBuiltInThemeType)type;

/// Change the custom theme.
/// @param theme The custom theme.
/// @param innerThemesType The built-in theme type that this custom theme is based on.
+ (BOOL)changeCustomTheme:(nullable NCChatUITheme *)theme
              baseOnTheme:(NCChatUIBuiltInThemeType)innerThemesType;

/// Get a dynamic color.
/// @param colorKey Lively theme color key.
+ (UIColor *)dynamicColor:(nullable NSString *)colorKey;

/// Get a dynamic image.
/// @param imageKey Lively theme image key.
+ (UIImage *)dynamicImage:(nullable NSString *)imageKey;

/// Get a dynamic color.
/// @param colorKey Lively theme color key.
/// @param resourceKey Resource configuration key string.
/// @param colorHex Default color hex.
+ (UIColor *)dynamicColor:(nullable NSString *)colorKey
              resourceKey:(nullable NSString *)resourceKey
            originalColor:(nullable NSString *)colorHex;
@end

NS_ASSUME_NONNULL_END
