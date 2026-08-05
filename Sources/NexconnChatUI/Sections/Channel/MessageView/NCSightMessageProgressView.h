//
//  NCSightMessageProgressView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCSightMessageProgressView : UIControl

@property (nonatomic) float progress;

@property (nonatomic, strong) UIColor *progressTintColor;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)setProgress:(float)progress animated:(BOOL)animated;

- (void)startIndeterminateAnimation;

- (void)stopIndeterminateAnimation;

- (void)resetStatus;

@end
