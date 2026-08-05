//  Source: https://github.com/CoderMJLee/MJRefresh
//  Additional reference:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  UIScrollView+NCMJRefresh.m
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "UIScrollView+NCMJRefresh.h"
#import "NCMJRefreshFooter.h"
#import <objc/runtime.h>

static const char NCMJRefreshFooterKey = '\0';

@implementation UIScrollView (NCMJRefresh)

#pragma mark - footer
- (void)setNcmj_footer:(NCMJRefreshFooter *)mj_footer {
    if (mj_footer != self.ncmj_footer) {
        // Remove the previous footer and add the replacement.
        [self.ncmj_footer removeFromSuperview];
        [self insertSubview:mj_footer atIndex:0];

        // Retain the new footer through the associated object.
        objc_setAssociatedObject(self, &NCMJRefreshFooterKey, mj_footer, OBJC_ASSOCIATION_RETAIN);
    }
}

- (NCMJRefreshFooter *)ncmj_footer {
    return objc_getAssociatedObject(self, &NCMJRefreshFooterKey);
}

#pragma mark - Deprecated
- (void)setNcfooter:(NCMJRefreshFooter *)footer {
    self.ncmj_footer = footer;
}

- (NCMJRefreshFooter *)ncfooter {
    return self.ncmj_footer;
}

#pragma mark - other
- (NSInteger)ncmj_totalDataCount {
    NSInteger totalCount = 0;
    if ([self isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)self;

        for (NSInteger section = 0; section < tableView.numberOfSections; section++) {
            totalCount += [tableView numberOfRowsInSection:section];
        }
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self;

        for (NSInteger section = 0; section < collectionView.numberOfSections; section++) {
            totalCount += [collectionView numberOfItemsInSection:section];
        }
    }
    return totalCount;
}

@end
