//
//  NCChatUITheme.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUITheme.h"
#import "UIColor+NCIMHexColor.h"
#import <NexconnChatUI/NCChatUILog.h>

// Theme file constants.
static NSString *const kThemePlistFileName = @"theme.plist";
static NSString *const kThemeResourcesDirectoryName = @"resources";

// Theme configuration keys.
static NSString *const kThemeNameKey = @"name";
static NSString *const kThemeColorsKey = @"colors";
static NSString *const kThemeImagesKey = @"images";

@interface NCChatUITheme ()

@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSString *> *colors;
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSString *> *images;
@property (nonatomic, copy, readwrite) NSString *resourcePath;
@property (nonatomic, copy, readwrite) NSString *plistPath;

/// Resolves an existing image path by preferred screen scale, then falls back across @2x, @3x, and
/// unscaled files.
- (nullable NSString *)resolvedImagePathForImageName:(NSString *)imageName;

@end

@implementation NCChatUITheme

#pragma mark - Lifecycle

- (instancetype)initWithThemePath:(NSString *)path {
    if (self = [super init]) {
        [self loadDataWithPath:path];
    }
    return self;
}

#pragma mark - Private Methods

/// Loads theme data from a directory.
/// - Parameter path: Theme directory path.
- (void)loadDataWithPath:(NSString *)path {
    // Validate the theme path.
    if (!path || path.length == 0) {
        NCLogE(@"[NCChatUITheme] theme path is invalid");
        return;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        NCLogE(@"[NCChatUITheme] theme path does not exist: %@", path);
        return;
    }

    // Validate the theme plist.
    NSString *plistPath = [path stringByAppendingPathComponent:kThemePlistFileName];
    if (![fileManager fileExistsAtPath:plistPath]) {
        NCLogE(@"[NCChatUITheme] theme plist file is not found: %@", plistPath);
        return;
    }

    // Validate the resource directory.
    NSString *resourcePath = [path stringByAppendingPathComponent:kThemeResourcesDirectoryName];
    if (![fileManager fileExistsAtPath:resourcePath]) {
        NCLogE(@"[NCChatUITheme] theme resources directory is not found: %@", resourcePath);
        return;
    }

    // Load and validate the plist contents.
    NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    if (![themeDict isKindOfClass:[NSDictionary class]]) {
        NCLogE(@"[NCChatUITheme] theme plist file format is invalid: %@", plistPath);
        return;
    }

    // Parse the theme configuration.
    [self parseThemeConfiguration:themeDict];

    // Store the validated paths.
    self.resourcePath = resourcePath;
    self.plistPath = plistPath;
}

/// Parses a theme configuration dictionary.
/// - Parameter themeDict: Theme configuration dictionary.
- (void)parseThemeConfiguration:(NSDictionary *)themeDict {
    // Parse the theme name.
    id nameValue = themeDict[kThemeNameKey];
    if ([nameValue isKindOfClass:[NSString class]]) {
        self.name = nameValue;
    }

    // Parse color entries.
    id colorsValue = themeDict[kThemeColorsKey];
    if ([colorsValue isKindOfClass:[NSDictionary class]]) {
        self.colors = colorsValue;
    }

    // Parse image entries.
    id imagesValue = themeDict[kThemeImagesKey];
    if ([imagesValue isKindOfClass:[NSDictionary class]]) {
        self.images = imagesValue;
    }
}

#pragma mark - Public Methods

/// Resolves a configured theme color with an optional hex fallback.
/// - Parameters:
///   - colorKey: Theme color key.
///   - hex: Fallback hex color.
/// - Returns: The configured color, the hex fallback, or nil when neither can be resolved.
- (UIColor *)dynamicColor:(NSString *)colorKey defaultColor:(NSString *)hex {
    // Validate the key.
    if (![self isValidStringKey:colorKey]) {
        return nil;
    }

    // Prefer the configured theme color.
    UIColor *color = [self colorFromThemeWithKey:colorKey];

    // Use the supplied hex fallback when the theme has no usable color.
    if (!color && hex) {
        color = [UIColor ncui_colorWithHex:hex];
    }

    return color;
}

/// Resolves a configured theme image with an optional image fallback.
/// - Parameters:
///   - imageKey: Theme image key.
///   - defaultImage: Fallback image.
/// - Returns: The configured image, or defaultImage when the key or file cannot be resolved.
- (UIImage *)dynamicImage:(NSString *)imageKey defaultImage:(UIImage *)defaultImage {
    // Validate the key.
    if (![self isValidStringKey:imageKey]) {
        return defaultImage;
    }

    // Prefer the configured theme image.
    UIImage *image = [self imageFromThemeWithKey:imageKey];

    // Fall back when the theme has no usable image.
    return image ?: defaultImage;
}

#pragma mark - Helper Methods

/// Validates a string key.
/// - Parameter key: Candidate key.
/// - Returns: Whether the key is a nonempty string.
- (BOOL)isValidStringKey:(NSString *)key {
    return [key isKindOfClass:[NSString class]] && key.length > 0;
}

/// Resolves a color from the theme configuration.
/// - Parameter colorKey: Theme color key.
/// - Returns: The configured color, or nil when unavailable.
- (UIColor *)colorFromThemeWithKey:(NSString *)colorKey {
    NSString *colorHex = self.colors[colorKey];
    if ([colorHex isKindOfClass:[NSString class]] && colorHex.length > 0) {
        return [UIColor ncui_colorWithHex:colorHex];
    }
    return nil;
}

/// Resolves an image from the theme configuration and resource directory.
/// - Parameter imageKey: Theme image key.
/// - Returns: The configured image, or nil when unavailable.
- (UIImage *)imageFromThemeWithKey:(NSString *)imageKey {
    NSString *imageName = self.images[imageKey];
    if (![imageName isKindOfClass:[NSString class]] || imageName.length == 0) {
        return nil;
    }

    NSString *imagePath = [self resolvedImagePathForImageName:imageName];
    UIImage *image = imagePath ? [UIImage imageWithContentsOfFile:imagePath] : nil;

    if (!image) {
        NCLogW(@"[NCChatUITheme] Failed to load image for key:%@, name:%@, resourcePath:%@",
               imageKey, imageName, self.resourcePath);
    }

    return image;
}

- (NSString *)resolvedImagePathForImageName:(NSString *)imageName {
    if (![self isValidStringKey:imageName] || ![self isValidStringKey:self.resourcePath]) {
        return nil;
    }

    NSString *extension = [imageName pathExtension];
    NSString *baseName =
        extension.length > 0 ? [imageName stringByDeletingPathExtension] : imageName;
    NSString *normalizedExtension =
        extension.length > 0 ? [@"." stringByAppendingString:extension] : @".png";
    CGFloat screenScale = [UIScreen mainScreen].scale;

    NSArray<NSString *> *scaleSuffixes = nil;
    if (screenScale >= 3.0) {
        scaleSuffixes = @[ @"@3x", @"@2x", @"" ];
    } else if (screenScale >= 2.0) {
        scaleSuffixes = @[ @"@2x", @"@3x", @"" ];
    } else {
        scaleSuffixes = @[ @"", @"@2x", @"@3x" ];
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *suffix in scaleSuffixes) {
        NSString *fileName =
            [NSString stringWithFormat:@"%@%@%@", baseName, suffix, normalizedExtension];
        NSString *candidatePath = [self.resourcePath stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:candidatePath]) {
            return candidatePath;
        }
    }

    return nil;
}

@end
