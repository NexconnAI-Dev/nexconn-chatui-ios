//  Source: https://github.com/CoderMJLee/MJRefresh
//  Additional reference:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  NCMJRefreshFooter.m
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "NCMJRefreshFooter.h"
#include "UIScrollView+NCMJRefresh.h"

@interface NCMJRefreshFooter ()

@end

@implementation NCMJRefreshFooter
#pragma mark - Creation
+ (instancetype)footerWithRefreshingBlock:(NCMJRefreshComponentRefreshingBlock)refreshingBlock {
    NCMJRefreshFooter *cmp = [[self alloc] init];
    cmp.refreshingBlock = refreshingBlock;
    return cmp;
}
+ (instancetype)footerWithRefreshingTarget:(id)target refreshingAction:(SEL)action {
    NCMJRefreshFooter *cmp = [[self alloc] init];
    [cmp setRefreshingTarget:target refreshingAction:action];
    return cmp;
}

#pragma mark - Overrides
- (void)prepare {
    [super prepare];

    // Apply the standard footer height.
    self.ncmj_h = NCMJRefreshFooterHeight;

    // The compatibility flag has no automatic visibility behavior.
    //    self.automaticallyHidden = NO;
}

#pragma mark - Public Methods
- (void)endRefreshingWithNoMoreData {
    NCMJRefreshDispatchAsyncOnMainQueue(self.state = NCMJRefreshStateNoMoreData;)
}

- (void)noticeNoMoreData {
    [self endRefreshingWithNoMoreData];
}

- (void)resetNoMoreData {
    NCMJRefreshDispatchAsyncOnMainQueue(self.state = NCMJRefreshStateIdle;)
}

- (void)setAutomaticallyHidden:(BOOL)automaticallyHidden {
    _automaticallyHidden = automaticallyHidden;
}
@end
