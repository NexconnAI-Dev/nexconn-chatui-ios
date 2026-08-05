//
//  NCMJRefreshAutoStateFooter.h
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "NCMJRefreshAutoFooter.h"

@interface NCMJRefreshAutoStateFooter : NCMJRefreshAutoFooter
/** Spacing between the state label and indicator or arrow. */
@property (assign, nonatomic) CGFloat labelLeftInset;
/** Label displaying the refresh state. */
@property (weak, nonatomic, readonly) UILabel *stateLabel;

/** Sets the title for a refresh state. */
- (void)setTitle:(NSString *)title forState:(NCMJRefreshState)state;

/** Hides the refresh state label. */
@property (assign, nonatomic, getter=isRefreshingTitleHidden) BOOL refreshingTitleHidden;
@end
