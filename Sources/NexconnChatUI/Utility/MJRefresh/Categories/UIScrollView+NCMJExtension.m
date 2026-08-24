//  Source: https://github.com/CoderMJLee/MJRefresh
//  Additional reference:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  UIScrollView+Extension.m
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "UIScrollView+NCMJExtension.h"
#import <objc/runtime.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"

static BOOL respondsToAdjustedContentInset_;

@implementation UIScrollView (NCMJExtension)

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      respondsToAdjustedContentInset_ =
          [self instancesRespondToSelector:@selector(adjustedContentInset)];
    });
}

- (UIEdgeInsets)ncmj_inset {
#ifdef __IPHONE_11_0
    if (respondsToAdjustedContentInset_) {
        return self.adjustedContentInset;
    }
#endif
    return self.contentInset;
}

- (void)setNcmj_insetT:(CGFloat)mj_insetT {
    UIEdgeInsets inset = self.contentInset;
    inset.top = mj_insetT;
#ifdef __IPHONE_11_0
    if (respondsToAdjustedContentInset_) {
        inset.top -= (self.adjustedContentInset.top - self.contentInset.top);
    }
#endif
    self.contentInset = inset;
}

- (CGFloat)ncmj_insetT {
    return self.ncmj_inset.top;
}

- (void)setNcmj_insetB:(CGFloat)mj_insetB {
    UIEdgeInsets inset = self.contentInset;
    inset.bottom = mj_insetB;
#ifdef __IPHONE_11_0
    if (respondsToAdjustedContentInset_) {
        inset.bottom -= (self.adjustedContentInset.bottom - self.contentInset.bottom);
    }
#endif
    self.contentInset = inset;
}

- (CGFloat)ncmj_insetB {
    return self.ncmj_inset.bottom;
}

- (void)setNcmj_insetL:(CGFloat)mj_insetL {
    UIEdgeInsets inset = self.contentInset;
    inset.left = mj_insetL;
#ifdef __IPHONE_11_0
    if (respondsToAdjustedContentInset_) {
        inset.left -= (self.adjustedContentInset.left - self.contentInset.left);
    }
#endif
    self.contentInset = inset;
}

- (CGFloat)ncmj_insetL {
    return self.ncmj_inset.left;
}

- (void)setNcmj_insetR:(CGFloat)mj_insetR {
    UIEdgeInsets inset = self.contentInset;
    inset.right = mj_insetR;
#ifdef __IPHONE_11_0
    if (respondsToAdjustedContentInset_) {
        inset.right -= (self.adjustedContentInset.right - self.contentInset.right);
    }
#endif
    self.contentInset = inset;
}

- (CGFloat)ncmj_insetR {
    return self.ncmj_inset.right;
}

- (void)setNcmj_offsetX:(CGFloat)mj_offsetX {
    CGPoint offset = self.contentOffset;
    offset.x = mj_offsetX;
    self.contentOffset = offset;
}

- (CGFloat)ncmj_offsetX {
    return self.contentOffset.x;
}

- (void)setNcmj_offsetY:(CGFloat)mj_offsetY {
    CGPoint offset = self.contentOffset;
    offset.y = mj_offsetY;
    self.contentOffset = offset;
}

- (CGFloat)ncmj_offsetY {
    return self.contentOffset.y;
}

- (void)setNcmj_contentW:(CGFloat)mj_contentW {
    CGSize size = self.contentSize;
    size.width = mj_contentW;
    self.contentSize = size;
}

- (CGFloat)ncmj_contentW {
    return self.contentSize.width;
}

- (void)setNcmj_contentH:(CGFloat)mj_contentH {
    CGSize size = self.contentSize;
    size.height = mj_contentH;
    self.contentSize = size;
}

- (CGFloat)ncmj_contentH {
    return self.contentSize.height;
}
@end
#pragma clang diagnostic pop
