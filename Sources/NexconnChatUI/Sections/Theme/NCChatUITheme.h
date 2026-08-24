//
//  NCChatUITheme.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Custom theme class.
/// Loads and manages custom theme resources, including color and image configuration.
@interface NCChatUITheme : NSObject

#pragma mark - Properties

/// Theme name.
@property (nonatomic, copy) NSString *name;

/// Color dictionary.
/// Key: color identifier, Value: hex color value (format: #RRGGBB or #RRGGBBAA).
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *colors;

/// Image dictionary.
/// Key: image identifier, Value: image filename (relative to resourcePath).
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *images;

/// Resource path.
/// Absolute path to the theme resource folder containing images and other assets.
@property (nonatomic, readonly, copy) NSString *resourcePath;

/// Theme configuration file path.
/// Absolute path to the plist file containing the complete theme configuration.
/// Configuration file format:
/// A dictionary with keys "name", "colors", and "images".
/// "colors" stores color key-value pairs (for example: "color_key": "#RRGGBB").
/// "images" stores image key-value pairs (for example: "image_key": "image_filename.png").
@property (nonatomic, readonly, copy) NSString *plistPath;

#pragma mark - Initialization

/// Initialize a theme object with a theme folder path.
/// @param path Theme folder path. The folder should contain:
///             - theme.plist: theme configuration file
///             - resources/: resource folder (containing images and other assets)
/// @return A theme instance. Returns an incomplete instance if the path is invalid or the
/// configuration format is wrong.
- (instancetype)initWithThemePath:(NSString *)path;

#pragma mark - Public Methods

/// Get a dynamic color.
/// Retrieves the color from the theme configuration first; falls back to the default color if not
/// configured.
/// @param colorKey Color identifier used to look up the color value in the theme configuration.
/// @param hex Default color value (hex format, e.g. #RRGGBB or 0xRRGGBB).
/// @return The color object, or nil if parameters are invalid.
- (UIColor *_Nullable)dynamicColor:(NSString *)colorKey defaultColor:(NSString *)hex;

/// Get a dynamic image.
/// Retrieves the image from the theme configuration first; falls back to the default image if not
/// configured.
/// @param imageKey Image identifier used to look up the image filename in the theme configuration.
/// @param defaultImage Default image to use when the theme does not configure one or loading fails.
/// @return The image object; returns the default image if the theme does not configure one.
- (UIImage *_Nullable)dynamicImage:(NSString *)imageKey
                      defaultImage:(UIImage *_Nullable)defaultImage;

@end

NS_ASSUME_NONNULL_END
