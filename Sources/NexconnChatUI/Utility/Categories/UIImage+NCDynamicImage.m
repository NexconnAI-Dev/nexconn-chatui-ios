//
//  UIImage+NCDynamicImage.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "UIImage+NCDynamicImage.h"
#include <objc/runtime.h>
#import "NCChatUIConfig.h"

static const NSString *NCImageLocalPathKey = @"NCImageLocalPathKey";

@implementation UIImage (NCDynamicImage)
+ (UIImage *)nc_imageWithLocalPath:(NSString *)path {
    NSString *imagePath = [self getCurrentPathForTraitCollection:path];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    image.nc_imageLocalPath = imagePath;
    return image;
}

- (BOOL)nc_needReloadImage {
    if (!NCChatUIConfigCenter.ui.enableDarkMode) {
        return NO;
    }
    if (self.nc_imageLocalPath.length <= 0) {
        return NO;
    }
    if ([[self class] isDarkMode]) {
        if (![self.nc_imageLocalPath containsString:@"_dark"]) {
            NSString *currentPath = self.nc_imageLocalPath;
            currentPath = [currentPath stringByReplacingOccurrencesOfString:@".png" withString:@"_dark.png"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:currentPath] ||
                [[NSFileManager defaultManager]
                    fileExistsAtPath:[currentPath stringByReplacingOccurrencesOfString:@".png"
                                                                            withString:@"@2x.png"]] ||
                [[NSFileManager defaultManager]
                    fileExistsAtPath:[currentPath stringByReplacingOccurrencesOfString:@".png"
                                                                            withString:@"@3x.png"]]) {
                return YES;
            }
            return NO;
        }
    } else {
        if ([self.nc_imageLocalPath containsString:@"_dark"]) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)getCurrentPathForTraitCollection:(NSString *)path {
    if (!NCChatUIConfigCenter.ui.enableDarkMode) {
        return path;
    }
    NSString *currentPath = path;
    if ([self isDarkMode]) {
        if (![path containsString:@"_dark"]) {
            currentPath = [path stringByReplacingOccurrencesOfString:@".png" withString:@"_dark.png"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:currentPath] ||
                [[NSFileManager defaultManager]
                    fileExistsAtPath:[currentPath stringByReplacingOccurrencesOfString:@".png"
                                                                            withString:@"@2x.png"]] ||
                [[NSFileManager defaultManager]
                    fileExistsAtPath:[currentPath stringByReplacingOccurrencesOfString:@".png"
                                                                            withString:@"@3x.png"]]) {
                return currentPath;
            } else {
                currentPath = path;
            }
        }
    } else {
        if ([path containsString:@"_dark"]) {
            currentPath = [path stringByReplacingOccurrencesOfString:@"_dark" withString:@""];
        }
    }
    return currentPath;
}

// Returns whether the current interface style is dark.
+ (BOOL)isDarkMode {
    if (@available(iOS 13.0, *)) {
        NSNumber *currentUserInterfaceStyle =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"NCCurrentUserInterfaceStyle"];
        if (!currentUserInterfaceStyle) {
            currentUserInterfaceStyle = @(UITraitCollection.currentTraitCollection.userInterfaceStyle);
        }
        if (currentUserInterfaceStyle.integerValue == UIUserInterfaceStyleDark) {
            return YES;
        }
    }
    return NO;
}

- (void)setNc_imageLocalPath:(NSString *)nc_imageLocalPath {
    objc_setAssociatedObject(self, &NCImageLocalPathKey, nc_imageLocalPath, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)nc_imageLocalPath {
    return objc_getAssociatedObject(self, &NCImageLocalPathKey);
}
@end
