//
//  NCChatUICommonDefine.h
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIUtility.h"
#import "NCChatUIThemeManager.h"
#import "NCChatUILog.h"
#ifndef NCChatUICommonDefine_h
#define NCChatUICommonDefine_h

#define NCUILocalizedString(key) [NCChatUIUtility localizedString:(key) table:@"NCChatUI"]
#define NCResourceImage(value) [NCChatUIUtility imageNamed:(value) ofBundle:@"NCChatUI.bundle"]
#define NCResourceColor(key, colorStr) [NCChatUIUtility color:(key) originalColor:(colorStr)]

#define NCDynamicImage(key) [NCChatUIThemeManager dynamicImage:key]
#define NCDynamicColor(key) [NCChatUIThemeManager dynamicColor:key]
#define NCDynamicResourceColor(key, resourceKeyString, colorHex) [NCChatUIThemeManager dynamicColor:key resourceKey:resourceKeyString originalColor:colorHex]

#pragma mark - Screen Size
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_SCALE ([UIScreen mainScreen].scale)

#pragma mark - Dispatch Main Async
#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)                                                                                \
    if ([NSThread isMainThread]) {                                                                                     \
        block();                                                                                                       \
    } else {                                                                                                           \
        dispatch_async(dispatch_get_main_queue(), block);                                                              \
    }
#endif

#pragma mark - Color

#define RGBCOLOR(r, g, b) [UIColor colorWithRed:(r) / 255.0f green:(g) / 255.0f blue:(b) / 255.0f alpha:1]

#define HEXCOLOR(rgbValue)                                                                                             \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0                                               \
                green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0                                                  \
                 blue:((float)(rgbValue & 0xFF)) / 255.0                                                           \
                alpha:1.0]

#define NCMASKCOLOR(rgbValue,alphaValue)                                                                                             \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0                                               \
                green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0                                                  \
                 blue:((float)(rgbValue & 0xFF)) / 255.0                                                           \
                alpha:alphaValue]

#define NCDYCOLOR(lrgbValue, drgbValue)                                                                                \
    [NCChatUIUtility generateDynamicColor:HEXCOLOR(lrgbValue) darkColor:HEXCOLOR(drgbValue)]

#pragma mark - System Version

#define NC_IOS_SYSTEM_VERSION_GREATER_THAN(v)                                                                          \
    ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define NC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)                                                              \
    ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define NC_IOS_SYSTEM_VERSION_LESS_THAN(v)                                                                             \
    ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#pragma mark - device
#define ISX [NCChatUIUtility getWindowSafeAreaInsets].top >= 10

// Posted when a page that supports autorotation appears or disappears. Notification object is @(YES) or @(NO).
#define NCChatUIViewSupportAutorotateNotification @"NCChatUIViewSupportAutorotateNotification"

/// Simplified Chinese
static NSString *const NCChatUILanguageZH_HANS = @"zh-Hans";
/// English
static NSString *const NCChatUILanguageEN = @"en";
/// Arabic
static NSString *const NCChatUILanguageAR = @"ar";

#endif /* NCChatUICommonDefine_h */
