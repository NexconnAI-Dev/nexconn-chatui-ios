//
//  NCMessageEditUtil.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCMessageEditUtil : NSObject

/// Gets the display text, including the edited marker.
/// - Parameter originalText The original text.
/// - Parameter isEdited Whether the message has been edited.
/// - Returns The display text.
+ (NSString *)displayTextForOriginalText:(NSString *)originalText isEdited:(BOOL)isEdited;

/// Gets the color configuration for edited text.
/// - Returns The edited text color.
+ (UIColor *)editedTextColor;

/// Gets the edited marker text.
/// - Returns The edited marker text.
+ (NSString *)editedSuffix;

/// Calculates the text size including the edited state.
/// - Parameter originalText The original text.
/// - Parameter isEdited Whether the message has been edited.
/// - Parameter font The font.
/// - Parameter constrainedSize The constrained size.
/// - Returns The text size.
+ (CGSize)sizeForText:(NSString *)originalText
             isEdited:(BOOL)isEdited
                 font:(UIFont *)font
      constrainedSize:(CGSize)constrainedSize;

/// Whether the edit time has not expired.
/// The edit time can be configured in the Nexconn console.
/// - Parameter sentTime The message sent time.
+ (BOOL)isEditTimeValid:(long long)sentTime;

@end

NS_ASSUME_NONNULL_END
