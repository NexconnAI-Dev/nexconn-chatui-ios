//  Source: https://github.com/CoderMJLee/MJRefresh
//  Additional reference:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import "NCChatUILog.h"

// Weak reference helpers
#define MJWeakSelf __weak typeof(self) weakSelf = self;

// Logging
#define NCMJRefreshLog(...) NCLogD(__VA_ARGS__)

// Deprecation notices
#define NCMJRefreshDeprecated(instead) NS_DEPRECATED(2_0, 2_0, 2_0, 2_0, instead)

// Runtime objc_msgSend
#define NCMJRefreshMsgSend(...) ((void (*)(void *, SEL, UIView *))objc_msgSend)(__VA_ARGS__)
#define NCMJRefreshMsgTarget(target) (__bridge void *)(target)

// RGB colors
#define NCMJRefreshColor(r, g, b) [UIColor colorWithRed:(r) / 255.0 green:(g) / 255.0 blue:(b) / 255.0 alpha:1.0]

// Text color
#define NCMJRefreshLabelTextColor NCMJRefreshColor(90, 90, 90)

// Font size
#define NCMJRefreshLabelFont [UIFont boldSystemFontOfSize:14]

// Constants
UIKIT_EXTERN const CGFloat NCMJRefreshLabelLeftInset;
UIKIT_EXTERN const CGFloat NCMJRefreshHeaderHeight;
UIKIT_EXTERN const CGFloat NCMJRefreshFooterHeight;
UIKIT_EXTERN const CGFloat NCMJRefreshFastAnimationDuration;
UIKIT_EXTERN const CGFloat NCMJRefreshSlowAnimationDuration;

UIKIT_EXTERN NSString *const NCMJRefreshKeyPathContentOffset;
UIKIT_EXTERN NSString *const NCMJRefreshKeyPathContentSize;
UIKIT_EXTERN NSString *const NCMJRefreshKeyPathContentInset;
UIKIT_EXTERN NSString *const NCMJRefreshKeyPathPanState;

UIKIT_EXTERN NSString *const NCMJRefreshHeaderLastUpdatedTimeKey;

UIKIT_EXTERN NSString *const NCMJRefreshHeaderIdleText;
UIKIT_EXTERN NSString *const NCMJRefreshHeaderPullingText;
UIKIT_EXTERN NSString *const NCMJRefreshHeaderRefreshingText;

UIKIT_EXTERN NSString *const NCMJRefreshAutoFooterIdleText;
UIKIT_EXTERN NSString *const NCMJRefreshAutoFooterRefreshingText;
UIKIT_EXTERN NSString *const NCMJRefreshAutoFooterNoMoreDataText;

UIKIT_EXTERN NSString *const NCMJRefreshBackFooterIdleText;
UIKIT_EXTERN NSString *const NCMJRefreshBackFooterPullingText;
UIKIT_EXTERN NSString *const NCMJRefreshBackFooterRefreshingText;
UIKIT_EXTERN NSString *const NCMJRefreshBackFooterNoMoreDataText;

UIKIT_EXTERN NSString *const NCMJRefreshHeaderLastTimeText;
UIKIT_EXTERN NSString *const NCMJRefreshHeaderDateTodayText;
UIKIT_EXTERN NSString *const NCMJRefreshHeaderNoneLastDateText;

// State transition guard
#define NCMJRefreshCheckState                                                                                          \
    NCMJRefreshState oldState = self.state;                                                                            \
    if (state == oldState)                                                                                             \
        return;                                                                                                        \
    [super setState:state];

// Dispatch asynchronously to the main queue without retaining self.
#define NCMJRefreshDispatchAsyncOnMainQueue(x)                                                                         \
    __weak typeof(self) weakSelf = self;                                                                               \
    dispatch_async(dispatch_get_main_queue(), ^{                                                                       \
        typeof(weakSelf) self = weakSelf;                                                                              \
        { x }                                                                                                          \
    });
