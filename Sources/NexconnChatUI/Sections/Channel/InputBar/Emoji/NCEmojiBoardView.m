//
//  NCEmojiBoardView.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCEmojiBoardView.h"
#import "NCPageControl.h"
#import "NCEmoticonPackage.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIExtensionService.h"
#import "NCChatUIConfig.h"
#import "NCEmojiTabView.h"
#import "NCBaseButton.h"
#import "NCBaseScrollView.h"
#define NC_EMOJI_WIDTH 30
#define NC_EMOTIONTAB_SIZE_HEIGHT 42
#define NC_EMOTIONTAB_SIZE_WIDTH 42
#define NC_EMOTIONTAB_ICON_SIZE 25
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

NSString *const NCUIExtensionEmoticonTabNeedReloadNotification = @"NCUIExtensionEmoticonTabNeedReloadNotification";
@interface NCEmojiBoardView ()<NCEmojiTabViewDelegate> {
    BOOL _disableDefaultEmoji;
}
@property (nonatomic, assign) int emojiTotal;
@property (nonatomic, assign) int emojiTotalPage;
@property (nonatomic, assign) int emojiColumn;
@property (nonatomic, assign) int emojiMaxCountPerPage;
@property (nonatomic, assign) CGFloat emojiMariginHorizontalMin;
@property (nonatomic, strong) NSArray *faceEmojiArray;
@property (nonatomic, assign) int emojiLoadedPage;
@property (nonatomic, strong) NCEmojiTabView *tabbarView;
@property (nonatomic, assign) CGSize emojiContentSize; // Content size of the built-in emoji pages
@property (nonatomic, assign) int preSelectEmoticonPackageIndex;

/*!
 Custom emoticon package models.
 */
@property (nonatomic, strong) NSMutableArray *emojiModelList;

/*!
 Custom emoticon package models added by the app through addEmojiTab.
 */
@property (nonatomic, strong) NSMutableArray *appAddEmojiModelList;
// Disables the built-in emoji package.
@property (nonatomic, assign, readwrite) BOOL disableDefaultEmoji;

@end

static int nc_currentSelectIndexPackage;
static int nc_currentSelectIndexPage;
@implementation NCEmojiBoardView {
    /*!
     PageControl
     */
    NCPageControl *pageCtrl;

    /*!
     Index of the current page.
     */
    //  NSInteger currentIndex;

    CGFloat lastFrameWith;
}
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame delegate:(id<NCEmojiViewDelegate>)delegate {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        nc_currentSelectIndexPage = 0;

        NSString *bundlePath = [NCChatUIUtility filePathForName:@"Emoji.plist"];
        NCLogD(@"Emoji.plist > %@", bundlePath);
        self.faceEmojiArray = [[NSArray alloc] initWithContentsOfFile:bundlePath];
        self.emojiLoadedPage = 0;

        [self generateDefaultLayoutParameters];
        lastFrameWith = self.frame.size.width;
        self.emojiBackgroundView = [[NCBaseScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 186)];
        self.emojiBackgroundView.backgroundColor = NCDynamicColor(@"common_background_color");
        self.emojiBackgroundView.pagingEnabled = YES;
        self.emojiBackgroundView.contentSize = CGSizeMake(self.emojiTotalPage * self.frame.size.width, 186);
        self.emojiBackgroundView.showsHorizontalScrollIndicator = NO;
        self.emojiBackgroundView.showsVerticalScrollIndicator = NO;
        self.emojiBackgroundView.delegate = self;
        if ([NCChatUIUtility isRTL]) {
            [self.emojiBackgroundView setTransform:CGAffineTransformMakeScale(-1, 1)];
        }
        self.delegate = delegate;
        [self addSubview:self.emojiBackgroundView];
        [self loadLabelView];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(needReloadEmoticonTabSource:)
                                                 name:NCUIExtensionEmoticonTabNeedReloadNotification
                                               object:nil];
    return self;
}

- (void)dealloc {
    nc_currentSelectIndexPackage = 0;
    nc_currentSelectIndexPage = 0;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Super Methods

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (fabs(frame.size.width - lastFrameWith) >= 4) {
        lastFrameWith = frame.size.width;
    } else {
        return; // Avoid redundant layout refreshes.
    }
    // Resize the tab bar to match the new board width.
    if (_tabbarView) {
        CGRect tabbarViewFrame = _tabbarView.frame;
        tabbarViewFrame.size.width = frame.size.width;
        self.tabbarView.frame = tabbarViewFrame;
    }
    
    [self generateDefaultLayoutParameters];
    // Recalculate page metrics and rebuild content for the new width.
    for (UIView *subView in self.emojiBackgroundView.subviews) {
        // Remove generated controls from the previous built-in emoji pages.
        if (![subView isKindOfClass:[UIScrollView class]]) {
            [subView removeFromSuperview];
        }
    }

    self.emojiLoadedPage = 0;
    [self.emojiBackgroundView setContentOffset:CGPointMake(0, 0) animated:YES];
    // The selected tab reload below recreates the required page content.
    //[self loadEmojiViewPartly];
    self.emojiContentSize = CGSizeMake(self.emojiTotalPage * self.frame.size.width, 186);

    for (NSInteger i = 0; i < _emojiModelList.count; i++) {
        NCEmoticonPackage *model = _emojiModelList[i];
        int offsetX = self.frame.size.width * i;
        CGRect frame = CGRectMake(self.emojiContentSize.width + offsetX, 0, self.frame.size.width,
                                  self.emojiBackgroundView.contentSize.height);
        model.emotionContainerView.frame = frame;
        [model setNeedLayout];
    }
    CGSize size = self.emojiContentSize;
    size.width = self.emojiContentSize.width + self.frame.size.width * _emojiModelList.count;
    self.emojiBackgroundView.contentSize = size;
    [self loadEmotionTab:nc_currentSelectIndexPackage];
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

#pragma mark - Public Methods
- (void)disableSystemDefaultEmoji {
    self.disableDefaultEmoji = YES;
}

- (void)loadLabelView {
    if (!self.disableDefaultEmoji) {
        [self loadEmojiViewPartly];
    }
    if (pageCtrl) {
        [pageCtrl removeFromSuperview];
        pageCtrl = nil;
    }
    pageCtrl = [[NCPageControl alloc] initWithFrame:CGRectMake(0, 175, self.frame.size.width, 5)];
    pageCtrl.numberOfPages = self.emojiTotalPage; // Total built-in emoji pages
    pageCtrl.currentPage = 0;                     // Current page
    [pageCtrl addTarget:self action:@selector(pageTurn:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:pageCtrl];
    [self addSubview:self.tabbarView];
    BOOL isAddButtonEnabled = NO;
    BOOL isSettingButtonEnabled = NO;
    if ([self.delegate isKindOfClass:[NCChatSessionInputBarControl class]]) {
        NCChatSessionInputBarControl *inputBarControl = (NCChatSessionInputBarControl *)self.delegate;
        isAddButtonEnabled = [[NCChatUIExtensionService sharedService] isEmoticonAddButtonEnabled:inputBarControl];
        isSettingButtonEnabled = [[NCChatUIExtensionService sharedService] isEmoticonSettingButtonEnabled:inputBarControl];
    }
    [self.tabbarView showAddButton:isAddButtonEnabled showSettingButton:isSettingButtonEnabled];
    [self loadCustomerEmoticonPackage];
}

- (void)enableSendButton:(BOOL)enableSend {
    UIButton *sendButton = (UIButton *)[self viewWithTag:333];
    if (enableSend) {
        sendButton.userInteractionEnabled = YES;
        sendButton.backgroundColor = NCDynamicColor(@"primary_color");
        [sendButton setTitleColor:NCDynamicColor(@"control_title_white_color") forState:UIControlStateNormal];
    } else {
        sendButton.userInteractionEnabled = NO;
        sendButton.backgroundColor = NCDynamicColor(@"disabled_color");
        [sendButton setTitleColor:NCDynamicColor(@"text_secondary_color") forState:UIControlStateNormal];
    }
}

- (void)addEmojiTab:(id<NCEmoticonTabSource>)viewDataSource {
    NCEmoticonPackage *model = [[NCEmoticonPackage alloc] initEmoticonPackage:[viewDataSource image]
                                                               withTotalCount:[viewDataSource pageCount]];
    model.tabSource = viewDataSource;
    model.identify = [viewDataSource identify];
    model.emojBoardView = self;
    if (!_emojiModelList) {
        _emojiModelList = [NSMutableArray new];
    }
    if (!_appAddEmojiModelList) {
        _appAddEmojiModelList = [NSMutableArray new];
    }
    [_appAddEmojiModelList addObject:model];
    [_emojiModelList addObject:model];
    [self loadCustomerEmoticonPackage];
}

- (void)addExtensionEmojiTab:(id<NCEmoticonTabSource>)viewDataSource {
    NCEmoticonPackage *model = [[NCEmoticonPackage alloc] initEmoticonPackage:[viewDataSource image]
                                                               withTotalCount:[viewDataSource pageCount]];
    model.tabSource = viewDataSource;
    model.identify = [viewDataSource identify];
    model.emojBoardView = self;
    if (!_emojiModelList) {
        _emojiModelList = [NSMutableArray new];
    }
    [_emojiModelList addObject:model];
    [self loadCustomerEmoticonPackage];
}

- (void)setCurrentIndex:(int)index withTotalPages:(int)totalPageNum {
    pageCtrl.numberOfPages = totalPageNum;
    nc_currentSelectIndexPage = index;
    [pageCtrl setCurrentPage:index];
}

- (void)reloadExtensionEmoticonTabSource {
    NSString *identify = nil;
    if (nc_currentSelectIndexPackage < _emojiModelList.count) {
        NCEmoticonPackage *model = _emojiModelList[nc_currentSelectIndexPackage];
        identify = model.identify;
    } else {
        nc_currentSelectIndexPackage = 0;
        nc_currentSelectIndexPage = 0;
    }

    if (_emojiModelList && _emojiModelList.count > 0) {
        [_emojiModelList removeAllObjects];
    }
    if (self.emojiBackgroundView) {
        [self.emojiBackgroundView removeFromSuperview];
        self.emojiBackgroundView = nil;
    }
    self.emojiBackgroundView = [[NCBaseScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 186)];
    if ([NCChatUIUtility isRTL]) {
        [self.emojiBackgroundView setTransform:CGAffineTransformMakeScale(-1, 1)];
    }
    self.emojiBackgroundView.backgroundColor = NCDynamicColor(@"common_background_color");
    self.emojiBackgroundView.pagingEnabled = YES;
    self.emojiBackgroundView.contentSize = CGSizeMake(self.emojiTotalPage * self.frame.size.width, 186);
    self.emojiBackgroundView.showsHorizontalScrollIndicator = NO;
    self.emojiBackgroundView.showsVerticalScrollIndicator = NO;
    self.emojiBackgroundView.delegate = self;
    [self addSubview:self.emojiBackgroundView];
    self.emojiLoadedPage = 0;
    [self loadLabelView];
    for (int i = 0; i < _appAddEmojiModelList.count; i++) {
        [_emojiModelList addObject:_appAddEmojiModelList[i]];
    }
    NSArray<id<NCEmoticonTabSource>> *emoticonTabSourceList =
        [[NCChatUIExtensionService sharedService] getEmoticonTabList:self.channelType channelId:self.channelId];
    for (id<NCEmoticonTabSource> source in emoticonTabSourceList) {
        NCEmoticonPackage *model =
            [[NCEmoticonPackage alloc] initEmoticonPackage:[source image] withTotalCount:[source pageCount]];
        model.tabSource = source;
        model.identify = [source identify];
        model.emojBoardView = self;
        [_emojiModelList addObject:model];
    };
    if (identify) {
        BOOL hasFoundPackage = NO;
        for (int i = 0; i < _emojiModelList.count; i++) {
            NCEmoticonPackage *model = _emojiModelList[i];
            if ([model.identify isEqualToString:identify]) {
                hasFoundPackage = YES;
                nc_currentSelectIndexPackage = i;
                [self showEmoticonPackage:i];
                CGSize viewSize = self.emojiBackgroundView.frame.size;
                CGRect rect =
                    CGRectMake(nc_currentSelectIndexPage * viewSize.width, 0, viewSize.width, viewSize.height);
                [model.emotionContainerView scrollRectToVisible:rect animated:NO];
                break;
            }
        }
        if (!hasFoundPackage) {
            nc_currentSelectIndexPage = 0;
            nc_currentSelectIndexPackage = 0;
        }
    } else {
        nc_currentSelectIndexPackage = (int)(_emojiModelList.count);
        [self showEmoticonPackage:nc_currentSelectIndexPackage];
    }
    [self loadCustomerEmoticonPackage];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self loadEmojiViewPartly];
}

// Updates selection after deceleration ends.
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // Update UIPageControl to the visible page.
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.frame;
    int currentIndex = offset.x / bounds.size.width;
    int selectIndex = currentIndex;
    if (currentIndex >= self.emojiTotalPage) {
        int emotionPackageIndex = currentIndex - self.emojiTotalPage;
        if (emotionPackageIndex >= self.emojiModelList.count) {
            return;
        }
        NCEmoticonPackage *model = self.emojiModelList[emotionPackageIndex];
        selectIndex = 0;
        if (model.tabSource) {
            if (_preSelectEmoticonPackageIndex > emotionPackageIndex) {
                selectIndex = model.totalPage - 1;
                if (selectIndex < 0) {
                    selectIndex = 0;
                }
                [model showEmoticonView:selectIndex];
            } else {
                [model showEmoticonView:0];
            }
        }
        pageCtrl.numberOfPages = model.totalPage;
        if (self.disableDefaultEmoji) {
            nc_currentSelectIndexPackage = emotionPackageIndex; // Selected emoticon package
        } else {
            nc_currentSelectIndexPackage = emotionPackageIndex + 1; // Selected emoticon package
        }
        nc_currentSelectIndexPage = 0;
    } else {
        pageCtrl.numberOfPages = self.emojiTotalPage;
        nc_currentSelectIndexPackage = 0;
        nc_currentSelectIndexPage = currentIndex;
        if (self.emojiLoadedPage <= currentIndex) {
            [self showEmoticonView:currentIndex];
        }
    }
    [self.tabbarView showEmotion:nc_currentSelectIndexPackage];
    _preSelectEmoticonPackageIndex = nc_currentSelectIndexPackage;
    [pageCtrl setCurrentPage:selectIndex];
    NCLogD(@"%d/%d", nc_currentSelectIndexPage, nc_currentSelectIndexPackage);
}

#pragma mark - NCEmojiTabViewDelegate

- (void)emojiTabView:(NCEmojiTabView *)emojiTabView didClickSendButton:(UIButton *)button{
    if ([self.delegate respondsToSelector:@selector(didSendButtonEvent:sendButton:)]) {
        [self.delegate didSendButtonEvent:self sendButton:button];
    }
}

- (void)emojiTabView:(NCEmojiTabView *)emojiTabView didClickSettingButton:(UIButton *)button{
    if ([self.delegate isKindOfClass:[NCChatSessionInputBarControl class]]) {
        [[NCChatUIExtensionService sharedService] emoticonTab:self
                                  didTouchSettingButton:button
                                             inInputBar:(NCChatSessionInputBarControl *)self.delegate];
    } else {
        [[NCChatUIExtensionService sharedService] emoticonTab:self didTouchSettingButton:button inInputBar:nil];
    }
}

- (void)emojiTabView:(NCEmojiTabView *)emojiTabView didClickAddButton:(UIButton *)button{
    if ([self.delegate isKindOfClass:[NCChatSessionInputBarControl class]]) {
        [[NCChatUIExtensionService sharedService] emoticonTab:self
                                      didTouchAddButton:button
                                             inInputBar:(NCChatSessionInputBarControl *)self.delegate];
    } else {
        [[NCChatUIExtensionService sharedService] emoticonTab:self didTouchAddButton:button inInputBar:nil];
    }
}

- (void)emojiTabView:(NCEmojiTabView *)emojiTabView didSelectEmotion:(int)index{
    _preSelectEmoticonPackageIndex = index;
    nc_currentSelectIndexPage = 0;
    [self loadEmotionTab:index];
}

#pragma mark - Private Methods
- (void)loadEmotionTab:(int)index {
    if ([self.delegate isKindOfClass:[NCChatSessionInputBarControl class]]) {
        [[NCChatUIExtensionService sharedService] emoticonTab:self
                               didTouchEmotionIconIndex:index
                                             inInputBar:(NCChatSessionInputBarControl *)self.delegate
                                    isBlockDefaultEvent:^(BOOL isBlockDefaultEvent) {
                                        if (!isBlockDefaultEvent) {
                                            [self showEmoticonPackage:index];
                                        }
                                    }];
    } else {
        [self showEmoticonPackage:index];
    }
}

// Lazily loads built-in emoji pages.
- (void)loadEmojiViewPartly {
    if (self.disableDefaultEmoji) {
        return;
    }
    // Preload two pages to support rapid swiping.
    int beginEmojiBtn = self.emojiLoadedPage * self.emojiMaxCountPerPage;
    int endEmojiBtn = MIN(self.emojiTotal, (self.emojiLoadedPage + 2) * self.emojiMaxCountPerPage);
    float startPos_X = 0, startPos_Y = 26.5;
    startPos_X = self.emojiMariginHorizontalMin + 6;
    for (int i = beginEmojiBtn; i < endEmojiBtn; i++) {
        int pageIndex = i / self.emojiMaxCountPerPage;
        float emojiPosX =
            startPos_X + 42 * (i % self.emojiMaxCountPerPage % self.emojiColumn) + pageIndex * self.frame.size.width;
        float emojiPosY = startPos_Y + 47 * (i % self.emojiMaxCountPerPage / self.emojiColumn);
        NCBaseButton *emojiBtn =
            [[NCBaseButton alloc] initWithFrame:CGRectMake(emojiPosX, emojiPosY, NC_EMOJI_WIDTH, NC_EMOJI_WIDTH)];
        emojiBtn.titleLabel.font = [[NCChatUIConfig defaultConfig].font fontOfSize:26];
        [emojiBtn setTitle:self.faceEmojiArray[i] forState:UIControlStateNormal];
        [emojiBtn addTarget:self action:@selector(emojiBtnHandle:) forControlEvents:UIControlEventTouchUpInside];
        if ([NCChatUIUtility isRTL]) {
            [emojiBtn setTransform:CGAffineTransformMakeScale(-1, 1)];
        }
        [self.emojiBackgroundView addSubview:emojiBtn];
        if (((i + 1) >= self.emojiMaxCountPerPage && (i + 1) % self.emojiMaxCountPerPage == 0) ||
            i == self.emojiTotal - 1) {
            CGRect frame = emojiBtn.frame;
            NCBaseButton *deleteButton = [NCBaseButton buttonWithType:UIButtonTypeCustom];
            [deleteButton addTarget:self
                             action:@selector(emojiBtnHandle:)
                   forControlEvents:UIControlEventTouchUpInside];
            int offset = 30;
            frame.origin.x = self.frame.size.width - startPos_X - offset + pageIndex * self.frame.size.width;
            frame.size = CGSizeMake(NC_EMOJI_WIDTH, NC_EMOJI_WIDTH);
            deleteButton.frame = frame;
            [deleteButton setImage:NCDynamicImage(@"channel_msg_cell_emoji_delete_img") forState:UIControlStateNormal];
            deleteButton.contentEdgeInsets = UIEdgeInsetsMake(3, 0, 0, 0);
            [self.emojiBackgroundView addSubview:deleteButton];
        }
        if (self.emojiLoadedPage < pageIndex + 1) {
            self.emojiLoadedPage = pageIndex + 1;
        }
    }
    self.emojiContentSize = self.emojiBackgroundView.contentSize;
}

- (void)generateDefaultLayoutParameters {
    CGFloat emojiSpanHorizontal = 42;
    int emojiRow = 3;
    self.emojiMariginHorizontalMin = 6;
    if (nil == self.faceEmojiArray || [self.faceEmojiArray count] == 0) {
        self.emojiTotal = 0;
    } else {
        self.emojiTotal = (int)[self.faceEmojiArray count];
    }
    self.emojiColumn = (int)(self.frame.size.width / emojiSpanHorizontal); // Columns that fit the current width
    int left = ((int)self.frame.size.width) % 42;
    if (left < 12) {
        self.emojiColumn--;
        left = left + emojiSpanHorizontal;
    }
    self.emojiMaxCountPerPage = self.emojiColumn * emojiRow - 1;
    self.emojiMariginHorizontalMin = left / 2;
    self.emojiTotalPage =
        self.emojiTotal / self.emojiMaxCountPerPage + (self.emojiTotal % self.emojiMaxCountPerPage ? 1 : 0);
}

- (void)loadCustomerEmoticonPackage {
    NSMutableArray *emojiList = [NSMutableArray array];
    if(!self.disableDefaultEmoji) {
        UIImage *img = NCDynamicImage(@"emoji_tab_face_img");
        if (img) {
            [emojiList addObject:img];
        }
    }
    for (int i = 0; i < _emojiModelList.count; i++) {
        NCEmoticonPackage *model = _emojiModelList[i];
        int offsetX = self.frame.size.width * i;
        CGRect frame = CGRectMake(self.emojiContentSize.width + offsetX, 0, self.frame.size.width,
                                  self.emojiBackgroundView.contentSize.height);
        [model.emotionContainerView setFrame:frame];
        // Tag the view so it can be removed or laid out again later.
        [self.emojiBackgroundView addSubview:model.emotionContainerView];
        CGSize size = self.emojiContentSize;
        size.width = self.emojiContentSize.width + self.frame.size.width * _emojiModelList.count;
        self.emojiBackgroundView.contentSize = size;
        if (model.tabImage) {
            [emojiList addObject:model.tabImage];
        }
    }
    [self.tabbarView reloadTabView:emojiList.copy];
    if (nc_currentSelectIndexPackage <= self.emojiModelList.count)
        [self showEmoticonPackage:nc_currentSelectIndexPackage];
}

- (void)emojiBtnHandle:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didTouchEmojiView:touchedEmoji:)]) {
        [self.delegate didTouchEmojiView:self touchedEmoji:sender.titleLabel.text];
    }
}

- (void)showEmoticonPackage:(int)index {
    int selectIndex = index;
    if (self.disableDefaultEmoji) {
        if (index>=self.emojiModelList.count) {
            return;
        }
        NCEmoticonPackage *model = self.emojiModelList[index];
        pageCtrl.numberOfPages = model.totalPage;
        [model showEmoticonView:0];
        if (nc_currentSelectIndexPage > model.totalPage) {
            nc_currentSelectIndexPage = 0;
        }
    } else {
        if (selectIndex > 0) {
            selectIndex = selectIndex + self.emojiTotalPage - 1;
            NCEmoticonPackage *model = self.emojiModelList[index - 1];
            pageCtrl.numberOfPages = model.totalPage;
            [model showEmoticonView:0];
            if (nc_currentSelectIndexPage > model.totalPage) {
                nc_currentSelectIndexPage = 0;
            }

    } else {
        pageCtrl.numberOfPages = self.emojiTotalPage;
    }
    }
    CGSize viewSize = self.emojiBackgroundView.frame.size;
    CGRect rect = CGRectMake(selectIndex * viewSize.width, 0, viewSize.width, viewSize.height);
    [self.emojiBackgroundView scrollRectToVisible:rect animated:NO];
    [pageCtrl setCurrentPage:index];
    nc_currentSelectIndexPackage = index;
    _preSelectEmoticonPackageIndex = index;
    [self showEmoticonView:nc_currentSelectIndexPage];
    [self.tabbarView showEmotion:index];
}

- (void)showEmoticonView:(int)index {
    if (self.disableDefaultEmoji) {
        if (nc_currentSelectIndexPackage>= self.emojiModelList.count) {
            return;
        }
        NCEmoticonPackage *model = _emojiModelList[nc_currentSelectIndexPackage];
        if (nc_currentSelectIndexPage < model.totalPage) {
            [model showEmoticonView:nc_currentSelectIndexPage];
            [self setCurrentIndex:nc_currentSelectIndexPage withTotalPages:model.totalPage];
        }
        return;
    }
    //    // Scroll the UIScrollView to the selected page.
    if (nc_currentSelectIndexPackage > 0) {
        if ((nc_currentSelectIndexPackage - 1) < _emojiModelList.count) {
            NCEmoticonPackage *model = _emojiModelList[nc_currentSelectIndexPackage - 1];
            if (nc_currentSelectIndexPage < model.totalPage) {
                [model showEmoticonView:nc_currentSelectIndexPage];
                [self setCurrentIndex:nc_currentSelectIndexPage withTotalPages:model.totalPage];
            }
        }
    } else {
        while (self.emojiLoadedPage <= index && (self.faceEmojiArray && self.faceEmojiArray.count > 0)) {
            [self loadEmojiViewPartly];
        }
        CGSize viewSize = self.emojiBackgroundView.frame.size;
        CGRect rect = CGRectMake(index * viewSize.width, 0, viewSize.width, viewSize.height);
        [self.emojiBackgroundView scrollRectToVisible:rect animated:YES];
        [pageCtrl setCurrentPage:index];
    }
}

// Handles page-control selection changes.
- (void)pageTurn:(UIPageControl *)sender {
    int index = (int)sender.currentPage;
    nc_currentSelectIndexPage = 0;
    [self showEmoticonPackage:index];
}

- (float)getBoardViewBottonOriginY {
    float gap = (NC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) ? 64 : 0;
    return [UIScreen mainScreen].bounds.size.height - gap;
}

- (void)needReloadEmoticonTabSource:(NSNotification *)notification {
    NSArray<NCEmoticonTabSource> *emoticonTabList = notification.object;
    if (emoticonTabList) {
        [self reloadExtensionEmoticonTabSource];
        if ([self.delegate isMemberOfClass:[NCChatSessionInputBarControl class]]) {
            NCChatSessionInputBarControl *chatSessionInputBarControl = (NCChatSessionInputBarControl *)self.delegate;
            if (chatSessionInputBarControl.inputTextView.text &&
                chatSessionInputBarControl.inputTextView.text.length > 0) {
                [self enableSendButton:YES];
            } else {
                [self enableSendButton:NO];
            }
        }
    }
}

#pragma mark - Getters and Setters
- (CGSize)contentViewSize {
    return CGSizeMake(self.frame.size.width, 186);
}

- (NCEmojiTabView *)tabbarView{
    if (!_tabbarView) {
        _tabbarView = [[NCEmojiTabView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 38, self.frame.size.width, 38)];
        _tabbarView.backgroundColor = NCDynamicColor(@"auxiliary_background_2_color");
        _tabbarView.delegate = self;
        _tabbarView.accessibilityLabel = @"emoji_tabbarView";
    }
    return _tabbarView;
}


- (void)setDisableDefaultEmoji:(BOOL)disableDefaultEmoji {
    _disableDefaultEmoji = disableDefaultEmoji;
    if (disableDefaultEmoji) {
        [self cleanDefaultEmoji];
       
        [self generateDefaultLayoutParameters];
        if (pageCtrl) {
            [pageCtrl removeFromSuperview];
            pageCtrl = nil;
        }
        [self loadCustomerEmoticonPackage];
    }
}

- (void)cleanDefaultEmoji {
    self.emojiBackgroundView.contentSize = self.emojiBackgroundView.frame.size;
    self.emojiContentSize = CGSizeMake(0, self.emojiBackgroundView.contentSize.height);
    self.faceEmojiArray = @[];
    nc_currentSelectIndexPackage = 0;
    nc_currentSelectIndexPage = 0;
    for (UIView *subView in self.emojiBackgroundView.subviews) {
        [subView removeFromSuperview];
    }
}

- (BOOL)disableDefaultEmoji {
    return _disableDefaultEmoji;
}
@end
