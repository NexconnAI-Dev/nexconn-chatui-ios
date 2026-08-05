//  Source: https://github.com/CoderMJLee/MJRefresh
//  Additional reference:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  UIScrollView+Extension.h
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (NCMJExtension)
@property (readonly, nonatomic) UIEdgeInsets ncmj_inset;

@property (assign, nonatomic) CGFloat ncmj_insetT;
@property (assign, nonatomic) CGFloat ncmj_insetB;
@property (assign, nonatomic) CGFloat ncmj_insetL;
@property (assign, nonatomic) CGFloat ncmj_insetR;

@property (assign, nonatomic) CGFloat ncmj_offsetX;
@property (assign, nonatomic) CGFloat ncmj_offsetY;

@property (assign, nonatomic) CGFloat ncmj_contentW;
@property (assign, nonatomic) CGFloat ncmj_contentH;
@end
