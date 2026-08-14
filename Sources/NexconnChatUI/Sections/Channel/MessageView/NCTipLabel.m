//
//  NCTipLabel.m
//  iOS-IMKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCTipLabel.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"

@implementation NCTipLabel

+ (instancetype)greyTipLabel {
    NCTipLabel *tip = [[NCTipLabel alloc] init];
    if (tip) {
        tip.marginInsets = UIEdgeInsetsMake(5.f, 5.f, 5.f, 5.f);
        tip.textColor = NCDynamicColor(@"control_title_white_color");
        tip.numberOfLines = 0;
        tip.lineBreakMode = NSLineBreakByTruncatingTail;
        tip.textAlignment = NSTextAlignmentCenter;
        tip.font = [[NCChatUIConfig defaultConfig].font fontOfFourthLevel];
        tip.layer.masksToBounds = YES;
        tip.layer.cornerRadius = 4.f;
        tip.backgroundColor = NCDynamicColor(@"tip_background_color");
        
    }
    return tip;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.marginInsets)];
}

- (void)setMarginInsets:(UIEdgeInsets)marginInsets {
    _marginInsets = marginInsets;
    [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.width += self.marginInsets.left + self.marginInsets.right;
    size.height += self.marginInsets.top + self.marginInsets.bottom;
    return size;
}

@end
