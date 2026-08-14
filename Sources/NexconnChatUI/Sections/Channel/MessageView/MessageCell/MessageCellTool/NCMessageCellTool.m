//
//  NCMessageCellTool.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageCellTool.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

@implementation NCMessageCellTool
+ (UIImage *)getDefaultMessageCellBackgroundImage:(NCMessageModel *)model{
    UIImage *bubbleImage;
    if (NCMessageDirectionReceive == model.messageDirection) {
        bubbleImage = NCDynamicImage(@"channel_msg_cell_bg_from_img");
    } else {
        if ([self isWhiteBubbleImageWithSendMesageCell:model.objectName]) {
            bubbleImage = NCDynamicImage(@"channel_msg_cell_bg_white_img");
        }else{
            bubbleImage = NCDynamicImage(@"channel_msg_cell_bg_to_img");
        }
    }
    if ([NCChatUIUtility isRTL]) {
        bubbleImage = [bubbleImage imageFlippedForRightToLeftLayoutDirection];
    }
    bubbleImage = [self getResizableImage:bubbleImage];
    return bubbleImage;
}

+ (BOOL)isWhiteBubbleImageWithSendMesageCell:(NSString *)objectName{
    NSArray *list = @[@"RC:FileMsg",@"RC:CardMsg"];
    if ([list containsObject:objectName]) {
        return YES;
    }
    return NO;
}

+ (CGFloat)getMessageContentViewMaxWidth{
    float screenRatio = 0.637;
    if (SCREEN_WIDTH <= 320) {
        screenRatio = 0.6;
    }
    float maxWidth = (int)(SCREEN_WIDTH * screenRatio) + 7;
    return maxWidth;
}

+ (CGSize)getThumbnailImageSize:(UIImage *)image {
    // Size thumbnails using the minimum and maximum lengths from the SDK compression options.
    // If either edge is below the minimum, scale from the shorter edge and cap the longer edge at the maximum.
    // If both edges are within the range, scale the longer edge to the maximum while preserving the aspect ratio.
    // If either edge exceeds the maximum, fit moderate aspect ratios by the longer edge; for extreme ratios,
    // fit the shorter edge to the minimum and cap the longer edge at the maximum.
    CGSize imageSize = image.size;
    NCCompressOptions *compressOptions = [NCEngine getCompressOptions];
    CGFloat maxSize = compressOptions.thumbnailMaxSize.floatValue / 2;
    CGFloat minSize = compressOptions.thumbnailMinSize.floatValue / 2;
    CGFloat imageMaxLength = maxSize > 0 ? maxSize : 120;
    CGFloat imageMinLength = minSize > 0 ? minSize : 50;
    if (imageSize.width == 0 || imageSize.height == 0) {
        return CGSizeMake(imageMaxLength, imageMinLength);
    }
    CGFloat imageWidth = 0;
    CGFloat imageHeight = 0;
    if (imageSize.width < imageMinLength || imageSize.height < imageMinLength) {
        return [self p_getSizeForBelowStandard:imageSize imageMinLength:imageMinLength imageMaxLength:imageMaxLength];
    } else if (imageSize.width < imageMaxLength && imageSize.height < imageMaxLength &&
               imageSize.width >= imageMinLength && imageSize.height >= imageMinLength) {
        if (imageSize.width > imageSize.height) {
            imageWidth = imageMaxLength;
            imageHeight = imageMaxLength * imageSize.height / imageSize.width;
        } else {
            imageHeight = imageMaxLength;
            imageWidth = imageMaxLength * imageSize.width / imageSize.height;
        }
    } else if (imageSize.width >= imageMaxLength || imageSize.height >= imageMaxLength) {
        return [self p_getSizeForAboveStandard:imageSize imageMinLength:imageMinLength imageMaxLength:imageMaxLength];
    }
    return CGSizeMake(imageWidth, imageHeight);
}

+ (CGSize)p_getSizeForBelowStandard:(CGSize)imageSize imageMinLength:(CGFloat)imageMinLength imageMaxLength:(CGFloat)imageMaxLength{
    CGFloat imageWidth = 0;
    CGFloat imageHeight = 0;
    if (imageSize.width < imageSize.height) {
        imageWidth = imageMinLength;
        imageHeight = imageMinLength * imageSize.height / imageSize.width;
        if (imageHeight > imageMaxLength) {
            imageHeight = imageMaxLength;
        }
    } else {
        imageHeight = imageMinLength;
        imageWidth = imageMinLength * imageSize.width / imageSize.height;
        if (imageWidth > imageMaxLength) {
            imageWidth = imageMaxLength;
        }
    }
    return CGSizeMake(imageWidth, imageHeight);
}

+ (CGSize)p_getSizeForAboveStandard:(CGSize)imageSize imageMinLength:(CGFloat)imageMinLength imageMaxLength:(CGFloat)imageMaxLength{
    CGFloat imageWidth = 0;
    CGFloat imageHeight = 0;
    if (imageSize.width > imageSize.height) {
        if (imageSize.width / imageSize.height < imageMaxLength / imageMinLength) {
            imageWidth = imageMaxLength;
            imageHeight = imageMaxLength * imageSize.height / imageSize.width;
        } else {
            imageHeight = imageMinLength;
            imageWidth = imageMinLength * imageSize.width / imageSize.height;
            if (imageWidth > imageMaxLength) {
                imageWidth = imageMaxLength;
            }
        }
    } else {
        if (imageSize.height / imageSize.width < imageMaxLength / imageMinLength) {
            imageHeight = imageMaxLength;
            imageWidth = imageMaxLength * imageSize.width / imageSize.height;
        } else {
            imageWidth = imageMinLength;
            imageHeight = imageMinLength * imageSize.height / imageSize.width;
            if (imageHeight > imageMaxLength) {
                imageHeight = imageMaxLength;
            }
        }
    }
    return CGSizeMake(imageWidth, imageHeight);
}

+ (NSDictionary *)getTextLinkOrPhoneNumberAttributeDictionary:(NCMessageDirection)msgDirection{
    return [self getTextLinkOrPhoneNumberAttributeDictionary:msgDirection linkColorKey:@"link_color"];
}

+ (NSDictionary *)getTextLinkOrPhoneNumberAttributeDictionary:(NCMessageDirection)msgDirection
                                                 linkColorKey:(NSString *)linkColorKey{

    if (msgDirection == NCMessageDirectionSend ) {
        UIColor *linkColor = NCDynamicColor(linkColorKey);
        if (linkColor) {
            return @{@(NSTextCheckingTypeLink) :
                         @{NSForegroundColorAttributeName : linkColor,
                           NSUnderlineColorAttributeName :linkColor,
                           NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)
                         },
                     @(NSTextCheckingTypePhoneNumber) : @{ NSForegroundColorAttributeName : linkColor}
            };
        }
        return @{@(NSTextCheckingTypeLink) : @{NSForegroundColorAttributeName : NCDYCOLOR(0x0099ff, 0x005F9E)},
                 @(NSTextCheckingTypePhoneNumber) : @{ NSForegroundColorAttributeName : [NCChatUIUtility generateDynamicColor:HEXCOLOR(0x0099ff) darkColor:HEXCOLOR(0x005F9E)]
                 }
        };
    }else{
        UIColor *linkColor = NCDynamicColor(linkColorKey);
        if (linkColor) {
            return @{@(NSTextCheckingTypeLink) : @{NSForegroundColorAttributeName : linkColor,
                                                   NSUnderlineColorAttributeName :linkColor,
                                                   NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)},
                     @(NSTextCheckingTypePhoneNumber) : @{ NSForegroundColorAttributeName : linkColor}
            };
        }
        return @{@(NSTextCheckingTypeLink) : @{NSForegroundColorAttributeName : NCDYCOLOR(0x0099ff, 0x1290e2)},
                 @(NSTextCheckingTypePhoneNumber) : @{ NSForegroundColorAttributeName : [NCChatUIUtility generateDynamicColor:HEXCOLOR(0x0099ff) darkColor:HEXCOLOR(0x1290e2)]
                 }
        };
    }
    
}

+ (NSString *)phoneURLStringWithPhoneNumber:(NSString *)phoneNumber {
    if (![phoneNumber isKindOfClass:[NSString class]]) {
        NCLogD(@"didSelectLinkWithPhoneNumber phoneNumber is nil");
        return nil;
    }

    NSString *trimmedPhoneNumber = [phoneNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedPhoneNumber.length == 0) {
        NCLogD(@"didSelectLinkWithPhoneNumber phoneNumber is empty");
        return nil;
    }

    if ([trimmedPhoneNumber rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound) {
        NCLogD(@"didSelectLinkWithPhoneNumber phoneNumber is invalid");
        return nil;
    }

    NSMutableCharacterSet *allowedCharacters = [[NSMutableCharacterSet decimalDigitCharacterSet] mutableCopy];
    [allowedCharacters addCharactersInString:@"+-() "];
    if ([trimmedPhoneNumber rangeOfCharacterFromSet:allowedCharacters.invertedSet].location != NSNotFound) {
        NCLogD(@"didSelectLinkWithPhoneNumber phoneNumber is invalid");
        return nil;
    }

    return [@"tel://" stringByAppendingString:trimmedPhoneNumber];
}

#pragma mark - Private Methods
+ (UIImage *)getResizableImage:(UIImage *)image{
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.5, image.size.width * 0.5, image.size.height * 0.5, image.size.width * 0.5)];
}
@end
