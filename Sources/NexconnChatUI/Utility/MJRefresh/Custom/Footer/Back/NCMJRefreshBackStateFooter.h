//
//  NCMJRefreshBackStateFooter.h
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "NCMJRefreshBackFooter.h"

@interface NCMJRefreshBackStateFooter : NCMJRefreshBackFooter
/** Spacing between the state label and indicator or arrow. */
@property (assign, nonatomic) CGFloat labelLeftInset;
/** Label displaying the refresh state. */
@property (weak, nonatomic, readonly) UILabel *stateLabel;
/** Sets the title for a refresh state. */
- (void)setTitle:(NSString *)title forState:(NCMJRefreshState)state;

/** Returns the title for a refresh state. */
- (NSString *)titleForState:(NCMJRefreshState)state;
@end
