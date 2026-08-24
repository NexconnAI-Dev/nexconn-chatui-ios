//  Source: https://github.com/CoderMJLee/MJRefresh
//  Additional reference:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  NCMJRefreshComponent.h
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//  Base class for refresh controls

#import "NCMJRefreshConst.h"
#import "UIScrollView+NCMJExtension.h"
#import "UIScrollView+NCMJRefresh.h"
#import "UIView+NCMJExtension.h"
#import <UIKit/UIKit.h>

/** Refresh control state. */
typedef NS_ENUM(NSInteger, NCMJRefreshState) {
    /** Idle state. */
    NCMJRefreshStateIdle = 1,
    /** Ready to refresh when the drag is released. */
    NCMJRefreshStatePulling,
    /** Refreshing. */
    NCMJRefreshStateRefreshing,
    /** Scheduled to refresh when the view becomes visible. */
    NCMJRefreshStateWillRefresh,
    /** All data has loaded and no more items are available. */
    NCMJRefreshStateNoMoreData
};

/** Callback invoked after entering the refreshing state. */
typedef void (^NCMJRefreshComponentRefreshingBlock)(void);
/** Completion callback invoked after refresh begins. */
typedef void (^NCMJRefreshComponentbeginRefreshingCompletionBlock)(void);
/** Completion callback invoked after refresh ends. */
typedef void (^NCMJRefreshComponentEndRefreshingCompletionBlock)(void);

/** Base class for refresh controls. */
@interface NCMJRefreshComponent : UIView {
    /** Content inset captured when the control attaches to the scroll view. */
    UIEdgeInsets _scrollViewOriginalInset;
    /** Owning scroll view. */
    __weak UIScrollView *_scrollView;
}
#pragma mark - Refresh Callbacks
/** Callback invoked while refreshing. */
@property (copy, nonatomic) NCMJRefreshComponentRefreshingBlock refreshingBlock;
/** Sets the refresh callback target and action. */
- (void)setRefreshingTarget:(id)target refreshingAction:(SEL)action;

/** Refresh callback target. */
@property (weak, nonatomic) id refreshingTarget;
/** Refresh callback action. */
@property (assign, nonatomic) SEL refreshingAction;
/** Executes refresh callbacks. Subclasses call this when their transition is complete. */
- (void)executeRefreshingCallback;

#pragma mark - Refresh State
/** Enters the refreshing state. */
- (void)beginRefreshing;
- (void)beginRefreshingWithCompletionBlock:(void (^)(void))completionBlock;
/** Completion callback invoked after refresh begins. */
@property (copy, nonatomic)
    NCMJRefreshComponentbeginRefreshingCompletionBlock beginRefreshingCompletionBlock;
/** Completion callback invoked during the refresh-ending animation. */
@property (copy, nonatomic)
    NCMJRefreshComponentEndRefreshingCompletionBlock endRefreshingAnimateCompletionBlock;
/** Completion callback invoked after refresh ends. */
@property (copy, nonatomic)
    NCMJRefreshComponentEndRefreshingCompletionBlock endRefreshingCompletionBlock;
/** Ends the refreshing state. */
- (void)endRefreshing;
- (void)endRefreshingWithCompletionBlock:(void (^)(void))completionBlock;
/** Whether the control is refreshing or waiting to refresh. */
@property (assign, nonatomic, readonly, getter=isRefreshing) BOOL refreshing;
//- (BOOL)isRefreshing;
/** Refresh state, typically managed by subclasses. */
@property (assign, nonatomic) NCMJRefreshState state;

#pragma mark - Subclass Access
/** Content inset captured when the control attaches to the scroll view. */
@property (assign, nonatomic, readonly) UIEdgeInsets scrollViewOriginalInset;
/** Owning scroll view. */
@property (weak, nonatomic, readonly) UIScrollView *scrollView;

#pragma mark - Subclass Overrides
/** Performs initial setup. */
- (void)prepare NS_REQUIRES_SUPER;
/** Lays out subviews. */
- (void)placeSubviews NS_REQUIRES_SUPER;
/** Called when the scroll view's contentOffset changes. */
- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change NS_REQUIRES_SUPER;
/** Called when the scroll view's contentSize changes. */
- (void)scrollViewContentSizeDidChange:(NSDictionary *)change NS_REQUIRES_SUPER;
/** Called when the scroll view's pan state changes. */
- (void)scrollViewPanStateDidChange:(NSDictionary *)change NS_REQUIRES_SUPER;

#pragma mark - Other
/** Pull progress. Subclasses may override its behavior. */
@property (assign, nonatomic) CGFloat pullingPercent;
/** Automatically adjusts alpha from the pull progress. */
@property (assign, nonatomic, getter=isAutoChangeAlpha)
    BOOL autoChangeAlpha NCMJRefreshDeprecated("Use automaticallyChangeAlpha.");
/** Automatically adjusts alpha from the pull progress. */
@property (assign, nonatomic, getter=isAutomaticallyChangeAlpha) BOOL automaticallyChangeAlpha;
@end

@interface UILabel (NCMJRefresh)
+ (instancetype)ncmj_label;
- (CGFloat)ncmj_textWidth;
@end
