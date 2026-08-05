// Source: https://github.com/CoderMJLee/MJRefresh
// Additional reference:
// http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  UIView+Extension.h
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import <UIKit/UIKit.h>

@interface UIView (NCMJExtension)
@property (assign, nonatomic) CGFloat ncmj_x;
@property (assign, nonatomic) CGFloat ncmj_y;
@property (assign, nonatomic) CGFloat ncmj_w;
@property (assign, nonatomic) CGFloat ncmj_h;
@property (assign, nonatomic) CGSize ncmj_size;
@property (assign, nonatomic) CGPoint ncmj_origin;
@end
