//
//  NCPluginBoardView.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPluginBoardView.h"
#import "NCPageControl.h"
#import "NCChatUICommonDefine.h"
#import "NCPluginBoardHorizontalCollectionViewLayout.h"
#import "NCPluginBoardItem.h"
#import "UIImage+NCDynamicImage.h"
#import "NCChatUIConfig.h"
#define NCPluginBoardCell @"NCPluginBoardCell"

@interface NCPluginBoardView () <UICollectionViewDataSource, UICollectionViewDelegate> {
    NCPageControl *_pageCtrl;
    CGFloat _lastWidth;
    NSInteger _currentIndex;
}
@property (strong, nonatomic) NCPluginBoardHorizontalCollectionViewLayout *layout;
@end

@implementation NCPluginBoardView
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self.layout = [NCPluginBoardHorizontalCollectionViewLayout new];
    self = [super initWithFrame:frame];
    if (self) {
        _currentIndex = 0;
        CGRect contentViewFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        self.contentView = [[NCBaseCollectionView alloc] initWithFrame:contentViewFrame collectionViewLayout:self.layout];
        self.contentView.dataSource = self;
        self.contentView.delegate = self;
        self.contentView.pagingEnabled = YES;
        self.allItems = [@[] mutableCopy];
        self.contentView.scrollEnabled = YES;
        [self addSubview:self.contentView];
        self.extensionView = [[UIView alloc] initWithFrame:contentViewFrame];
        [self.extensionView setHidden:YES];
        self.extensionView.backgroundColor = NCDynamicColor(@"common_background_color");
        [self addSubview:self.extensionView];
        [self.contentView setShowsHorizontalScrollIndicator:NO];
        [self.contentView setShowsVerticalScrollIndicator:NO];
        [self.contentView setBackgroundColor:NCDynamicColor(@"common_background_color")];
        [self.contentView registerClass:[NCPluginBoardItem class] forCellWithReuseIdentifier:NCPluginBoardCell];
        if ([NCChatUIUtility isRTL]) {
            [self.contentView setTransform:CGAffineTransformMakeScale(-1, 1)];
        }

    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self fitDarkMode];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (_lastWidth != self.bounds.size.width) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contentView.frame = self.bounds;
            [_contentView reloadData];
            [self scrollToCurrentIndexIfNeeded];
        });
    }
    _lastWidth = self.bounds.size.width;
}

- (void)scrollToCurrentIndexIfNeeded {
    if (_currentIndex >= _allItems.count) {
        return;
    }
    BOOL needScroll = _currentIndex == 1 || [NCChatUIUtility isRTL];
    if (!needScroll) {
        return;
    }
    [_contentView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:_currentIndex]
                         atScrollPosition:[NCChatUIUtility isRTL] ? UICollectionViewScrollPositionRight : UICollectionViewScrollPositionLeft
                                 animated:[NCChatUIUtility isRTL] ? NO : YES];
    _pageCtrl.currentPage = _currentIndex;
}

#pragma mark - Public Methods
- (void)insertItem:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title atIndex:(NSInteger)index tag:(NSInteger)tag{
    NCPluginBoardItem *__item = [[NCPluginBoardItem alloc] initWithTitle:title normalImage:normalImage highlightedImage:highlightedImage tag:tag];
    [self insertItem:__item atIndex:index];
}

- (void)insertItem:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title tag:(NSInteger)tag{
    [self insertItem:normalImage highlightedImage:highlightedImage title:title atIndex:self.allItems.count tag:tag];
}

- (void)updateItemAtIndex:(NSInteger)index normalImage:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title{
    if (index >= 0 && index < self.allItems.count) {
        NCPluginBoardItem *item = self.allItems[index];
        if (normalImage) {
            item.normalImage = normalImage;
        }
        if (highlightedImage) {
            item.highlightedImage = highlightedImage;
        }
        if (title) {
            item.title = title;
        }
        [self.contentView reloadData];
    }
}

- (void)updateItemWithTag:(NSInteger)tag normalImage:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title{
    for (int i = 0; i < self.allItems.count; i++) {
        NCPluginBoardItem *item = _allItems[i];
        if (item.tag == tag) {
            if (normalImage) {
                item.normalImage = normalImage;
            }
            if (highlightedImage) {
                item.highlightedImage = highlightedImage;
            }
            if (title) {
                item.title = title;
            }
            [self.contentView reloadData];
        }
    }
}

- (void)removeItemWithTag:(NSInteger)tag {
    for (int i = 0; i < _allItems.count; i++) {
        NCPluginBoardItem *item = _allItems[i];
        if (item.tag == tag) {
            [_allItems removeObjectAtIndex:i];
            [self.contentView reloadData];
        }
    }
}

- (void)removeItemAtIndex:(NSInteger)index {
    if (_allItems) {
        NSInteger _count = [_allItems count];

        if (index >= _count) {
            return;
        }

        [_allItems removeObjectAtIndex:index];
        [self.contentView reloadData];
    }
}

- (void)removeAllItems {
    [self.allItems removeAllObjects];
    [self.contentView reloadData];
}

#pragma mark - UICollectionViewDataSource
// Returns the number of collection-view cells to display.
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ((section + 1) * self.layout.itemsPerSection >= self.allItems.count) {
        return self.allItems.count - section * self.layout.itemsPerSection;
    } else {
        return self.layout.itemsPerSection;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSInteger sectionNumber = (NSInteger)ceilf((double)self.allItems.count / self.layout.itemsPerSection);
    [self setPageTips:sectionNumber];
    return sectionNumber;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = NCPluginBoardCell;
    NCPluginBoardItem *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }
    NCPluginBoardItem *item = _allItems[indexPath.row + indexPath.section * self.layout.itemsPerSection];
    cell.title = item.title;
    cell.normalImage = item.normalImage;
    cell.highlightedImage = item.highlightedImage;
    __weak typeof(self) weakSelf = self;
    [cell setItemclick:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.pluginBoardDelegate &&
            [strongSelf.pluginBoardDelegate respondsToSelector:@selector(pluginBoardView:clickedItemWithTag:)]) {
            NCPluginBoardItem *item =
            strongSelf.allItems[indexPath.row + indexPath.section * strongSelf.layout.itemsPerSection];
            [strongSelf.pluginBoardDelegate pluginBoardView:strongSelf clickedItemWithTag:item.tag];
        }
    }];
    cell.tag = item.tag;
    [cell loadView];
    if ([NCChatUIUtility isRTL]) {
        [cell setTransform:CGAffineTransformMakeScale(-1, 1)];
    }
    return cell;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.frame;
    int currentIndex = offset.x / bounds.size.width;
    _currentIndex = currentIndex;
    [_pageCtrl setCurrentPage:currentIndex];
}

#pragma mark - Dark Mode
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self fitDarkMode];
}

- (void)fitDarkMode {
    if (!NCChatUIConfigCenter.ui.enableDarkMode) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        for (NCPluginBoardItem *item in self.allItems) {
            if (item.normalImage.nc_imageLocalPath) {
                item.normalImage = [UIImage nc_imageWithLocalPath:item.normalImage.nc_imageLocalPath];
            }
            if (item.highlightedImage.nc_imageLocalPath) {
                item.highlightedImage = [UIImage nc_imageWithLocalPath:item.highlightedImage.nc_imageLocalPath];
            }
        }
        [self.contentView reloadData];
    }
}

#pragma mark - Private Methods
- (void)setPageTips:(NSInteger)pages {
    if (_pageCtrl) {
        [_pageCtrl removeFromSuperview];
        _pageCtrl = nil;
    }
    _pageCtrl = [[NCPageControl alloc]
        initWithFrame:CGRectMake(0, self.bounds.size.height - 25, self.bounds.size.width, 8)];
    _pageCtrl.currentPage = _currentIndex;
    _pageCtrl.numberOfPages = pages; // Total pages
    [self addSubview:_pageCtrl];
    [self bringSubviewToFront:self.extensionView];
}

- (void)insertItem:(NCPluginBoardItem *)item atIndex:(NSInteger)index {
    if (item) {
        if (index > self.allItems.count) {
            index = self.allItems.count;
        }
        [_allItems insertObject:item atIndex:index];
    }
    [self.contentView reloadData];
}

- (float)getBoardViewBottonOriginY {
    float gap = (NC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) ? 64 : 0;
    return [UIScreen mainScreen].bounds.size.height - gap;
}

// Moves the board on or off screen for the visibility transition.
- (void)setHidden:(BOOL)hidden {
    CGRect viewRect = self.frame;
    if (hidden) {
        viewRect.origin.y = [self getBoardViewBottonOriginY];
    } else {
        viewRect.origin.y = [self getBoardViewBottonOriginY] - self.frame.size.height;
    }
    [self setFrame:viewRect];
    [super setHidden:hidden];
}
@end
