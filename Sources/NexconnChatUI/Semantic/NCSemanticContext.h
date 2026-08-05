//
//  NCSemanticContext.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCSemanticContext : NSObject
+ (BOOL)isRTL;
+ (void)configureAttributeForNavigationController:(UINavigationController *)navi;
+ (UIImage *)imageflippedForRTL:(UIImage *)image;
+ (CGRect)modifyFrameForRTL:(CGRect)frame toX:(CGFloat)x;
+ (void)swapFrameForRTL:(UIView *)firstView withView:(UIView *)secondView;
@end

NS_ASSUME_NONNULL_END
