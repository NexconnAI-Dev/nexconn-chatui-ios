//
//  NCReadReceiptProgressView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCReadReceiptProgressView.h"

@implementation NCReadReceiptProgressView

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaultValues];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaultValues];
    }
    return self;
}

- (void)setupDefaultValues {
    self.backgroundColor = [UIColor clearColor];
    _progress = 0.0;
    // Default green: #16D258.
    UIColor *defaultColor = [UIColor colorWithRed:22.0/255.0 green:210.0/255.0 blue:88.0/255.0 alpha:1.0];
    _borderColor = defaultColor;
    _fillColor = defaultColor;
    _innerPadding = 1.5;  // Spacing between the filled area and the border.
    _borderWidth = 1.5;  // Border width.
}

#pragma mark - Property Setters

- (void)setProgress:(CGFloat)progress {
    // Clamp progress to the 0.0-1.0 range.
    _progress = MAX(0.0, MIN(1.0, progress));
    [self setNeedsDisplay];
}

- (void)setBorderColor:(UIColor *)borderColor {
    if (borderColor) {
        _borderColor = borderColor;
    } else {
        // Default green: #16D258.
        _borderColor = [UIColor colorWithRed:22.0/255.0 green:210.0/255.0 blue:88.0/255.0 alpha:1.0];
    }
    [self setNeedsDisplay];
}

- (void)setFillColor:(UIColor *)fillColor {
    if (fillColor) {
        _fillColor = fillColor;
    } else {
        // Default green: #16D258.
        _fillColor = [UIColor colorWithRed:22.0/255.0 green:210.0/255.0 blue:88.0/255.0 alpha:1.0];
    }
    [self setNeedsDisplay];
}

- (void)setInnerPadding:(CGFloat)innerPadding {
    _innerPadding = MAX(0.0, innerPadding);
    [self setNeedsDisplay];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = MAX(0.0, borderWidth);
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }
    
    CGFloat centerX = rect.size.width * 0.5;
    CGFloat centerY = rect.size.height * 0.5;
    CGFloat minSize = MIN(rect.size.width, rect.size.height);
    
    // Calculate the outer radius, accounting for the border width.
    CGFloat outerRadius = (minSize * 0.5) - (self.borderWidth * 0.5);
    
    // Draw the circular border.
    [self drawBorderWithContext:context centerX:centerX centerY:centerY radius:outerRadius];
    
    // Draw the filled progress sector when progress is greater than zero.
    if (self.progress > 0.0) {
        CGFloat fillRadius = outerRadius - (self.borderWidth * 0.5) - self.innerPadding;
        [self drawProgressWithContext:context centerX:centerX centerY:centerY radius:fillRadius];
    }
}

/// Draws the circular border.
- (void)drawBorderWithContext:(CGContextRef)context centerX:(CGFloat)centerX centerY:(CGFloat)centerY radius:(CGFloat)radius {
    CGContextSaveGState(context);
    
    // Configure the border style.
    CGContextSetLineWidth(context, self.borderWidth);
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    
    // Draw the circular border.
    CGContextAddArc(context, centerX, centerY, radius, 0, M_PI * 2, 0);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

/// Draws the progress fill clockwise from the 12 o'clock position.
- (void)drawProgressWithContext:(CGContextRef)context centerX:(CGFloat)centerX centerY:(CGFloat)centerY radius:(CGFloat)radius {
    CGContextSaveGState(context);
    
    // Configure the fill color.
    CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
    
    // Start at 12 o'clock (-pi/2).
    CGFloat startAngle = -M_PI_2;
    // Rotate clockwise by progress * 2pi.
    CGFloat endAngle = startAngle + (self.progress * M_PI * 2);
    
    // Build a sector path starting at the center.
    CGContextMoveToPoint(context, centerX, centerY);
    CGContextAddArc(context, centerX, centerY, radius, startAngle, endAngle, 0);
    CGContextClosePath(context);
    
    // Fill the sector path.
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
}

@end
