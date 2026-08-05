//  Source: https://github.com/CoderMJLee/MJRefresh
//  Additional reference:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
#import <UIKit/UIKit.h>

const CGFloat NCMJRefreshLabelLeftInset = 25;
const CGFloat NCMJRefreshHeaderHeight = 54.0;
const CGFloat NCMJRefreshFooterHeight = 44.0;
const CGFloat NCMJRefreshFastAnimationDuration = 0.25;
const CGFloat NCMJRefreshSlowAnimationDuration = 0.4;

NSString *const NCMJRefreshKeyPathContentOffset = @"contentOffset";
NSString *const NCMJRefreshKeyPathContentInset = @"contentInset";
NSString *const NCMJRefreshKeyPathContentSize = @"contentSize";
NSString *const NCMJRefreshKeyPathPanState = @"state";

NSString *const NCMJRefreshHeaderLastUpdatedTimeKey = @"NCMJRefreshHeaderLastUpdatedTimeKey";

NSString *const NCMJRefreshHeaderIdleText = @"NCMJRefreshHeaderIdleText";
NSString *const NCMJRefreshHeaderPullingText = @"NCMJRefreshHeaderPullingText";
NSString *const NCMJRefreshHeaderRefreshingText = @"NCMJRefreshHeaderRefreshingText";

NSString *const NCMJRefreshAutoFooterIdleText = @"NCMJRefreshAutoFooterIdleText";
NSString *const NCMJRefreshAutoFooterRefreshingText = @"NCMJRefreshAutoFooterRefreshingText";
NSString *const NCMJRefreshAutoFooterNoMoreDataText = @"NCMJRefreshAutoFooterNoMoreDataText";

NSString *const NCMJRefreshBackFooterIdleText = @"NCMJRefreshBackFooterIdleText";
NSString *const NCMJRefreshBackFooterPullingText = @"NCMJRefreshBackFooterPullingText";
NSString *const NCMJRefreshBackFooterRefreshingText = @"NCMJRefreshBackFooterRefreshingText";
NSString *const NCMJRefreshBackFooterNoMoreDataText = @"NCMJRefreshBackFooterNoMoreDataText";

NSString *const NCMJRefreshHeaderLastTimeText = @"NCMJRefreshHeaderLastTimeText";
NSString *const NCMJRefreshHeaderDateTodayText = @"NCMJRefreshHeaderDateTodayText";
NSString *const NCMJRefreshHeaderNoneLastDateText = @"NCMJRefreshHeaderNoneLastDateText";
