//
//  NCChatUIThemeManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIThemeManager.h"
#import "NCChatUIBuiltInThemes.h"
#import "NCChatUIUtility.h"
#import "NCReadWriteLock.h"

@interface NCChatUIThemeManager () {
    NCChatUIBuiltInThemeType _innerThemesType;
    NCChatUITheme *_currentTheme;
}
@property (nonatomic, assign) NCChatUIBuiltInThemeType innerThemesType;
@property (nonatomic, strong) NCChatUILivelyThemes *livelyThemes;
@property (nonatomic, strong) NCChatUITheme *currentTheme;
@property (nonatomic, strong) NSHashTable *delegates;
@property (nonatomic, strong) NCReadWriteLock *lock;

/// Validates a built-in theme type.
/// - Parameter type: Built-in theme type.
/// - Returns: Whether the type is supported.
- (BOOL)isValidInnerThemesType:(NCChatUIBuiltInThemeType)type;

/// Returns the active built-in theme provider.
- (NCChatUIBuiltInThemes *)currentInnerThemes;

/// Notifies all delegates that the theme changed.
- (void)noticeThemeChanged;

@end

@implementation NCChatUIThemeManager

#pragma mark - Lifecycle

+ (instancetype)sharedInstance {
    static NCChatUIThemeManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _delegates = [NSHashTable weakObjectsHashTable];
        _lock = [NCReadWriteLock new];
        _innerThemesType = NCChatUIBuiltInThemeTypeLively; // Use the Lively theme by default.
    }
    return self;
}

#pragma mark - Public Class Methods

+ (NCChatUIBuiltInThemeType)currentInnerThemesType {
    return [[NCChatUIThemeManager sharedInstance] innerThemesType];
}

+ (BOOL)changeInnerTheme:(NCChatUIBuiltInThemeType)type {
    return [self changeCustomTheme:nil baseOnTheme:type];
}

+ (void)addThemeDelegate:(id<NCChatUIThemeDelegate>)delegate {
    [[NCChatUIThemeManager sharedInstance] addThemeDelegate:delegate];
}

+ (void)removeThemeDelegate:(id<NCChatUIThemeDelegate>)delegate {
    [[NCChatUIThemeManager sharedInstance] removeThemeDelegate:delegate];
}

+ (BOOL)changeCustomTheme:(NCChatUITheme *)theme
              baseOnTheme:(NCChatUIBuiltInThemeType)innerThemesType {
    return [[NCChatUIThemeManager sharedInstance] changeCustomTheme:theme
                                                        baseOnTheme:innerThemesType];
}

+ (UIColor *)dynamicColor:(NSString *)colorKey {
    return [[NCChatUIThemeManager sharedInstance] dynamicColor:colorKey];
}

+ (UIImage *)dynamicImage:(NSString *)imageKey {
    return [[NCChatUIThemeManager sharedInstance] dynamicImage:imageKey];
}

+ (UIColor *)dynamicColor:(NSString *)colorKey
              resourceKey:(NSString *)resourceKey
            originalColor:(NSString *)colorHex {
    return [[NCChatUIThemeManager sharedInstance] dynamicColor:colorKey
                                                   resourceKey:resourceKey
                                                 originalColor:colorHex];
}

#pragma mark - Delegate Management

/// Adds a theme change delegate.
/// - Parameter delegate: Delegate to add.
- (void)addThemeDelegate:(id<NCChatUIThemeDelegate>)delegate {
    if (!delegate) {
        return;
    }

    [self.lock performWriteLockBlock:^{
      if (![self.delegates containsObject:delegate]) {
          [self.delegates addObject:delegate];
      }
    }];
}

/// Removes a theme change delegate.
/// - Parameter delegate: Delegate to remove.
- (void)removeThemeDelegate:(id<NCChatUIThemeDelegate>)delegate {
    if (!delegate) {
        return;
    }

    [self.lock performWriteLockBlock:^{
      if ([self.delegates containsObject:delegate]) {
          [self.delegates removeObject:delegate];
      }
    }];
}

#pragma mark - Theme Configuration

/// Applies a custom theme over a built-in base theme.
/// - Parameters:
///   - theme: Custom theme, or nil to clear it.
///   - innerThemesType: Built-in theme used for missing resources.
/// - Returns: Whether the requested built-in theme is supported.
- (BOOL)changeCustomTheme:(NCChatUITheme *)theme
              baseOnTheme:(NCChatUIBuiltInThemeType)innerThemesType {
    // Validate the built-in theme type.
    if (![self isValidInnerThemesType:innerThemesType]) {
        return NO;
    }

    BOOL isSameInnerTheme = (innerThemesType == self.innerThemesType);
    BOOL isSameCustomTheme = (theme == self.currentTheme);

    if (isSameInnerTheme) {
        // The base is unchanged; update only the custom theme.
        self.currentTheme = theme;
    } else {
        if (isSameCustomTheme) {
            // The custom theme is unchanged; update only the base theme.
            self.innerThemesType = innerThemesType;
        } else {
            // Update the base without notifying, then set the custom theme and send one
            // notification.
            _innerThemesType = innerThemesType;
            self.currentTheme = theme;
        }
    }
    return YES;
}

#pragma mark - Dynamic Resource Access

/// Resolves a color from the active theme.
/// Without a custom theme, the built-in color follows light and dark mode; a missing custom color
/// uses the built-in light color.
/// - Parameter colorKey: Theme color key.
/// - Returns: The resolved color, or clear when unavailable.
- (UIColor *)dynamicColor:(NSString *)colorKey {
    UIColor *color = nil;
    NCChatUITheme *theme = self.currentTheme;
    NCChatUIBuiltInThemes *innerThemes = [self currentInnerThemes];

    if (theme) {
        // Prefer the custom theme.
        color = [theme dynamicColor:colorKey defaultColor:nil];
        if (!color) {
            // Fall back to the built-in light color.
            color = [innerThemes defaultColor:colorKey];
        }
    } else {
        // Use the trait-aware built-in color.
        color = [innerThemes dynamicColor:colorKey];
    }

    return color ?: [UIColor clearColor];
}

/// Resolves a color from the active theme with resource and hex fallbacks.
/// - Parameters:
///   - colorKey: Theme color key.
///   - resourceKey: Resource configuration key.
///   - colorHex: Final fallback hex color.
/// - Returns: The resolved theme color, resource fallback, or clear color.
- (UIColor *)dynamicColor:(NSString *)colorKey
              resourceKey:(NSString *)resourceKey
            originalColor:(NSString *)colorHex {
    UIColor *color = nil;
    UIColor *fallbackColor = [NCChatUIUtility color:resourceKey originalColor:colorHex];
    NCChatUITheme *theme = self.currentTheme;
    NCChatUIBuiltInThemes *innerThemes = [self currentInnerThemes];

    if (theme) {
        // Prefer the custom theme, using colorHex when its key is missing.
        color = [theme dynamicColor:colorKey defaultColor:colorHex];
        if (!color) {
            // Fall back to the built-in light color.
            color = [innerThemes defaultColor:colorKey];
        }
    } else {
        // Use the trait-aware built-in color.
        color = [innerThemes dynamicColor:colorKey];
    }
    return color ?: fallbackColor ?: [UIColor clearColor];
}

/// Resolves an image from the active theme.
/// A missing custom image uses the built-in light image; without a custom theme, the built-in image
/// follows light and dark mode.
/// - Parameter imageKey: Theme image key.
/// - Returns: The resolved image, or nil when unavailable.
- (UIImage *)dynamicImage:(NSString *)imageKey {
    NCChatUITheme *theme = self.currentTheme;
    NCChatUIBuiltInThemes *innerThemes = [self currentInnerThemes];
    UIImage *image = nil;
    if (theme) {
        UIImage *defaultImage = [innerThemes defaultImage:imageKey];
        image = [theme dynamicImage:imageKey defaultImage:defaultImage];

    } else {
        // Use the trait-aware built-in image.
        image = [innerThemes dynamicImage:imageKey];
    }

    return image;
}

#pragma mark - Private Methods

/// Validates a built-in theme type.
/// - Parameter type: Built-in theme type.
/// - Returns: Whether the type is supported.
- (BOOL)isValidInnerThemesType:(NCChatUIBuiltInThemeType)type {
    return type == NCChatUIBuiltInThemeTypeLively;
}

/// Returns the active built-in theme provider.
- (NCChatUIBuiltInThemes *)currentInnerThemes {
    return self.livelyThemes;
}

/// Notifies all delegates that the theme changed.
- (void)noticeThemeChanged {
    __block NSArray *delegates = nil;
    [self.lock performReadLockBlock:^{
      delegates = [self.delegates allObjects];
    }];

    for (id<NCChatUIThemeDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(themeDidChanged:baseOnTheme:)]) {
            [delegate themeDidChanged:self.currentTheme baseOnTheme:self.innerThemesType];
        }
    }
}

#pragma mark - Setters

- (void)setInnerThemesType:(NCChatUIBuiltInThemeType)innerThemesType {
    if (innerThemesType != _innerThemesType) {
        _innerThemesType = innerThemesType;
        [self noticeThemeChanged];
    }
}

- (void)setCurrentTheme:(NCChatUITheme *)currentTheme {
    if (currentTheme != _currentTheme) {
        _currentTheme = currentTheme;
        [self noticeThemeChanged];
    }
}

#pragma mark - Lazy Loading

- (NCChatUILivelyThemes *)livelyThemes {
    if (!_livelyThemes) {
        _livelyThemes = [NCChatUILivelyThemes new];
    }
    return _livelyThemes;
}

@end
