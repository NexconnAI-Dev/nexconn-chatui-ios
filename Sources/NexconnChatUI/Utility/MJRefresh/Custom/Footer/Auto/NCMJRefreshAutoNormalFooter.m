//
//  NCMJRefreshAutoNormalFooter.m
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "NCMJRefreshAutoNormalFooter.h"

@interface NCMJRefreshAutoNormalFooter ()
@property (weak, nonatomic) UIActivityIndicatorView *loadingView;
@end

@implementation NCMJRefreshAutoNormalFooter
#pragma mark - Lazy-Loaded Subviews
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

    if (self.loadingView.constraints.count)
        return;

    // Activity indicator.
    CGFloat loadingCenterX = self.ncmj_w * 0.5;
    if (!self.isRefreshingTitleHidden) {
        loadingCenterX -= self.stateLabel.ncmj_textWidth * 0.5 + self.labelLeftInset;
    }
    CGFloat loadingCenterY = self.ncmj_h * 0.5;
    self.loadingView.center = CGPointMake(loadingCenterX, loadingCenterY);
}

- (void)setState:(NCMJRefreshState)state {
    NCMJRefreshCheckState

        // Update the indicator for the new state.
        if (state == NCMJRefreshStateNoMoreData || state == NCMJRefreshStateIdle) {
        [self.loadingView stopAnimating];
    }
    else if (state == NCMJRefreshStateRefreshing) {
        [self.loadingView startAnimating];
    }
}

@end
