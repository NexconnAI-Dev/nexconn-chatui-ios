//
//  NCChatUIBuiltInThemes.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIBuiltInThemes.h"
#import "UIColor+NCIMHexColor.h"

// Theme name constants.
NSString *const NCChatUIThemeNameLight = @"light";
NSString *const NCChatUIThemeNameDark = @"dark";

// Lively theme resource bundle name.
static NSString * const kLivelyThemeBundleName = @"NCChatUILively";

#pragma mark - NCChatUIBuiltInThemes

@interface NCChatUIBuiltInThemes()
@end

@implementation NCChatUIBuiltInThemes

- (UIColor *)dynamicColor:(NSString *)colorKey {
    // Subclasses provide the built-in color implementation.
    return [UIColor clearColor];
}

- (UIImage *)dynamicImage:(NSString *)imageKey {
    // Subclasses provide the built-in image implementation.
    return nil;
}

- (UIColor *)defaultColor:(NSString *)colorKey {
    // Subclasses provide the default color implementation.
    return [UIColor clearColor];
}

- (UIImage *)defaultImage:(NSString *)imageKey {
    // Subclasses provide the default image implementation.
    return nil;
}

@end

#pragma mark - NCChatUILivelyThemes

@interface NCChatUILivelyThemes()

/// Light theme resources.
@property (nonatomic, strong) NCChatUITheme *lightTheme;

/// Dark theme resources.
@property (nonatomic, strong) NCChatUITheme *darkTheme;

@end

@implementation NCChatUILivelyThemes

#pragma mark - Public Methods

/// Returns a trait-aware Lively theme color.
/// Dark mode falls back to the light color, then clear when the key is unavailable.
/// - Parameter colorKey: Lively theme color key.
/// - Returns: A trait-aware color.
- (UIColor *)dynamicColor:(NSString *)colorKey {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *_Nonnull(UITraitCollection *_Nonnull traitCollection) {
            UIColor *lightColor = [self.lightTheme dynamicColor:colorKey defaultColor:nil];
            switch (traitCollection.userInterfaceStyle) {
                case UIUserInterfaceStyleDark:
                    return [self.darkTheme dynamicColor:colorKey defaultColor:nil] ?: lightColor ?: [UIColor clearColor];

                case UIUserInterfaceStyleLight:
                case UIUserInterfaceStyleUnspecified:
                default:
                    return lightColor ?: [UIColor clearColor];
            }
        }];
    } else {
        // Earlier systems use the light color because they do not support dark mode.
        return [self.lightTheme dynamicColor:colorKey defaultColor:nil] ?: [UIColor clearColor];
    }
}

/// Returns the light-mode Lively theme color.
/// - Parameter colorKey: Lively theme color key.
/// - Returns: The light color, or nil when the key is unavailable.
- (UIColor *)defaultColor:(NSString *)colorKey {
    return [self.lightTheme dynamicColor:colorKey defaultColor:nil];
}

/// Returns a trait-aware Lively theme image when both variants are available.
/// On iOS 13 and later, a missing variant falls back to the available image; earlier systems use the light image.
/// - Parameter imageKey: Lively theme image key.
/// - Returns: The resolved image, or nil when no usable variant exists.
- (UIImage *)dynamicImage:(NSString *)imageKey {
    UIImage *lightImage = [self.lightTheme dynamicImage:imageKey defaultImage:nil];
    UIImage *darkImage = [self.darkTheme dynamicImage:imageKey defaultImage:nil];
    return [self combinedImageWithLight:lightImage dark:darkImage];
}

/// Returns the light-mode Lively theme image.
/// - Parameter imageKey: Lively theme image key.
/// - Returns: The light image, or nil when the key is unavailable.
- (UIImage *)defaultImage:(NSString *)imageKey {
    return [self.lightTheme dynamicImage:imageKey defaultImage:nil];
}

#pragma mark - Private Methods

/// Combines light and dark image variants into a trait-aware image on iOS 13 and later.
/// - Parameters:
///   - lightImage: Light-mode image.
///   - darkImage: Dark-mode image.
/// - Returns: A trait-aware image, the only available variant, or the light image on earlier systems.
- (UIImage *)combinedImageWithLight:(UIImage *)lightImage
                               dark:(UIImage *)darkImage {
    if (@available(iOS 13.0, *)) {
        if (!lightImage) {
            return darkImage;
        }
        if (!darkImage) {
            return lightImage;
        }

        // Preserve the current screen scale in the dark trait registration.
        CGFloat scale = [UIScreen mainScreen].scale;
        UITraitCollection *scaleTraitCollection = [UITraitCollection traitCollectionWithDisplayScale:scale];

        // Create the light-mode trait collection.
        UITraitCollection *lightTraitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];

        // Create a dark-mode trait collection that includes the display scale.
        UITraitCollection *darkUnscaledTraitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
        UITraitCollection *darkScaledTraitCollection = [UITraitCollection traitCollectionWithTraitsFromCollections:@[scaleTraitCollection, darkUnscaledTraitCollection]];

        // Configure the light image for light mode.
        UIImage *configuredLightImage = [lightImage imageWithConfiguration:[lightImage.configuration configurationWithTraitCollection:lightTraitCollection]];

        // Configure the dark image for dark mode and the current scale.
        UIImage *configuredDarkImage = [darkImage imageWithConfiguration:[darkImage.configuration configurationWithTraitCollection:darkScaledTraitCollection]];

        // Register the dark variant in the light image's asset.
        [configuredLightImage.imageAsset registerImage:configuredDarkImage withTraitCollection:darkScaledTraitCollection];

        return configuredLightImage;
    } else {
        // Earlier systems do not support trait-based image variants.
        return lightImage;
    }
}

/// Builds the path to a theme directory in the Lively resource bundle.
/// - Parameter themeName: Theme name.
/// - Returns: Theme directory path.
- (NSString *)pathForTheme:(NSString *)themeName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *bundlePath = [bundle pathForResource:kLivelyThemeBundleName ofType:@"bundle"];
    NSString *themePath = [bundlePath stringByAppendingPathComponent:themeName];
    return themePath;
}

#pragma mark - Lazy Loading

- (NCChatUITheme *)lightTheme {
    if (!_lightTheme) {
        NSString *path = [self pathForTheme:NCChatUIThemeNameLight];
        _lightTheme = [[NCChatUITheme alloc] initWithThemePath:path];
    }
    return _lightTheme;
}

- (NCChatUITheme *)darkTheme {
    if (!_darkTheme) {
        NSString *path = [self pathForTheme:NCChatUIThemeNameDark];
        _darkTheme = [[NCChatUITheme alloc] initWithThemePath:path];
    }
    return _darkTheme;
}

@end
