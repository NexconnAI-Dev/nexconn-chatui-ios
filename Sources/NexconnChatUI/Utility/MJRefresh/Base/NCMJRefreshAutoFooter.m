//
//  NCMJRefreshAutoFooter.m
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "NCMJRefreshAutoFooter.h"

@interface NCMJRefreshAutoFooter ()
/** Whether a new drag gesture has begun. */
@property (assign, nonatomic, getter=isOneNewPan) BOOL oneNewPan;
@end

@implementation NCMJRefreshAutoFooter

#pragma mark - Initialization
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];

    if (newSuperview) { // Attached to a new superview.
        if (self.hidden == NO) {
            self.scrollView.ncmj_insetB += self.ncmj_h;
        }

        // Position the footer after the current content.
        self.ncmj_y = _scrollView.ncmj_contentH;
    } else { // Removed from its superview.
        if (self.hidden == NO) {
            self.scrollView.ncmj_insetB -= self.ncmj_h;
        }
    }
}

#pragma mark - Deprecated Methods
- (void)setAppearencePercentTriggerAutoRefresh:(CGFloat)appearencePercentTriggerAutoRefresh {
    self.triggerAutomaticallyRefreshPercent = appearencePercentTriggerAutoRefresh;
}

- (CGFloat)appearencePercentTriggerAutoRefresh {
    return self.triggerAutomaticallyRefreshPercent;
}

#pragma mark - Overrides
- (void)prepare {
    [super prepare];

    // Trigger only when the footer is fully visible by default.
    self.triggerAutomaticallyRefreshPercent = 1.0;

    // Enable automatic refresh by default.
    self.automaticallyRefresh = YES;

    // Require a new drag gesture before triggering another refresh.
    self.onlyRefreshPerDrag = YES;
}

- (void)scrollViewContentSizeDidChange:(NSDictionary *)change {
    [super scrollViewContentSizeDidChange:change];

    // Position the footer after the current content.
    self.ncmj_y = self.scrollView.ncmj_contentH + self.ignoredScrollViewContentInsetBottom;
}

- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change {
    [super scrollViewContentOffsetDidChange:change];

    if (self.state != NCMJRefreshStateIdle || !self.automaticallyRefresh || self.ncmj_y == 0)
        return;

    if (_scrollView.ncmj_insetT + _scrollView.ncmj_contentH >
        _scrollView.ncmj_h) { // Content exceeds one screen.
        // Use the scroll view's content height instead of the footer position in this threshold
        // calculation.
        if (_scrollView.ncmj_offsetY >= _scrollView.ncmj_contentH - _scrollView.ncmj_h +
                                            self.ncmj_h * self.triggerAutomaticallyRefreshPercent +
                                            _scrollView.ncmj_insetB - self.ncmj_h) {
            // Ignore downward movement to avoid duplicate triggers as the drag ends.
            CGPoint old = [change[@"old"] CGPointValue];
            CGPoint new = [ change[@"new"] CGPointValue ];
            if (new.y <= old.y)
                return;

            // Begin refreshing once the configured footer fraction is visible.
            [self beginRefreshing];
        }
    }
}

- (void)scrollViewPanStateDidChange:(NSDictionary *)change {
    [super scrollViewPanStateDidChange:change];

    if (self.state != NCMJRefreshStateIdle)
        return;

    UIGestureRecognizerState panState = _scrollView.panGestureRecognizer.state;
    if (panState == UIGestureRecognizerStateEnded) { // The drag ended.
        if (_scrollView.ncmj_insetT + _scrollView.ncmj_contentH <=
            _scrollView.ncmj_h) { // Content fits within one screen.
            if (_scrollView.ncmj_offsetY >= -_scrollView.ncmj_insetT) { // The user dragged upward.
                [self beginRefreshing];
            }
        } else { // Content exceeds one screen.
            if (_scrollView.ncmj_offsetY >=
                _scrollView.ncmj_contentH + _scrollView.ncmj_insetB - _scrollView.ncmj_h) {
                [self beginRefreshing];
            }
        }
    } else if (panState == UIGestureRecognizerStateBegan) {
        self.oneNewPan = YES;
    }
}

- (void)beginRefreshing {
    if (!self.isOneNewPan && self.isOnlyRefreshPerDrag)
        return;

    [super beginRefreshing];

    self.oneNewPan = NO;
}

- (void)setState:(NCMJRefreshState)state {
    NCMJRefreshCheckState

        if (state == NCMJRefreshStateRefreshing) {
        [self executeRefreshingCallback];
    }
    else if (state == NCMJRefreshStateNoMoreData || state == NCMJRefreshStateIdle) {
        if (NCMJRefreshStateRefreshing == oldState) {
            if (self.endRefreshingCompletionBlock) {
                self.endRefreshingCompletionBlock();
            }
        }
    }
}

- (void)setHidden:(BOOL)hidden {
    BOOL lastHidden = self.isHidden;

    [super setHidden:hidden];

    if (!lastHidden && hidden) {
        self.state = NCMJRefreshStateIdle;

        self.scrollView.ncmj_insetB -= self.ncmj_h;
    } else if (lastHidden && !hidden) {
        self.scrollView.ncmj_insetB += self.ncmj_h;

        // Position the footer after the current content.
        self.ncmj_y = _scrollView.ncmj_contentH;
    }
}
@end
