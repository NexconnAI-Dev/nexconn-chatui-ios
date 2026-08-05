//
//  NCSightSlideViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightSlideViewController.h"
#import "NCChatUI.h"
#import "NCChatUIUtility.h"
#import "NCAssetHelper.h"
#import "NCMessageModel.h"
#import "NCSightCollectionView.h"
#import "NCSightCollectionViewCell.h"
#import "NCSightFileBrowserViewController.h"
#import "NCChatUICommonDefine.h"
#import "NCAlertView.h"
#import "NCActionSheetView.h"
#import "NCSightPlayerOverlayView+ChatUI.h"
#import "NCSightModel.h"
#import "NCSightModel+internal.h"
#import "NCSightPlayerController+ChatUI.h"
#import "NCPhotoPreviewCollectionViewFlowLayout.h"
#import "NCBaseButton.h"
@interface NCSightSlideViewController () <UIScrollViewDelegate, NCSightCollectionViewCellDelegate,
                                          UICollectionViewDataSource, UICollectionViewDelegate,
                                          UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate,
                                          NCChatUIMessageEventObserver>

@property (nonatomic, strong) NCBaseImageView *imageView;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

// Model for the currently displayed sight message.
@property (nonatomic, strong) NSMutableArray<NCSightModel *> *messageModelArray;
// Index of the currently displayed sight message.
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, assign) long previousMessageId;

@property (nonatomic, strong) NCSightCollectionView *collectionView;

@property (nonatomic, assign) CGFloat previousContentOffsetX;

@property (nonatomic, strong) NCBaseButton *rightTopButton;

@property (nonatomic, assign) BOOL autoPlayFlag;

@property (nonatomic, assign) BOOL isAppear;

@property (nonatomic, assign) BOOL isTouchScroll;

@property (nonatomic, assign) CGFloat viewWidth;

@property (nonatomic, assign) BOOL isLoadingBack;

@property (nonatomic, assign) BOOL isLoadingFront;

@property (nonatomic, strong, nullable) NCChannelIdentifier *previewChannelIdentifier;

@property (nonatomic, strong) NSMutableArray<NCLocalMessagesByTimeQuery *> *activeSightQueries;
@end

@implementation NCSightSlideViewController {
    BOOL _statusBarHidden;
    BOOL _isNotchScreen; // Whether the device has a display notch.
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 11.0, *)) {
        if ([NCChatUIUtility getKeyWindow].safeAreaInsets.bottom > 0) {
            _isNotchScreen = YES;
        }
    }
    // Make the navigation bar transparent.
    self.autoPlayFlag = YES;
    [self getMessageFromModel:self.messageModel];
    
    [self.view addSubview:self.collectionView];
    [self strechToSuperview:self.collectionView];
    
    [self.view addSubview:self.rightTopButton];
    self.navigationController.navigationBarHidden = YES;
    [self performSelector:@selector(setStatusBarHidden:) withObject:@(YES) afterDelay:0.6];
    self.automaticallyAdjustsScrollViewInsets = NO;

    [self registerNotificationCenter];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.isTouchScroll) {
        return;
    }
    [self scrollToCurrentIndex];
    
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self setStatusBarHidden:@(YES)];
    [self updateRightTopButtonFrame];
    self.isAppear = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:NCChatUIViewSupportAutorotateNotification object:@(YES)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
    _statusBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    if (self.currentIndex < self.messageModelArray.count) {
        self.previousMessageId = self.messageModelArray[self.currentIndex].messageModel.clientId;
    }
    [self resetPlay];
    self.isAppear = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:NCChatUIViewSupportAutorotateNotification object:@(NO)];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.collectionView.contentInset = UIEdgeInsetsZero;
}

- (BOOL)prefersStatusBarHidden {
    return _statusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

- (void)dealloc {
    [[NCChatUI shared] removeMessageEventObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

static NCChannelIdentifier *NCSightChannelIdentifierFromMessageModel(NCMessageModel *messageModel) {
    NSString *channelId = messageModel.channelId ?: @"";
    switch ((NCChannelType)messageModel.channelType) {
        case NCChannelTypeDirect:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeDirect
                                                          channelId:channelId];
        case NCChannelTypeGroup:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeGroup
                                                          channelId:channelId];
        case NCChannelTypeSystem:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeSystem
                                                          channelId:channelId];
        case NCChannelTypeOpen:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeOpen
                                                          channelId:channelId];
        case NCChannelTypeCommunity:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeCommunity
                                                          channelId:channelId];
        default:
            return nil;
    }
}

#pragma mark - Data Source Handling
- (void)querySightMessagesWithAnchorModel:(NCMessageModel *)anchorModel
                                     count:(NSInteger)count
                               isAscending:(BOOL)isAscending
                                completion:(void (^)(NSArray<NCMessage *> *messages))completion {
    NCChannelIdentifier *channelIdentifier = self.previewChannelIdentifier ?: NCSightChannelIdentifierFromMessageModel(anchorModel);
    if (!channelIdentifier || channelIdentifier.channelId.length == 0) {
        if (completion) {
            completion(@[]);
        }
        return;
    }
    NCLocalMessagesByTimeQueryParams *params = [[NCLocalMessagesByTimeQueryParams alloc] init];
    params.channelIdentifier = channelIdentifier;
    params.pageSize = count;
    params.sentTime = anchorModel.sentTime;
    params.isAscending = isAscending;
    params.messageTypes = @[ NCMessageType.shortVideo ];
    NCLocalMessagesByTimeQuery *query = [NCBaseChannel createLocalMessagesByTimeQueryWithParams:params];
    @synchronized (self) {
        [self.activeSightQueries addObject:query];
    }
    __weak typeof(self) weakSelf = self;
    [query loadNextPageWithCompletion:^(NSArray<NCMessage *> * _Nullable messages, NCError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            @synchronized (strongSelf) {
                [strongSelf.activeSightQueries removeObject:query];
            }
        }
        if (completion) {
            completion(error ? @[] : (messages ?: @[]));
        }
    }];
}

- (NSArray<NCMessageModel *> *)messageModelsWithMessages:(NSArray<NCMessage *> *)messages {
    NSMutableArray<NCMessageModel *> *models = [NSMutableArray array];
    for (NCMessage *message in messages) {
        NCMessageModel *model = [NCMessageModel modelWithNCMessage:message];
        if (model) {
            [models addObject:model];
        }
    }
    return models;
}

- (void)getBackMessagesForModel:(NCMessageModel *)model
                          count:(NSInteger)count
                          times:(int)times
                     completion:(void (^)(NSArray<NCMessageModel *> *models))completion {
    // Page toward newer sight messages by querying after the anchor in ascending order.
    [self querySightMessagesWithAnchorModel:model count:count isAscending:YES completion:^(NSArray<NCMessage *> *messages) {
        NSArray<NCMessageModel *> *messageModels = [self messageModelsWithMessages:messages];
        if (times < 2 && messageModels.count == 0 && messages.count == count && messages.lastObject) {
            NCMessageModel *nextModel = [NCMessageModel modelWithNCMessage:messages.lastObject];
            if (nextModel) {
                [self getBackMessagesForModel:nextModel count:count times:times + 1 completion:completion];
                return;
            }
        }
        if (completion) {
            completion(messageModels ?: @[]);
        }
    }];
}

- (void)getFrontMessagesForModel:(NCMessageModel *)model
                           count:(NSInteger)count
                           times:(int)times
                      completion:(void (^)(NSArray<NCMessageModel *> *models))completion {
    // Page toward older sight messages by querying before the anchor in descending order.
    [self querySightMessagesWithAnchorModel:model count:count isAscending:NO completion:^(NSArray<NCMessage *> *messages) {
        NSArray<NCMessageModel *> *messageModels = [self messageModelsWithMessages:messages];
        if (times < 2 && messages.count == count && messageModels.count == 0 && messages.lastObject) {
            NCMessageModel *nextModel = [NCMessageModel modelWithNCMessage:messages.lastObject];
            if (nextModel) {
                [self getFrontMessagesForModel:nextModel count:count times:times + 1 completion:completion];
                return;
            }
        }
        if (completion) {
            completion(messageModels ?: @[]);
        }
    }];
}

- (void)getMessageFromModel:(NCMessageModel *)model {
    if (!model) {
        NCLogReleaseW(@"Parameters are not allowed to be nil");
        return;
    }
    // Display the current message first so failed surrounding queries do not leave the page empty.
    self.currentIndex = 0;
    self.messageModelArray = [self getSightModels:@[ model ]].mutableCopy;
    [self.collectionView reloadData];
    [self scrollToCurrentIndex];

    if (self.onlyPreviewCurrentMessage) {
        return;
    }
    self.previewChannelIdentifier = NCSightChannelIdentifierFromMessageModel(model);
    __weak typeof(self) weakSelf = self;
    [self getFrontMessagesForModel:model count:5 times:0 completion:^(NSArray<NCMessageModel *> *frontMessagesArray) {
        [weakSelf getBackMessagesForModel:model count:5 times:0 completion:^(NSArray<NCMessageModel *> *backMessageArray) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                NSMutableArray<NCMessageModel *> *modelsArray = [[NSMutableArray alloc] init];
                [strongSelf appendModels:frontMessagesArray toArray:modelsArray];
                [strongSelf appendModels:@[ model ] toArray:modelsArray];
                [strongSelf appendModels:backMessageArray toArray:modelsArray];
                if (modelsArray.count == 0) {
                    [modelsArray addObject:model];
                }
                strongSelf.currentIndex = 0;
                for (NSInteger i = 0; i < modelsArray.count; i++) {
                    if ([strongSelf isSameModel:model asModel:modelsArray[i]]) {
                        strongSelf.currentIndex = i;
                        break;
                    }
                }
                strongSelf.messageModelArray =
                    [strongSelf getSightModels:modelsArray reusingSightModels:strongSelf.messageModelArray].mutableCopy;
                [strongSelf.collectionView reloadData];
                [strongSelf scrollToCurrentIndex];
            });
        }];
    }];
}

- (NSArray <NCSightModel *> *)getSightModels:(NSArray *)messages{
    return [self getSightModels:messages reusingSightModels:nil];
}

- (NSArray<NCSightModel *> *)getSightModels:(NSArray<NCMessageModel *> *)messages
                         reusingSightModels:(NSArray<NCSightModel *> *)existingSightModels {
    NSMutableDictionary<NSNumber *, NCSightModel *> *existingSightModelsByClientId = [NSMutableDictionary dictionary];
    for (NCSightModel *sightModel in existingSightModels) {
        existingSightModelsByClientId[@(sightModel.messageModel.clientId)] = sightModel;
    }

    NSMutableArray *array = @[].mutableCopy;
    for (NCMessageModel *model in messages) {
        NCSightModel *sight = existingSightModelsByClientId[@(model.clientId)];
        if (!sight) {
            sight = [[NCSightModel alloc] initWithMessageModel:model];
        }
        [array addObject:sight];
    }
    return array;
}

// Compare message identity by clientId first, then messageId.
- (BOOL)isSameModel:(NCMessageModel *)a asModel:(NCMessageModel *)b {
    if (!a || !b) {
        return NO;
    }
    if (a.clientId > 0 && a.clientId == b.clientId) {
        return YES;
    }
    if ((a.messageId ?: @"").length > 0 &&
        [a.messageId isEqualToString:(b.messageId ?: @"")]) {
        return YES;
    }
    return NO;
}

// The underlying by_time query may return the anchor or same-millisecond duplicates, so deduplicate by message identity.
- (void)appendModels:(NSArray<NCMessageModel *> *)models toArray:(NSMutableArray<NCMessageModel *> *)target {
    for (NCMessageModel *model in models) {
        BOOL exists = NO;
        for (NCMessageModel *existing in target) {
            if ([self isSameModel:existing asModel:model]) {
                exists = YES;
                break;
            }
        }
        if (!exists) {
            [target addObject:model];
        }
    }
}

// Return only sight messages not already present in the current list.
- (NSArray<NCMessageModel *> *)modelsExcludingExisting:(NSArray<NCMessageModel *> *)models {
    NSMutableArray<NCMessageModel *> *result = [NSMutableArray array];
    for (NCMessageModel *model in models) {
        BOOL exists = NO;
        for (NCSightModel *existing in self.messageModelArray) {
            if ([self isSameModel:existing.messageModel asModel:model]) {
                exists = YES;
                break;
            }
        }
        if (!exists) {
            [self appendModels:@[ model ] toArray:result];
        }
    }
    return result;
}

#pragma mark - collection view data source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.messageModelArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NCSightCollectionViewCell *cell =
        [self.collectionView dequeueReusableCellWithReuseIdentifier:@"RCSightCell" forIndexPath:indexPath];
    cell.delegate = self;
    NCSightModel *model = self.messageModelArray[indexPath.row];
    [cell setDataModel:model];
    NCShortVideoMessage *sightMessage = (NCShortVideoMessage *)model.messageModel.content;
    UIView *contentView = cell.contentView.subviews.firstObject;
    Class playerType = NSClassFromString(@"NCSightPlayerOverlayView");
    if (playerType) {
        for (UIView *view in contentView.subviews) {
            if ([view isKindOfClass:playerType.class]) {
                NCSightPlayerOverlayView *overlayView = ((NCSightPlayerOverlayView *)view);
                UILabel *durationTimeLabel = nil;
                if ([overlayView respondsToSelector:NSSelectorFromString(@"durationTimeLabel")]) {
                    id labelObj = [overlayView valueForKey:@"durationTimeLabel"];
                    if ([labelObj isKindOfClass:[UILabel class]]) {
                        durationTimeLabel = (UILabel *)labelObj;
                    }
                }
                durationTimeLabel.text = [self formatSeconds:sightMessage.duration];
                break;
            }
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    NCSightModel *model = self.messageModelArray[indexPath.row];
    NCSightCollectionViewCell *sightCell = (NCSightCollectionViewCell *)cell;

    if (self.messageModel.clientId == model.messageModel.clientId && self.autoPlayFlag) {
        sightCell.autoPlay = YES;
        self.autoPlayFlag = NO;
    } else {
        sightCell.autoPlay = NO;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return collectionView.bounds.size;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.isTouchScroll = YES;
    if (self.onlyPreviewCurrentMessage) {
        return;
    }
    self.viewWidth = self.view.bounds.size.width;
    self.previousContentOffsetX = self.currentIndex * self.view.bounds.size.width;
    self.previousMessageId = self.messageModelArray[self.currentIndex].messageModel.clientId;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.isTouchScroll = NO;
    if (self.onlyPreviewCurrentMessage) {
        return;
    }
    NSInteger midIndex = self.messageModelArray.count / 2;
    
    int index = (int)(scrollView.contentOffset.x / self.view.bounds.size.width);
    if (index < self.messageModelArray.count && self.viewWidth == self.view.bounds.size.width) {
        self.currentIndex = index;
    }
    
    if (self.currentIndex >= midIndex && scrollView.contentOffset.x > self.previousContentOffsetX) {
        if (self.isLoadingBack) {
            return;
        }
        NCMessageModel *anchorModel = self.messageModelArray.lastObject.messageModel;
        if (!anchorModel) {
            return;
        }
        self.isLoadingBack = YES;
        __weak typeof(self) weakSelf = self;
        [self getBackMessagesForModel:anchorModel count:5 times:0 completion:^(NSArray<NCMessageModel *> *models) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                strongSelf.isLoadingBack = NO;
                NSArray<NCMessageModel *> *newModels = [strongSelf modelsExcludingExisting:models];
                if (newModels.count == 0) {
                    [strongSelf scrollToCurrentIndex];
                    strongSelf.previousContentOffsetX = strongSelf.currentIndex * strongSelf.view.bounds.size.width;
                    return;
                }
                NSMutableArray<NSIndexPath *> *indexPathes = [NSMutableArray new];
                NSInteger lastIndex = strongSelf.messageModelArray.count;
                for (NSInteger i = 0; i < newModels.count; i++) {
                    NSIndexPath *indexpath = [NSIndexPath indexPathForRow:lastIndex + i inSection:0];
                    [indexPathes addObject:indexpath];
                }
                [strongSelf.messageModelArray addObjectsFromArray:[strongSelf getSightModels:newModels]];
                [strongSelf.collectionView insertItemsAtIndexPaths:[indexPathes copy]];
                [strongSelf.collectionView reloadItemsAtIndexPaths:[indexPathes copy]];
                [strongSelf.collectionView
                    scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:strongSelf.currentIndex inSection:0]
                           atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                   animated:NO];
                strongSelf.previousContentOffsetX = strongSelf.currentIndex * strongSelf.view.bounds.size.width;
            });
        }];
    } else if (self.currentIndex <= midIndex && scrollView.contentOffset.x < self.previousContentOffsetX) {
        if (self.isLoadingFront) {
            return;
        }
        NCMessageModel *anchorModel = self.messageModelArray.firstObject.messageModel;
        if (!anchorModel) {
            return;
        }
        self.isLoadingFront = YES;
        __weak typeof(self) weakSelf = self;
        [self getFrontMessagesForModel:anchorModel count:5 times:0 completion:^(NSArray<NCMessageModel *> *models) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                strongSelf.isLoadingFront = NO;
                NSArray<NCMessageModel *> *newModels = [strongSelf modelsExcludingExisting:models];
                if (newModels.count == 0) {
                    [strongSelf scrollToCurrentIndex];
                    strongSelf.previousContentOffsetX = strongSelf.currentIndex * strongSelf.view.bounds.size.width;
                    return;
                }
                NSMutableArray<NSIndexPath *> *indexPathes = [NSMutableArray new];
                for (NSInteger i = 0; i < newModels.count; i++) {
                    NSIndexPath *indexpath = [NSIndexPath indexPathForRow:i inSection:0];
                    [indexPathes addObject:indexpath];
                }
                [strongSelf.messageModelArray insertObjects:[strongSelf getSightModels:newModels]
                                                  atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, newModels.count)]];
                [strongSelf.collectionView reloadData];
                strongSelf.currentIndex = strongSelf.currentIndex + newModels.count;
                [strongSelf.collectionView
                    scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:strongSelf.currentIndex inSection:0]
                           atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                   animated:NO];
                strongSelf.previousContentOffsetX = strongSelf.currentIndex * strongSelf.view.bounds.size.width;
            });
        }];
    }else{
        [self scrollToCurrentIndex];
        self.previousContentOffsetX = self.currentIndex * self.view.bounds.size.width;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    int index = (round)(scrollView.contentOffset.x / self.view.bounds.size.width); // Round to the nearest item index.
    if (index < self.messageModelArray.count && self.viewWidth == self.view.bounds.size.width && self.isTouchScroll) {
        if (index != self.currentIndex) {
            [self resetPlay];
        }
        self.currentIndex = index;
    }
}

#pragma mark - NCSightCollectionViewCellDelegate

- (void)closeSight {
    self.isAppear = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sightLongPressed:(NSString *)localPath {
    [NCActionSheetView showActionSheetView:nil cellArray:@[NCUILocalizedString(@"save")] cancelTitle:NCUILocalizedString(@"cancel") selectedBlock:^(NSInteger index) {
        [self saveSight:localPath];
    } cancelBlock:^{
            
    }];
}

#pragma mark - Notification
- (void)registerNotificationCenter {
    [[NCChatUI shared] addMessageEventObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarFrameNotification
                                               object:nil];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    if (!self.isAppear) {
        return;
    }
    UIDeviceOrientation interfaceOrientation = [UIDevice currentDevice].orientation;
    if (interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight || interfaceOrientation == UIDeviceOrientationPortrait){
        [self updateRightTopButtonFrame];
    }
}

- (void)onDeletedMessagesForAll:(NSArray<NCMessage *> *)messages {
    if (messages.count == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NCMessage *message in messages) {
            long deletedMessageClientId = (long)message.clientId;
            NCSightModel *currentModel = self.messageModelArray[self.currentIndex];
            if (deletedMessageClientId == currentModel.messageModel.clientId) {
                [self didSightMessageRemoveWithCurrentIndex];
                return;
            }
            for (NSInteger index = 0; index < self.messageModelArray.count; index++) {
                NCSightModel *model = self.messageModelArray[index];
                if (deletedMessageClientId == model.messageModel.clientId) {
                    [self didSightMessageRemove:index];
                    break;
                }
            }
        }
    });
}

// Dismiss the preview when the sight message being viewed is deleted for everyone.
- (void)didSightMessageRemoveWithCurrentIndex {
    // Stop playback.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    [(NCSightCollectionViewCell *)cell stopPlay];
    
    // Present the deletion alert.
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:nil
                                                                        message:NCUILocalizedString(@"message_delete_for_all_alert")
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NCUILocalizedString(@"confirm")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *_Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [controller addAction:action];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)didSightMessageRemove:(NSInteger)index {
    if (index >= self.messageModelArray.count) return;
    [self.messageModelArray removeObjectAtIndex:index];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
        // update completion
    }];
}

#pragma mark - helper
- (void)scrollToCurrentIndex{
    if (_isNotchScreen) {
        [CATransaction begin];
        [CATransaction disableActions];
        self.collectionView.contentSize = CGSizeMake(self.messageModelArray.count*self.view.frame.size.width, self.view.frame.size.height);
        self.collectionView.contentOffset = CGPointMake(self.view.frame.size.width*self.currentIndex, 0);
        [CATransaction commit];
    }else{
        [self.collectionView performBatchUpdates:^{
            self.collectionView.contentSize = CGSizeMake(self.messageModelArray.count*self.view.frame.size.width, self.view.frame.size.height);
            self.collectionView.contentOffset = CGPointMake(self.view.frame.size.width*self.currentIndex, 0);
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)resetPlay{
    for (NCSightModel *model in self.messageModelArray) {
        if (model.messageModel.clientId == self.previousMessageId) {
            [model.playerController resetSightPlayer:NO];
            return;
        }
    }
}

- (void)updateRightTopButtonFrame{
    if ([NCChatUIUtility isRTL]) {
        self.rightTopButton.frame = CGRectMake(8, [NCChatUIUtility getWindowSafeAreaInsets].top+30, 44, 44);
    } else {
        self.rightTopButton.frame = CGRectMake(self.view.frame.size.width - 44 - 8, [NCChatUIUtility getWindowSafeAreaInsets].top+30, 44, 44);
    }
}

- (void)strechToSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *formats = @[ @"H:|[view]|", @"V:|[view]|" ];
    for (NSString *each in formats) {
        NSArray *constraints =
            [NSLayoutConstraint constraintsWithVisualFormat:each options:0 metrics:nil views:@{
                @"view" : view
            }];
        [view.superview addConstraints:constraints];
    }
}

- (void)saveSight:(NSString *)localPath {
    if (!localPath) {
        return;
    }
    [NCAssetHelper savePhotosAlbumWithVideoPath:localPath authorizationStatusBlock:^{
        [self showAlertController:NCUILocalizedString(@"access_right_title")
                          message:NCUILocalizedString(@"photo_access_right")
                      cancelTitle:NCUILocalizedString(@"ok")];
    } resultBlock:^(BOOL success) {
        [self showAlertWithSuccess:success];
    }];
}

- (void)showAlertWithSuccess:(BOOL)success {
    if (success) {
        [self showAlertController:nil
                          message:NCUILocalizedString(@"save_success")
                      cancelTitle:NCUILocalizedString(@"ok")];
    } else {
        [self showAlertController:nil
                          message:NCUILocalizedString(@"save_failed")
                      cancelTitle:NCUILocalizedString(@"ok")];
    }
}

- (NSString *)formatSeconds:(NSInteger)value {
    NSInteger seconds = value % 60;
    NSInteger minutes = value / 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    [NCAlertView showAlertController:title message:message cancelTitle:cancelTitle inViewController:self];
}

#pragma mark - Target Action
- (void)rightTopButtonClicked:(UIButton *)sender {
    NCSightCollectionViewCell *sightCell = (NCSightCollectionViewCell *)[self.collectionView
        cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0]];
    [sightCell stopPlay];
    NCMessageModel *currentModel = [self currentSightMessageModel] ?: self.messageModel;
    NCSightFileBrowserViewController *sfv =
        [[NCSightFileBrowserViewController alloc] initWithMessageModel:currentModel];
    [self.navigationController pushViewController:sfv animated:YES];
}

- (NCMessageModel *)currentSightMessageModel {
    if (self.currentIndex < 0 || self.currentIndex >= self.messageModelArray.count) {
        return nil;
    }
    return self.messageModelArray[self.currentIndex].messageModel;
}

#pragma mark - Getters and Setters

- (NCSightCollectionView *)collectionView {
    if(!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[NCPhotoPreviewCollectionViewFlowLayout alloc] init];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumInteritemSpacing = 0;
        _collectionView = [[NCSightCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        [_collectionView registerClass:[NCSightCollectionViewCell class] forCellWithReuseIdentifier:@"RCSightCell"];
        _collectionView.dataSource = self;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.delegate = self;
        [_collectionView setPagingEnabled:YES];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
    }
    return _collectionView;
}

- (NCBaseImageView *)imageView {
    if (!_imageView) {
        _imageView = [[NCBaseImageView alloc] init];
        _imageView.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
    }
    return _imageView;
}

- (NCBaseButton *)rightTopButton {
    if (!_rightTopButton) {
        _rightTopButton = [[NCBaseButton alloc] init];
        UIImage *image = NCDynamicImage(@"video_preview_list_btn_img");
        [_rightTopButton setImage:image forState:UIControlStateNormal];
        _rightTopButton.hidden = self.topRightBtnHidden;
        [_rightTopButton addTarget:self
                            action:@selector(rightTopButtonClicked:)
                  forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightTopButton;
}

- (NSMutableArray<NCLocalMessagesByTimeQuery *> *)activeSightQueries {
    if (!_activeSightQueries) {
        _activeSightQueries = [NSMutableArray array];
    }
    return _activeSightQueries;
}

- (void)setStatusBarHidden:(NSNumber *)hidden {
    _statusBarHidden = [hidden boolValue];
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}
@end
