//  Source: https://github.com/CoderMJLee/MJRefresh
//  Additional reference:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  UIScrollView+NCMJRefresh.h
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//  Adds refresh controls to UIScrollView

#import "NCMJRefreshConst.h"
#import <UIKit/UIKit.h>

@class NCMJRefreshHeader, NCMJRefreshFooter;

@interface UIScrollView (NCMJRefresh)
/** Pull-up refresh footer. */
@property (strong, nonatomic) NCMJRefreshFooter *ncmj_footer;
@property (strong, nonatomic) NCMJRefreshFooter *ncfooter NCMJRefreshDeprecated("Use ncmj_footer.");

#pragma mark - other
- (NSInteger)ncmj_totalDataCount;

@end
