//
//  NCChatUIBuiltInThemes.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUITheme.h"
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface NCChatUIBuiltInThemes : NSObject

/// Gets a dynamic color.
/// - Parameter colorKey: Lively theme color key.
- (UIColor *)dynamicColor:(NSString *)colorKey;

/// Gets the default color.
/// - Parameter colorKey: Lively theme color key.
- (UIColor *)defaultColor:(NSString *)colorKey;

/// Gets a dynamic image.
/// - Parameter imageKey: Lively theme image key.
- (UIImage *)dynamicImage:(NSString *)imageKey;

/// Gets the default image.
/// - Parameter imageKey: Lively theme image key.
- (UIImage *)defaultImage:(NSString *)imageKey;
@end

/// Lively theme.
@interface NCChatUILivelyThemes : NCChatUIBuiltInThemes

@end
NS_ASSUME_NONNULL_END
