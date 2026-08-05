//
//  NCCircularLoadingView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Circular rotating loading view.
 * Draws a 3/4 arc loading effect in code using CAShapeLayer and supports continuous rotation animation.
 * Default configuration: 2.0 line width, blue #007AFF, and a 270-degree arc from 3 o'clock to 12 o'clock.
 */
@interface NCCircularLoadingView : UIView

/**
 * The loading ring line width, defaulting to 2.0.
 */
@property (nonatomic, assign) CGFloat lineWidth;

/**
 * The loading ring color, defaulting to blue #007AFF.
 */
@property (nonatomic, strong) UIColor *strokeColor;

/**
 * The rotation animation duration, defaulting to 1.0 seconds.
 */
@property (nonatomic, assign) CGFloat animationDuration;

/**
 * The ring start angle in radians, defaulting to 0, starting from the 3 o'clock direction.
 */
@property (nonatomic, assign) CGFloat startAngle;

/**
 * The ring end angle in radians, defaulting to -π/2, ending at the 12 o'clock direction to form a 3/4 arc.
 */
@property (nonatomic, assign) CGFloat endAngle;

/**
 * Initializes the loading view with the specified frame.
 * @param frame The view frame. The loading ring is automatically centered based on the frame size.
 */
- (instancetype)initWithFrame:(CGRect)frame;

/**
 * Starts the rotation animation.
 * Starts a continuous 360-degree clockwise rotation animation until stopAnimating is called.
 */
- (void)startAnimating;

/**
 * Stops the rotation animation.
 * Immediately stops rotation and removes the animation effect.
 */
- (void)stopAnimating;

/**
 * Checks whether loading is currently rotating.
 * @return YES if animating, NO if stopped.
 */
- (BOOL)isAnimating;

@end

NS_ASSUME_NONNULL_END 
