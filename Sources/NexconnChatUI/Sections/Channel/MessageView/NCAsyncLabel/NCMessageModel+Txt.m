//
//  NCMessageModel+Txt.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageModel+Txt.h"
#import <objc/runtime.h>
#import "NCMessageCellTool.h"
#import "NCChatUIConfig.h"
#import <CoreText/CoreText.h>

NSInteger const NCComplexTextSpaceLeft = 12;
NSInteger const NCComplexTextSpaceRight = 12;

@implementation NCMessageModel (Txt)
- (void)setTxt_textSize:(CGSize)txt_textSize {
    NSValue *value = [NSValue valueWithCGSize:txt_textSize];
    objc_setAssociatedObject(self, @selector(txt_textSize), value, OBJC_ASSOCIATION_RETAIN);
}

- (CGSize)txt_textSize {
    if (![self.content isKindOfClass:[NCTextMessage class]]) {
        return CGSizeZero;
    }
    NCTextMessage *msg = (NCTextMessage *)self.content;
    NSValue *value = objc_getAssociatedObject(self, @selector(txt_textSize));
    if (value) {
        return [value CGSizeValue];
    } else {
        CGFloat textMaxWidth = [NCMessageCellTool getMessageContentViewMaxWidth] - NCComplexTextSpaceLeft - NCComplexTextSpaceRight;
        
        UIFont *font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
        CGSize size = [self coreText:msg.text
                                font:font
                     constrainedSize:CGSizeMake(textMaxWidth, 80000)];
        [self setTxt_textSize:size];
        return size;
    }
}


- (CGSize)coreText:(NSString *)calcedString font:(UIFont *)font constrainedSize:(CGSize)limitSize {
    NSMutableAttributedString *attibuteStr = [[NSMutableAttributedString alloc] initWithString:calcedString];
    [attibuteStr addAttribute:NSFontAttributeName
                        value:font
                        range:NSMakeRange(0, calcedString.length)];
    CFAttributedStringRef attributedStringRef = (__bridge CFAttributedStringRef)attibuteStr;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attributedStringRef);
    CFRange range = CFRangeMake(0, calcedString.length);
    CFRange fitCFRange = CFRangeMake(0, 0);
    CGSize newSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, range, NULL, limitSize, &fitCFRange);
    if (nil != framesetter) {
        CFRelease(framesetter);
        framesetter = nil;
    }
    return CGSizeMake(ceilf(newSize.width), ceilf(newSize.height));
}
@end
