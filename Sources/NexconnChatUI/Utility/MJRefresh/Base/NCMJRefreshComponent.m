//  Source: https://github.com/CoderMJLee/MJRefresh
//  Additional reference:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  NCMJRefreshComponent.m
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "NCMJRefreshComponent.h"
#import "NCMJRefreshConst.h"

@interface NCMJRefreshComponent ()
@property (strong, nonatomic) UIPanGestureRecognizer *pan;
@end

@implementation NCMJRefreshComponent
#pragma mark - Initialization
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Perform initial setup.
        [self prepare];

        // Start in the idle state.
        self.state = NCMJRefreshStateIdle;
    }
    return self;
}

- (void)prepare {
    // Base appearance and sizing behavior.
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews {
    [self placeSubviews];

    [super layoutSubviews];
}

- (void)placeSubviews {
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];

    // Refresh controls can only attach to UIScrollView instances.
    if (newSuperview && ![newSuperview isKindOfClass:[UIScrollView class]])
        return;

    // Remove observers from the previous superview.
    [self removeObservers];

    if (newSuperview) { // Attached to a new superview.
        // Keep the owning scroll view.
        _scrollView = (UIScrollView *)newSuperview;

        // Match the scroll view width.
        self.ncmj_w = _scrollView.ncmj_w;
        // Align with the scroll view's left content inset.
        self.ncmj_x = -_scrollView.ncmj_insetL;

        // Always allow vertical bouncing.
        _scrollView.alwaysBounceVertical = YES;
        // Capture the initial content inset.
        _scrollViewOriginalInset = _scrollView.ncmj_inset;

        // Observe scrolling and pan state changes.
        [self addObservers];
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    if (self.state == NCMJRefreshStateWillRefresh) {
        // Complete a refresh requested before the view became visible.
        self.state = NCMJRefreshStateRefreshing;
    }
}

#pragma mark - KVO
- (void)addObservers {
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    [self.scrollView addObserver:self forKeyPath:NCMJRefreshKeyPathContentOffset options:options context:nil];
    [self.scrollView addObserver:self forKeyPath:NCMJRefreshKeyPathContentSize options:options context:nil];
    self.pan = self.scrollView.panGestureRecognizer;
    [self.pan addObserver:self forKeyPath:NCMJRefreshKeyPathPanState options:options context:nil];
}

- (void)removeObservers {
    [self.superview removeObserver:self forKeyPath:NCMJRefreshKeyPathContentOffset];
    [self.superview removeObserver:self forKeyPath:NCMJRefreshKeyPathContentSize];
    [self.pan removeObserver:self forKeyPath:NCMJRefreshKeyPathPanState];
    self.pan = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    // Ignore observations while interaction is disabled.
    if (!self.userInteractionEnabled)
        return;

    // Content size changes must be handled even while hidden.
    if ([keyPath isEqualToString:NCMJRefreshKeyPathContentSize]) {
        [self scrollViewContentSizeDidChange:change];
    }

    // Ignore other observations while hidden.
    if (self.hidden)
        return;
    if ([keyPath isEqualToString:NCMJRefreshKeyPathContentOffset]) {
        [self scrollViewContentOffsetDidChange:change];
    } else if ([keyPath isEqualToString:NCMJRefreshKeyPathPanState]) {
        [self scrollViewPanStateDidChange:change];
    }
}

- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change {
}
- (void)scrollViewContentSizeDidChange:(NSDictionary *)change {
}
- (void)scrollViewPanStateDidChange:(NSDictionary *)change {
}

#pragma mark - Public Methods
#pragma mark Configure Callback Target and Action
- (void)setRefreshingTarget:(id)target refreshingAction:(SEL)action {
    self.refreshingTarget = target;
    self.refreshingAction = action;
}

- (void)setState:(NCMJRefreshState)state {
    _state = state;

    // Defer layout until setState: and any state-specific text updates have completed.
    NCMJRefreshDispatchAsyncOnMainQueue([self setNeedsLayout];)
}

#pragma mark Begin Refreshing
- (void)beginRefreshing {
    [UIView animateWithDuration:NCMJRefreshFastAnimationDuration
                     animations:^{
                         self.alpha = 1.0;
                     }];
    self.pullingPercent = 1.0;
    // Keep the control fully visible while refreshing.
    if (self.window) {
        self.state = NCMJRefreshStateRefreshing;
    } else {
        // Avoid resetting a header inset when beginRefreshing is called again during a refresh.
        if (self.state != NCMJRefreshStateRefreshing) {
            self.state = NCMJRefreshStateWillRefresh;
            // Redraw so the pending refresh starts when the controller becomes visible again.
            [self setNeedsDisplay];
        }
    }
}

- (void)beginRefreshingWithCompletionBlock:(void (^)(void))completionBlock {
    self.beginRefreshingCompletionBlock = completionBlock;

    [self beginRefreshing];
}

#pragma mark End Refreshing
- (void)endRefreshing {
    NCMJRefreshDispatchAsyncOnMainQueue(self.state = NCMJRefreshStateIdle;)
}

- (void)endRefreshingWithCompletionBlock:(void (^)(void))completionBlock {
    self.endRefreshingCompletionBlock = completionBlock;

    [self endRefreshing];
}

#pragma mark Refreshing State
- (BOOL)isRefreshing {
    return self.state == NCMJRefreshStateRefreshing || self.state == NCMJRefreshStateWillRefresh;
}

#pragma mark Automatic Alpha
- (void)setAutoChangeAlpha:(BOOL)autoChangeAlpha {
    self.automaticallyChangeAlpha = autoChangeAlpha;
}

- (BOOL)isAutoChangeAlpha {
    return self.isAutomaticallyChangeAlpha;
}

- (void)setAutomaticallyChangeAlpha:(BOOL)automaticallyChangeAlpha {
    _automaticallyChangeAlpha = automaticallyChangeAlpha;

    if (self.isRefreshing)
        return;

    if (automaticallyChangeAlpha) {
        self.alpha = self.pullingPercent;
    } else {
        self.alpha = 1.0;
    }
}

#pragma mark Pull Progress Alpha
- (void)setPullingPercent:(CGFloat)pullingPercent {
    _pullingPercent = pullingPercent;

    if (self.isRefreshing)
        return;

    if (self.isAutomaticallyChangeAlpha) {
        self.alpha = pullingPercent;
    }
}

#pragma mark - Internal Methods
- (void)executeRefreshingCallback {
    NCMJRefreshDispatchAsyncOnMainQueue({
        if (self.refreshingBlock) {
            self.refreshingBlock();
        }
        if ([self.refreshingTarget respondsToSelector:self.refreshingAction]) {
            NCMJRefreshMsgSend(NCMJRefreshMsgTarget(self.refreshingTarget), self.refreshingAction, self);
        }
        if (self.beginRefreshingCompletionBlock) {
            self.beginRefreshingCompletionBlock();
        }
    })
}
@end

@implementation UILabel (NCMJRefresh)
+ (instancetype)ncmj_label {
    UILabel *label = [[self alloc] init];
    label.font = NCMJRefreshLabelFont;
    label.textColor = NCMJRefreshLabelTextColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    return label;
}

- (CGFloat)ncmj_textWidth {
    CGFloat stringWidth = 0;
    CGSize size = CGSizeMake(MAXFLOAT, MAXFLOAT);
    if (self.text.length > 0) {
        stringWidth = [self.text boundingRectWithSize:size
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{
                                               NSFontAttributeName : self.font
                                           }
                                              context:nil]
                          .size.width;
    }
    return stringWidth;
}
@end
