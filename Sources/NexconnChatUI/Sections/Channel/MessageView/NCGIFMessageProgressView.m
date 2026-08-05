//
//  NCGIFMessageProgressView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGIFMessageProgressView.h"
#import "NCChatUICommonDefine.h"

@interface NCGIFMessageProgressView ()

@property (nonatomic, assign) CGFloat currentProgress;

@end

@implementation NCGIFMessageProgressView

- (void)drawRect:(CGRect)rect {
    CGPoint origin = CGPointMake(18, 18);
    CGFloat radius = 18.0f;
    CGFloat startAngle = -M_PI_2;
    CGFloat endAngle = startAngle + self.currentProgress * M_PI * 2;
    UIBezierPath *sectorPath = [UIBezierPath bezierPathWithArcCenter:origin
                                                              radius:radius
                                                          startAngle:startAngle
                                                            endAngle:endAngle
                                                           clockwise:YES];
    [sectorPath addLineToPoint:origin];
    UIColor *color = NCDynamicColor(@"selected_background_color");
    [color set];
    [sectorPath fill];
}

#pragma mark - Public Methods

- (void)setProgress:(CGFloat)progress {
    if (!progress) {
        return;
    }
    self.currentProgress = progress * 0.01;
    [self setNeedsDisplay];
}

#pragma mark - Getters and Setters

- (CGFloat)currentProgress {
    if (!_currentProgress) {
        _currentProgress = 0;
    }
    return _currentProgress;
}

@end
