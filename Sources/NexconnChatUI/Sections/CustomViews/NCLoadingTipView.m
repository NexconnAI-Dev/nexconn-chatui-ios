//
//  NCLoadingTipView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCLoadingTipView.h"
#import "NCBaseImageView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"

@interface NCLoadingTipView()
@property (nonatomic, copy) NSString *tip;
@property (nonatomic, strong) NCBaseImageView *loadingImageView;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIView *containerView;

@end
@implementation NCLoadingTipView

+ (NCLoadingTipView *)loadingWithTip:(NSString *)tip
                          parentView:(UIView *)parentView
{
    NCLoadingTipView *view = [[NCLoadingTipView alloc] initWithTip:tip];
    view.frame = parentView.bounds;
    [parentView addSubview:view];
    return view;
}

+ (NCLoadingTipView *)loadingWithTip:(NSString *)tip {
    NCLoadingTipView *view = [[NCLoadingTipView alloc] initWithTip:tip];
    UIWindow *window = [NCChatUIUtility getKeyWindow];
    if (!window) {
        return view;
    }
    view.frame = window.bounds;
    [window addSubview:view];
    return view;
}

- (void)startLoading {
    [self startAnimation];
    self.alpha = 1;
    self.userInteractionEnabled = YES;
}

- (void)stopLoading {
    [self stopAnimation];
    [self removeFromSuperview];
}

- (instancetype)initWithTip:(NSString *)tip
{
    self = [super init];
    if (self) {
        self.tip = tip;
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.alpha = 0;
    self.userInteractionEnabled = NO;
    self.tipLabel.text = self.tip;
    [self.tipLabel sizeToFit];
    
    [self.containerView addSubview:self.tipLabel];
    [self.containerView addSubview:self.loadingImageView];
    [self addSubview:self.containerView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat containerWidth = 24 + self.loadingImageView.frame.size.width+8+self.tipLabel.frame.size.width;
    CGFloat containerHeight = 41;
    
    self.containerView.bounds = CGRectMake(0, 0, containerWidth, containerHeight);
    self.containerView.center = self.center;
    
    self.loadingImageView.frame = CGRectMake(10, (containerHeight-27)/2, 27, 27);
    self.tipLabel.frame = CGRectMake(10 + 27 + 8,
                                     (containerHeight - self.tipLabel.frame.size.height)/2,
                                     self.tipLabel.frame.size.width,
                                     self.tipLabel.frame.size.height);
}

- (void)startAnimation {
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
    rotationAnimation.duration = 1.5;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = MAXFLOAT;
    [self.loadingImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopAnimation {
    if (self.loadingImageView) {
        [self.loadingImageView.layer removeAnimationForKey:@"rotationAnimation"];
    }
}

- (NCBaseImageView *)loadingImageView {
    if (!_loadingImageView) {
        _loadingImageView = [[NCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 27, 27)];
        _loadingImageView.image = NCDynamicImage(@"channel_msg_combine_loading_img");
    }
    return _loadingImageView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.font = [UIFont systemFontOfSize:15];
        _tipLabel.numberOfLines = 1;
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.backgroundColor = [UIColor clearColor];
        _tipLabel.textColor = NCDynamicColor(@"control_title_white_color");
    }
    return _tipLabel;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
        _containerView.layer.cornerRadius = 3;
        [_containerView.layer masksToBounds];
    }
    return _containerView;
}
@end
