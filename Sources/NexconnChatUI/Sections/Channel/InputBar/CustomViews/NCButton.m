//
//  NCButton.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCButton.h"
#import "UIImage+NCDynamicImage.h"
#import "NCChatUIConfig.h"
@implementation NCButton
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self fitDarkMode];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self fitDarkMode];
}

- (void)fitDarkMode {
    if (!NCChatUIConfigCenter.ui.enableDarkMode) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        [self nc_setDynamicImageForState:(UIControlStateNormal)];
        [self nc_setDynamicImageForState:(UIControlStateSelected)];
        [self nc_setDynamicImageForState:(UIControlStateHighlighted)];
        [self nc_setDynamicBackgroundImageForState:(UIControlStateNormal)];
        [self nc_setDynamicBackgroundImageForState:(UIControlStateSelected)];
        [self nc_setDynamicBackgroundImageForState:(UIControlStateHighlighted)];
    }
}

- (void)nc_setDynamicBackgroundImageForState:(UIControlState)state {
    UIImage *oldImage = [self backgroundImageForState:state];
    if (oldImage && [oldImage nc_needReloadImage]) {
        UIImage *newImage = [UIImage nc_imageWithLocalPath:oldImage.nc_imageLocalPath];
        if (newImage) {
            [self setBackgroundImage:newImage forState:state];
        }
    }
}

- (void)nc_setDynamicImageForState:(UIControlState)state {
    UIImage *oldImage = [self imageForState:state];
    if (oldImage && [oldImage nc_needReloadImage]) {
        UIImage *newImage = [UIImage nc_imageWithLocalPath:oldImage.nc_imageLocalPath];
        if (newImage) {
            [self setImage:newImage forState:state];
        }
    }
}

@end
