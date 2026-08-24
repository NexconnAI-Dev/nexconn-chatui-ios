//
//  NCCircularLoadingView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCCircularLoadingView.h"
#import "NCChatUICommonDefine.h"
static NSString *const kRotationAnimationKey = @"circularLoadingRotationAnimation";

@interface NCCircularLoadingView ()

/**
 * Shape layer that draws the loading arc.
 */
@property (nonatomic, strong) CAShapeLayer *circleLayer;

/**
 * Indicates whether the rotation animation is active.
 */
@property (nonatomic, assign) BOOL animating;

@end

@implementation NCCircularLoadingView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaultValues];
        [self setupLayer];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectMake(0, 0, 40, 40)];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupDefaultValues];
    [self setupLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateCirclePath];
}

#pragma mark - Setup Methods

/**
 * Configures the default appearance and animation values.
 */
- (void)setupDefaultValues {
    _lineWidth = 2.0;
    UIColor *color = NCDynamicColor(@"primary_color");
    if (!color) {
        color = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    }
    _strokeColor = color; // Match the blue used in the UI specification.
    _animationDuration = 1.0;
    _startAngle = 0;     // Start at 3 o'clock (0 degrees).
    _endAngle = -M_PI_2; // End at 12 o'clock (-90 degrees).
    _animating = NO;
}

/**
 * Configures the loading arc layer.
 */
- (void)setupLayer {
    self.circleLayer = [CAShapeLayer layer];
    self.circleLayer.fillColor = [UIColor clearColor].CGColor;
    self.circleLayer.strokeColor = self.strokeColor.CGColor;
    self.circleLayer.lineWidth = self.lineWidth;
    self.circleLayer.lineCap = kCALineCapRound;
    self.circleLayer.lineJoin = kCALineJoinRound;

    [self.layer addSublayer:self.circleLayer];

    // Build the initial arc path.
    [self updateCirclePath];
}

/**
 * Updates the loading arc path for the current bounds.
 */
- (void)updateCirclePath {
    CGRect bounds = self.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    CGFloat radius = MIN(bounds.size.width, bounds.size.height) / 2 - self.lineWidth / 2;

    // Keep the path radius positive for very small bounds.
    if (radius <= 0) {
        radius = 1;
    }

    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center
                                                        radius:radius
                                                    startAngle:self.startAngle
                                                      endAngle:self.endAngle
                                                     clockwise:YES];

    self.circleLayer.path = path.CGPath;
    self.circleLayer.frame = bounds;
}

#pragma mark - Public Methods

- (void)startAnimating {
    if (self.animating) {
        return;
    }

    self.animating = YES;
    self.hidden = NO;

    // Rotate the arc continuously.
    CABasicAnimation *rotationAnimation =
        [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = @(0);
    rotationAnimation.toValue = @(M_PI * 2);
    rotationAnimation.duration = self.animationDuration;
    rotationAnimation.repeatCount = HUGE_VALF;
    rotationAnimation.removedOnCompletion = NO;
    rotationAnimation.timingFunction =
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    [self.circleLayer addAnimation:rotationAnimation forKey:kRotationAnimationKey];
}

- (void)stopAnimating {
    if (!self.animating) {
        return;
    }

    self.animating = NO;
    [self.circleLayer removeAnimationForKey:kRotationAnimationKey];
}

- (BOOL)isAnimating {
    return self.animating;
}

#pragma mark - Setter Methods

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    self.circleLayer.lineWidth = lineWidth;
    [self updateCirclePath];
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor = strokeColor;
    self.circleLayer.strokeColor = strokeColor.CGColor;
}

- (void)setStartAngle:(CGFloat)startAngle {
    _startAngle = startAngle;
    [self updateCirclePath];
}

- (void)setEndAngle:(CGFloat)endAngle {
    _endAngle = endAngle;
    [self updateCirclePath];
}

#pragma mark - Cleanup

- (void)dealloc {
    [self stopAnimating];
}

@end
