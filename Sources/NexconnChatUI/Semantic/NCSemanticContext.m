//
//  NCSemanticContext.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSemanticContext.h"
#import <UIKit/UIKit.h>
#import "NCChatUIUtility.h"
@implementation NCSemanticContext

+ (BOOL)isRTL {
    return [NCChatUIUtility isRTL];
}

+ (void)configureAttributeForNavigationController:(UINavigationController *)navi {
    if (@available(iOS 9.0, *)) {
        if ([self isRTL]) {
            navi.navigationBar.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;;
            navi.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        } else {
            navi.navigationBar.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;;
            navi.view.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
    }
}

+ (UIImage *)imageflippedForRTL:(UIImage *)image {
    if (!image || ![self isRTL]) {
        return image;
    }
    
    // Preserve dynamic image variants on iOS 13 and later when possible.
    if (@available(iOS 13.0, *)) {
        UIImage *dynamicFlippedImage = [self p_flippedDynamicImage:image];
        if (dynamicFlippedImage) {
            return dynamicFlippedImage;
        }
    }
    
    // Default behavior: flip the image directly.
    return [self p_flippedImage:image];
}

#pragma mark - Private

/// Flips a single image.
+ (UIImage *)p_flippedImage:(UIImage *)image {
    if (!image.CGImage) {
        return image;
    }
    return [UIImage imageWithCGImage:image.CGImage
                               scale:image.scale
                         orientation:UIImageOrientationUpMirrored];
}

/// Flips a dynamic image while preserving light and dark variants.
+ (UIImage *)p_flippedDynamicImage:(UIImage *)image API_AVAILABLE(ios(13.0)) {
    UIImageAsset *imageAsset = image.imageAsset;
    if (!imageAsset) {
        return nil;
    }
    
    UITraitCollection *lightTrait = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *darkTrait = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    
    UIImage *lightImage = [imageAsset imageWithTraitCollection:lightTrait];
    UIImage *darkImage = [imageAsset imageWithTraitCollection:darkTrait];
    
    // The image is not dynamic when both variants are identical.
    if (!lightImage || !darkImage || lightImage.CGImage == darkImage.CGImage) {
        return nil;
    }
    
    // Flip each appearance variant separately.
    UIImage *flippedLight = [self p_flippedImage:lightImage];
    UIImage *flippedDark = [self p_flippedImage:darkImage];
    
    // Recombine the flipped variants as a dynamic image.
    return [self p_combineDynamicImageWithLight:flippedLight dark:flippedDark];
}

/// Combines light and dark variants into a dynamic image.
+ (UIImage *)p_combineDynamicImageWithLight:(UIImage *)lightImage 
                                       dark:(UIImage *)darkImage API_AVAILABLE(ios(13.0)) {
    CGFloat scale = [UIScreen mainScreen].scale;
    UITraitCollection *scaleTrait = [UITraitCollection traitCollectionWithDisplayScale:scale];
    UITraitCollection *lightTrait = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *darkTrait = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    UITraitCollection *darkScaledTrait = [UITraitCollection traitCollectionWithTraitsFromCollections:@[scaleTrait, darkTrait]];
    
    UIImage *configuredLight = [lightImage imageWithConfiguration:[lightImage.configuration configurationWithTraitCollection:lightTrait]];
    UIImage *configuredDark = [darkImage imageWithConfiguration:[darkImage.configuration configurationWithTraitCollection:darkScaledTrait]];
    
    [configuredLight.imageAsset registerImage:configuredDark withTraitCollection:darkScaledTrait];
    
    return configuredLight;
}

+ (CGRect)modifyFrameForRTL:(CGRect)frame toX:(CGFloat)x {
    if (@available(iOS 9.0, *)) {
        if ([self isRTL]) {
            CGRect rect = CGRectMake(x,
                                     frame.origin.y,
                                     frame.size.width,
                                     frame.size.height);
            return rect;
        }
    }
    return frame;
}

+ (void)swapFrameForRTL:(UIView *)firstView withView:(UIView *)secondView {
    
    if (@available(iOS 9.0, *)) {
        if ([self isRTL]) {
            CGRect rect = firstView.frame;
            
            firstView.frame =  CGRectMake(secondView.frame.origin.x,
                                          firstView.frame.origin.y,
                                          firstView.frame.size.width,
                                          firstView.frame.size.height);
            secondView.frame =  CGRectMake(rect.origin.x,
                                          secondView.frame.origin.y,
                                          secondView.frame.size.width,
                                          secondView.frame.size.height);
        }
    }
}
@end
