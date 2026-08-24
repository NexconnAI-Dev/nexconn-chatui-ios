//
//  NCMessageEditUtil.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageEditUtil.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

@implementation NCMessageEditUtil

+ (NSString *)displayTextForOriginalText:(NSString *)originalText isEdited:(BOOL)isEdited {
    if (!originalText) {
        originalText = @"";
    }

    if (isEdited) {
        return [NSString stringWithFormat:@"%@%@", originalText, [self editedSuffix]];
    }
    return originalText;
}

+ (UIColor *)editedTextColor {
    return NCChatUIConfigCenter.message.editedTextColor;
}

+ (NSString *)editedSuffix {
    return [NSString stringWithFormat:NCUILocalizedString(@"message_edited_suffix_format"),
                                      NCUILocalizedString(@"message_edited")];
}

+ (CGSize)sizeForText:(NSString *)originalText
             isEdited:(BOOL)isEdited
                 font:(UIFont *)font
      constrainedSize:(CGSize)constrainedSize {

    NSString *displayText = [self displayTextForOriginalText:originalText isEdited:isEdited];

    CGSize textSize = [NCChatUIUtility getTextDrawingSize:displayText
                                                     font:font
                                          constrainedSize:constrainedSize];

    return CGSizeMake(ceilf(textSize.width), ceilf(textSize.height));
}

+ (BOOL)isEditTimeValid:(long long)sentTime {
    if (sentTime <= 0) {
        return NO;
    }
    NCAppSettings *appSettings = [NCEngine getAppSettings];
    NSTimeInterval appSettingsTime = appSettings.messageModifiableMinutes * 60 * 1000;
    if (appSettingsTime <= 0) {
        return NO;
    }
    // Convert the device time to the server timeline.
    NSTimeInterval deltaTime = [NCEngine getServerTimeDelta];
    NSTimeInterval currentTimestamp = ([[NSDate date] timeIntervalSince1970] * 1000) - deltaTime;
    // Measure elapsed time from the message send timestamp.
    NSTimeInterval timeInterval = currentTimestamp - sentTime;
    // Messages older than the configured edit window are not editable.
    if (timeInterval > appSettingsTime) {
        return NO;
    }
    return YES;
}

@end
