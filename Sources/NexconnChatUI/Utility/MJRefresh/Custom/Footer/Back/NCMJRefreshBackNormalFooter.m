//
//  NCMJRefreshBackNormalFooter.m
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "NCMJRefreshBackNormalFooter.h"

@interface NCMJRefreshBackNormalFooter () {
    __unsafe_unretained UIImageView *_arrowView;
}
@property (weak, nonatomic) UIActivityIndicatorView *loadingView;
@end

@implementation NCMJRefreshBackNormalFooter
#pragma mark - Lazy-Loaded Subviews
- (UIImageView *)arrowView {
    if (!_arrowView) {
        UIImageView *arrowView = [[UIImageView alloc] initWithImage:nil];
        [self addSubview:_arrowView = arrowView];
    }
    return _arrowView;
}

- (UIActivityIndicatorView *)loadingView {
    if (!_loadingView) {
        UIActivityIndicatorView *loadingView =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.activityIndicatorViewStyle];
        loadingView.hidesWhenStopped = YES;
        [self addSubview:_loadingView = loadingView];
    }
    return _loadingView;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
    _activityIndicatorViewStyle = activityIndicatorViewStyle;

    self.loadingView = nil;
    [self setNeedsLayout];
}
#pragma mark - Overrides
- (void)prepare {
    [super prepare];

    self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
}

- (void)placeSubviews {
    [super placeSubviews];

    // Align the arrow vertically with the label.
    CGFloat arrowCenterX = self.ncmj_w * 0.5;
    if (!self.stateLabel.hidden) {
        arrowCenterX -= self.labelLeftInset + self.stateLabel.ncmj_textWidth * 0.5;
    }
    CGFloat arrowCenterY = self.ncmj_h * 0.5;
    CGPoint arrowCenter = CGPointMake(arrowCenterX, arrowCenterY);

    // Arrow image.
    if (self.arrowView.constraints.count == 0) {
        self.arrowView.ncmj_size = self.arrowView.image.size;
        self.arrowView.center = arrowCenter;
    }

    // Activity indicator.
    if (self.loadingView.constraints.count == 0) {
        self.loadingView.center = arrowCenter;
    }

    self.arrowView.tintColor = self.stateLabel.textColor;
}

- (void)setState:(NCMJRefreshState)state {
    NCMJRefreshCheckState

        // Update subviews for the new state.
        if (state == NCMJRefreshStateIdle) {
        if (oldState == NCMJRefreshStateRefreshing) {
            self.arrowView.transform = CGAffineTransformMakeRotation(0.000001 - M_PI);
            [UIView animateWithDuration:NCMJRefreshSlowAnimationDuration
                animations:^{
                    self.loadingView.alpha = 0.0;
                }
                completion:^(BOOL finished) {
                    // Stop only if the state is still idle when the animation completes.
                    if (state != NCMJRefreshStateIdle)
                        return;

                    self.loadingView.alpha = 1.0;
                    [self.loadingView stopAnimating];

                    self.arrowView.hidden = NO;
                }];
        } else {
            self.arrowView.hidden = NO;
            [self.loadingView stopAnimating];
            [UIView animateWithDuration:NCMJRefreshFastAnimationDuration
                             animations:^{
                                 self.arrowView.transform = CGAffineTransformMakeRotation(0.000001 - M_PI);
                             }];
        }
    }
    else if (state == NCMJRefreshStatePulling) {
        self.arrowView.hidden = NO;
        [self.loadingView stopAnimating];
        [UIView animateWithDuration:NCMJRefreshFastAnimationDuration
                         animations:^{
                             self.arrowView.transform = CGAffineTransformIdentity;
                         }];
    }
    else if (state == NCMJRefreshStateRefreshing) {
        self.arrowView.hidden = YES;
        [self.loadingView startAnimating];
    }
    else if (state == NCMJRefreshStateNoMoreData) {
        self.arrowView.hidden = YES;
        [self.loadingView stopAnimating];
    }
}

@end
