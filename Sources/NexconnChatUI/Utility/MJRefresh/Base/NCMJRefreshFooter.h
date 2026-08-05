//  Source: https://github.com/CoderMJLee/MJRefresh
//  Additional reference:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  NCMJRefreshFooter.h
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//  Pull-up refresh footer

#import "NCMJRefreshComponent.h"

@interface NCMJRefreshFooter : NCMJRefreshComponent
/** Creates a footer with a refresh block. */
+ (instancetype)footerWithRefreshingBlock:(NCMJRefreshComponentRefreshingBlock)refreshingBlock;
/** Creates a footer with a target and refresh action. */
+ (instancetype)footerWithRefreshingTarget:(id)target refreshingAction:(SEL)action;

/** Ends refreshing and marks that no more data is available. */
- (void)endRefreshingWithNoMoreData;
- (void)noticeNoMoreData NCMJRefreshDeprecated("Use endRefreshingWithNoMoreData.");

/** Clears the no-more-data state. */
- (void)resetNoMoreData;

/** Additional bottom content inset ignored when positioning the footer. */
@property (assign, nonatomic) CGFloat ignoredScrollViewContentInsetBottom;

/** Deprecated compatibility flag. This implementation stores the value but does not show or hide the footer. */
@property (assign, nonatomic, getter=isAutomaticallyHidden)
    BOOL automaticallyHidden NCMJRefreshDeprecated("Deprecated. Control the footer's hidden property directly.");
@end
