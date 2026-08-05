//
//  NCEmoticonPackage.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCEmoticonPackage.h"
#import "NCEmojiBoardView+internal.h"
@interface NCEmoticonPackage () <UIScrollViewDelegate> {
    NSInteger viewTag;
}
@property (nonatomic, strong) NSMutableDictionary *loadedEmoticonPage;

@end

@implementation NCEmoticonPackage
#pragma mark - UIScrollViewDelegate
// Updates the selected page after deceleration ends.
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.frame;
    int currentIndex = offset.x / bounds.size.width;
    int totalPages = scrollView.contentSize.width / bounds.size.width;

    [self.emojBoardView setCurrentIndex:currentIndex withTotalPages:totalPages];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if (self.tabSource) {
        CGPoint offset = scrollView.contentOffset;
        CGRect bounds = scrollView.frame;
        int currentIndex = offset.x / bounds.size.width;
        NSString *pageKey = [NSString stringWithFormat:@"page%d", (currentIndex + 1)];
        if (![_loadedEmoticonPage.allKeys containsObject:pageKey]) {
            UIView *currentView = [_loadedEmoticonPage objectForKey:pageKey];
            if (currentView) {
                [currentView removeFromSuperview];
            }
            currentView = [self.tabSource loadEmoticonView:self.identify index:currentIndex + 1];
            currentView.tag = viewTag;
            viewTag++;
            [_loadedEmoticonPage setObject:currentView forKey:pageKey];
            [currentView setFrame:CGRectMake(self.emojBoardView.frame.size.width * (currentIndex + 1), 0,
                                             self.emojBoardView.frame.size.width, 186)];
            [self.emotionContainerView addSubview:currentView];
        }
        if (currentIndex >= 0) {
            NSString *prePageKey = [NSString stringWithFormat:@"page%d", (currentIndex)];
            if (![_loadedEmoticonPage.allKeys containsObject:prePageKey]) {
                UIView *currentView = [_loadedEmoticonPage objectForKey:pageKey];
                if (currentView) {
                    [currentView removeFromSuperview];
                }
                currentView = [self.tabSource loadEmoticonView:self.identify index:currentIndex];
                currentView.tag = viewTag;
                viewTag++;
                [_loadedEmoticonPage setObject:currentView forKey:pageKey];
                [currentView setFrame:CGRectMake(self.emojBoardView.frame.size.width * (currentIndex), 0,
                                                 self.emojBoardView.frame.size.width, 186)];
                [self.emotionContainerView addSubview:currentView];
            }
        }
    }
}

#pragma mark - Public Methods
- (id)initEmoticonPackage:(UIImage *)tabImage withTotalCount:(int)pageCount {
    self = [super init];
    if (self) {
        self.totalPage = pageCount;
        self.tabImage = tabImage;
        viewTag = 8800;
    }
    return self;
}

- (void)showEmoticonView:(int)index {
    if (self.tabSource) {
        NSString *pageKey = [NSString stringWithFormat:@"page%d", (index)];
        if (![_loadedEmoticonPage.allKeys containsObject:pageKey]) {
            UIView *currentView = [_loadedEmoticonPage objectForKey:pageKey];
            if (currentView) {
                [currentView removeFromSuperview];
            }
            currentView = [self.tabSource loadEmoticonView:self.identify index:index];
            currentView.tag = viewTag;
            viewTag++;
            [_loadedEmoticonPage setObject:currentView forKey:pageKey];
            [currentView setFrame:CGRectMake(self.emojBoardView.frame.size.width * (index), 0,
                                             self.emojBoardView.frame.size.width, 186)];
            [self.emotionContainerView addSubview:currentView];
        }
        CGSize viewSize = self.emotionContainerView.frame.size;
        CGRect rect = CGRectMake(index * viewSize.width, 0, viewSize.width, viewSize.height);
        [self.emotionContainerView scrollRectToVisible:rect animated:NO];
        [self.emojBoardView setCurrentIndex:index withTotalPages:self.totalPage];
    }
}

- (void)setNeedLayout {
    self.emotionContainerView.contentSize = CGSizeMake(self.emojBoardView.frame.size.width * self.totalPage, 186);
    // Update child frames after the package position changes.
    for (UIView *aView in self.emotionContainerView.subviews) {
        if (aView.tag >= 8800) {
            aView.frame = CGRectMake(self.emojBoardView.frame.size.width * (aView.tag - 8800), 0,
                                     self.emojBoardView.frame.size.width, 186);
        }
    }
}

#pragma mark - Getters and Setters
- (NCBaseScrollView *)emotionContainerView {
    if (!_emotionContainerView) {
        _emotionContainerView =
            [[NCBaseScrollView alloc] initWithFrame:CGRectMake(0, 0, self.emojBoardView.frame.size.width, 186)];
        _loadedEmoticonPage = [NSMutableDictionary new];
        _emotionContainerView.pagingEnabled = YES;
        _emotionContainerView.showsHorizontalScrollIndicator = NO;
        _emotionContainerView.showsVerticalScrollIndicator = NO;
        _emotionContainerView.delegate = self;
        _emotionContainerView.contentSize = CGSizeMake(self.emojBoardView.frame.size.width * self.totalPage, 186);
    }
    return _emotionContainerView;
}
@end
