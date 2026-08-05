//
//  NCMJRefreshBackFooter.m
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "NCMJRefreshBackFooter.h"

@interface NCMJRefreshBackFooter ()
@property (assign, nonatomic) NSInteger lastRefreshCount;
@property (assign, nonatomic) CGFloat lastBottomDelta;
@end

@implementation NCMJRefreshBackFooter

#pragma mark - Initialization
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];

    [self scrollViewContentSizeDidChange:nil];
}

#pragma mark - Overrides
- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change {
    [super scrollViewContentOffsetDidChange:change];

    // Ignore offset changes while refreshing.
    if (self.state == NCMJRefreshStateRefreshing)
        return;

    _scrollViewOriginalInset = self.scrollView.ncmj_inset;

    // Current content offset.
    CGFloat currentOffsetY = self.scrollView.ncmj_offsetY;
    // Offset at which the footer first becomes visible.
    CGFloat happenOffsetY = [self happenOffsetY];
    // Ignore positions where the footer is not visible.
    if (currentOffsetY <= happenOffsetY)
        return;

    CGFloat pullingPercent = (currentOffsetY - happenOffsetY) / self.ncmj_h;

    // In the no-more-data state, update only the pull progress.
    if (self.state == NCMJRefreshStateNoMoreData) {
        self.pullingPercent = pullingPercent;
        return;
    }

    if (self.scrollView.isDragging) {
        self.pullingPercent = pullingPercent;
        // Boundary between idle and ready-to-refresh states.
        CGFloat normal2pullingOffsetY = happenOffsetY + self.ncmj_h;

        if (self.state == NCMJRefreshStateIdle && currentOffsetY > normal2pullingOffsetY) {
            // Enter the ready-to-refresh state.
            self.state = NCMJRefreshStatePulling;
        } else if (self.state == NCMJRefreshStatePulling && currentOffsetY <= normal2pullingOffsetY) {
            // Return to the idle state.
            self.state = NCMJRefreshStateIdle;
        }
    } else if (self.state == NCMJRefreshStatePulling) { // The drag ended while ready to refresh.
        // Begin refreshing.
        [self beginRefreshing];
    } else if (pullingPercent < 1) {
        self.pullingPercent = pullingPercent;
    }
}

- (void)scrollViewContentSizeDidChange:(NSDictionary *)change {
    [super scrollViewContentSizeDidChange:change];

    // Effective content height.
    CGFloat contentHeight = self.scrollView.ncmj_contentH + self.ignoredScrollViewContentInsetBottom;
    // Visible scroll view height.
    CGFloat scrollHeight = self.scrollView.ncmj_h - self.scrollViewOriginalInset.top -
                           self.scrollViewOriginalInset.bottom + self.ignoredScrollViewContentInsetBottom;
    // Position the footer after the larger of the content and visible area.
    self.ncmj_y = MAX(contentHeight, scrollHeight);
}

- (void)setState:(NCMJRefreshState)state {
    NCMJRefreshCheckState

        // Update properties for the new state.
        if (state == NCMJRefreshStateNoMoreData || state == NCMJRefreshStateIdle) {
        // Finish the active refresh.
        if (NCMJRefreshStateRefreshing == oldState) {
            [UIView animateWithDuration:NCMJRefreshSlowAnimationDuration
                animations:^{
                    self.scrollView.ncmj_insetB -= self.lastBottomDelta;

                    if (self.endRefreshingAnimateCompletionBlock) {
                        self.endRefreshingAnimateCompletionBlock();
                    }
                    // Apply automatic alpha behavior.
                    if (self.isAutomaticallyChangeAlpha)
                        self.alpha = 0.0;
                }
                completion:^(BOOL finished) {
                    self.pullingPercent = 0.0;

                    if (self.endRefreshingCompletionBlock) {
                        self.endRefreshingCompletionBlock();
                    }
                }];
        }

        CGFloat deltaH = [self heightForContentBreakView];
        // Preserve the current offset when newly loaded content changes the item count.
        if (NCMJRefreshStateRefreshing == oldState && deltaH > 0 &&
            self.scrollView.ncmj_totalDataCount != self.lastRefreshCount) {
            self.scrollView.ncmj_offsetY = self.scrollView.ncmj_offsetY;
        }
    }
    else if (state == NCMJRefreshStateRefreshing) {
        // Record the item count before refreshing.
        self.lastRefreshCount = self.scrollView.ncmj_totalDataCount;

        [UIView animateWithDuration:NCMJRefreshFastAnimationDuration
            animations:^{
                CGFloat bottom = self.ncmj_h + self.scrollViewOriginalInset.bottom;
                CGFloat deltaH = [self heightForContentBreakView];
                if (deltaH < 0) { // Content is shorter than the visible area.
                    bottom -= deltaH;
                }
                self.lastBottomDelta = bottom - self.scrollView.ncmj_insetB;
                self.scrollView.ncmj_insetB = bottom;
                self.scrollView.ncmj_offsetY = [self happenOffsetY] + self.ncmj_h;
            }
            completion:^(BOOL finished) {
                [self executeRefreshingCallback];
            }];
    }
}
#pragma mark - Private Methods
#pragma mark Content Height Beyond the Visible Area
- (CGFloat)heightForContentBreakView {
    CGFloat h =
        self.scrollView.frame.size.height - self.scrollViewOriginalInset.bottom - self.scrollViewOriginalInset.top;
    return self.scrollView.contentSize.height - h;
}

#pragma mark Offset Where the Footer First Appears
- (CGFloat)happenOffsetY {
    CGFloat deltaH = [self heightForContentBreakView];
    if (deltaH > 0) {
        return deltaH - self.scrollViewOriginalInset.top;
    } else {
        return -self.scrollViewOriginalInset.top;
    }
}
@end
