//
//  NCMJRefreshAutoFooter.h
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "NCMJRefreshFooter.h"

@interface NCMJRefreshAutoFooter : NCMJRefreshFooter
/** Whether refresh triggers automatically. Defaults to YES. */
@property (assign, nonatomic, getter=isAutomaticallyRefresh) BOOL automaticallyRefresh;

/** Visible footer fraction used to trigger automatic refresh when content exceeds one screen.
 * Defaults to 1.0. */
@property (assign, nonatomic) CGFloat appearencePercentTriggerAutoRefresh NCMJRefreshDeprecated(
    "Use triggerAutomaticallyRefreshPercent.");

/** Visible footer fraction used to trigger automatic refresh when content exceeds one screen.
 * Defaults to 1.0. */
@property (assign, nonatomic) CGFloat triggerAutomaticallyRefreshPercent;

/** Whether each drag gesture may trigger at most one refresh. */
@property (assign, nonatomic, getter=isOnlyRefreshPerDrag) BOOL onlyRefreshPerDrag;
@end
