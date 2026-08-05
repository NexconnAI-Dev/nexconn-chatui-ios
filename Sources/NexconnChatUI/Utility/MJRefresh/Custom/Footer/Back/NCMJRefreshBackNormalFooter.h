//
//  NCMJRefreshBackNormalFooter.h
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "NCMJRefreshBackStateFooter.h"

@interface NCMJRefreshBackNormalFooter : NCMJRefreshBackStateFooter
@property (weak, nonatomic, readonly) UIImageView *arrowView;
/** Activity indicator style. */
@property (assign, nonatomic) UIActivityIndicatorViewStyle activityIndicatorViewStyle;
@end
