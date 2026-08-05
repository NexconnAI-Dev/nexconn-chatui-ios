//  Source: https://github.com/CoderMJLee/MJRefresh
//  Additional reference:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  UIView+Extension.m
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "UIView+NCMJExtension.h"

@implementation UIView (NCMJExtension)
- (void)setNcmj_x:(CGFloat)mj_x {
    CGRect frame = self.frame;
    frame.origin.x = mj_x;
    self.frame = frame;
}

- (CGFloat)ncmj_x {
    return self.frame.origin.x;
}

- (void)setNcmj_y:(CGFloat)mj_y {
    CGRect frame = self.frame;
    frame.origin.y = mj_y;
    self.frame = frame;
}

- (CGFloat)ncmj_y {
    return self.frame.origin.y;
}

- (void)setNcmj_w:(CGFloat)mj_w {
    CGRect frame = self.frame;
    frame.size.width = mj_w;
    self.frame = frame;
}

- (CGFloat)ncmj_w {
    return self.frame.size.width;
}

- (void)setNcmj_h:(CGFloat)mj_h {
    CGRect frame = self.frame;
    frame.size.height = mj_h;
    self.frame = frame;
}

- (CGFloat)ncmj_h {
    return self.frame.size.height;
}

- (void)setNcmj_size:(CGSize)mj_size {
    CGRect frame = self.frame;
    frame.size = mj_size;
    self.frame = frame;
}

- (CGSize)ncmj_size {
    return self.frame.size;
}

- (void)setNcmj_origin:(CGPoint)mj_origin {
    CGRect frame = self.frame;
    frame.origin = mj_origin;
    self.frame = frame;
}

- (CGPoint)ncmj_origin {
    return self.frame.origin;
}
@end
