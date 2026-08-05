//
//  NCImageSlideController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCImageSlideController.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCAssetHelper.h"
#import "NCMessageModel.h"
#import "NCImageLoader.h"
#import "NCImageView.h"
#import "NCChatUI.h"
#import "NCAlertView.h"
#import "NCActionSheetView.h"
#import "NCImagePreviewCell.h"
#import "NCPhotoPreviewCollectionViewFlowLayout.h"
#import "NCBaseCollectionView.h"
@interface NCImageSlideController () <UIScrollViewDelegate, NCImagePreviewCellDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NCChatUIMessageEventObserver>

// Model for the currently displayed image message.
@property (nonatomic, strong) NSMutableArray<NCMessageModel *> *messageModelArray;
// Index of the currently displayed image message.
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, assign) long previousMessageId;

@property (nonatomic, strong) NCPhotoPreviewCollectionViewFlowLayout *flowLayout;

@property (nonatomic, strong) NCBaseCollectionView *collectionView;

@property (nonatomic, assign) CGFloat previousContentOffsetX;

@property (nonatomic, assign) BOOL isAppear;

@property (nonatomic, assign) BOOL isTouchScroll;

@property (nonatomic, assign) CGFloat viewWidth;

@property (nonatomic, assign) BOOL isLoadingBack;

@property (nonatomic, assign) BOOL isLoadingFront;

@property (nonatomic, strong, nullable) NCChannelIdentifier *previewChannelIdentifier;

@property (nonatomic, strong) NSMutableArray<NCLocalMessagesByTimeQuery *> *activeImageQueries;

@end

@implementation NCImageSlideController {
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
    [self.view addSubview:self.collectionView];
    [self strechToSuperview:self.collectionView];
    [self getMessageFromModel:self.messageModel];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self setStatusBarHidden:@(YES)];
    self.isAppear = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:NCChatUIViewSupportAutorotateNotification object:@(YES)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
    _statusBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    if (self.currentIndex < self.messageModelArray.count) {
        self.previousMessageId = self.messageModelArray[self.currentIndex].clientId;
    }
    self.isAppear = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:NCChatUIViewSupportAutorotateNotification object:@(NO)];
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

static NCChannelIdentifier *NCImageChannelIdentifierFromMessageModel(NCMessageModel *messageModel) {
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
// Load a bounded set of images around the current item.
- (void)getMessageFromModel:(NCMessageModel *)model {
    if (!model) {
        NCLogReleaseW(@"Parameters are not allowed to be nil");
        return;
    }
    if (self.onlyPreviewCurrentMessage) {
        self.currentIndex = 0;
        self.messageModelArray = [NSMutableArray arrayWithObject:model];
        [self.collectionView reloadData];
        return;
    }
    self.currentIndex = 0;
    self.messageModelArray = [NSMutableArray arrayWithObject:model];
    [self.collectionView reloadData];
    [self scrollToCurrentIndex];
    __weak typeof(self) weakSelf = self;
    [self resolvePreviewAnchorModel:model completion:^(NCMessageModel *resolvedModel, NCChannelIdentifier *channelIdentifier) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.previewChannelIdentifier = channelIdentifier;
        [strongSelf getOlderMessagesThanModel:resolvedModel count:5 times:0 completion:^(NSArray<NCMessageModel *> *olderModels) {
            [strongSelf getLaterMessagesThanModel:resolvedModel count:5 times:0 completion:^(NSArray<NCMessageModel *> *newerModels) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Assemble in ascending receive order: older + anchor + newer. Deduplicate by clientId so the anchor appears once.
                NSMutableArray<NCMessageModel *> *imageArr = [[NSMutableArray alloc] init];
                [strongSelf appendModels:olderModels toArray:imageArr];
                [strongSelf appendModels:@[ resolvedModel ] toArray:imageArr];
                [strongSelf appendModels:newerModels toArray:imageArr];
                if (imageArr.count == 0) {
                    [imageArr addObject:resolvedModel];
                }
                strongSelf.messageModelArray = imageArr;
                for (NSInteger i = 0; i < imageArr.count; i++) {
                    if ([strongSelf isSameModel:resolvedModel asModel:[imageArr objectAtIndex:i]]) {
                        strongSelf.currentIndex = i;
                    }
                }
                [strongSelf.collectionView reloadData];
                [strongSelf scrollToCurrentIndex];
            });
            }];
        }];
    }];
}

- (void)resolvePreviewAnchorModel:(NCMessageModel *)model
                       completion:(void (^)(NCMessageModel *resolvedModel, NCChannelIdentifier *channelIdentifier))completion {
    NCChannelIdentifier *fallbackIdentifier = NCImageChannelIdentifierFromMessageModel(model);
    if (!completion) {
        return;
    }
    if ((model.messageId ?: @"").length == 0 && model.clientId <= 0) {
        completion(model, fallbackIdentifier);
        return;
    }

    NCGetMessageByIdParams *params = nil;
    if ((model.messageId ?: @"").length > 0) {
        params = [[NCGetMessageByIdParams alloc] initWithMessageId:model.messageId];
    } else {
        params = [[NCGetMessageByIdParams alloc] initWithMessageClientId:model.clientId];
    }

    [NCBaseChannel getMessageByIdWithParams:params completion:^(NCMessage * _Nullable message, NCError * _Nullable error) {
        if (error || !message) {
            completion(model, fallbackIdentifier);
            return;
        }
        NCMessageModel *resolvedModel = [NCMessageModel modelWithNCMessage:message];
        completion(resolvedModel ?: model, message.channelIdentifier ?: fallbackIdentifier);
    }];
}

- (void)queryImageMessagesWithAnchorModel:(NCMessageModel *)anchorModel
                                    count:(NSInteger)count
                              isAscending:(BOOL)isAscending
                               completion:(void (^)(NSArray<NCMessage *> *messages))completion {
    NCChannelIdentifier *channelIdentifier = self.previewChannelIdentifier ?: NCImageChannelIdentifierFromMessageModel(anchorModel);
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
    params.messageTypes = @[ NCMessageType.image ];
    NCLocalMessagesByTimeQuery *query = [NCBaseChannel createLocalMessagesByTimeQueryWithParams:params];
    @synchronized (self) {
        [self.activeImageQueries addObject:query];
    }
    __weak typeof(self) weakSelf = self;
    [query loadNextPageWithCompletion:^(NSArray<NCMessage *> * _Nullable messages, NCError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            @synchronized (strongSelf) {
                [strongSelf.activeImageQueries removeObject:query];
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

// Append models to target while skipping messages already present under the identity rules.
// The underlying by_time query may include the anchor in every result, so deduplication keeps it from appearing twice.
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

// Return only messages not already in the list for paged swipe deduplication.
- (NSArray<NCMessageModel *> *)modelsExcludingExisting:(NSArray<NCMessageModel *> *)models {
    NSMutableArray<NCMessageModel *> *result = [NSMutableArray array];
    for (NCMessageModel *model in models) {
        BOOL exists = NO;
        for (NCMessageModel *existing in self.messageModelArray) {
            if ([self isSameModel:existing asModel:model]) {
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

- (void)getLaterMessagesThanModel:(NCMessageModel *)model
                            count:(NSInteger)count
                            times:(int)times
                       completion:(void (^)(NSArray<NCMessageModel *> *models))completion {
    // Newer messages in ascending order (send_time > anchor).
    [self queryImageMessagesWithAnchorModel:model count:count isAscending:YES completion:^(NSArray<NCMessage *> *messages) {
        NSArray<NCMessageModel *> *messageModels = [self messageModelsWithMessages:messages];
        if (times < 2 && messageModels.count == 0 && messages.count == count && messages.lastObject) {
            NCMessageModel *nextModel = [NCMessageModel modelWithNCMessage:messages.lastObject];
            if (nextModel) {
                [self getLaterMessagesThanModel:nextModel count:count times:times + 1 completion:completion];
                return;
            }
        }
        if (completion) {
            completion(messageModels ?: @[]);
        }
    }];
}

- (void)getOlderMessagesThanModel:(NCMessageModel *)model
                            count:(NSInteger)count
                            times:(int)times
                       completion:(void (^)(NSArray<NCMessageModel *> *models))completion {
    // Older messages are queried in descending order (send_time < anchor); the database returns them in ascending order.
    [self queryImageMessagesWithAnchorModel:model count:count isAscending:NO completion:^(NSArray<NCMessage *> *messages) {
        NSArray<NCMessageModel *> *messageModels = [self messageModelsWithMessages:messages];
        if (times < 2 && messages.count == count && messageModels.count == 0 && messages.lastObject) {
            NCMessageModel *nextModel = [NCMessageModel modelWithNCMessage:messages.lastObject];
            if (nextModel) {
                [self getOlderMessagesThanModel:nextModel count:count times:times + 1 completion:completion];
                return;
            }
        }
        if (completion) {
            completion(messageModels ?: @[]);
        }
    }];
}

#pragma mark - collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.messageModelArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NCImagePreviewCell *cell =
        [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NCImagePreviewCell" forIndexPath:indexPath];
    cell.delegate = self;
    NCMessageModel *model = self.messageModelArray[indexPath.row];
    [cell configPreviewCellWithItem:model];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[NCImagePreviewCell class]]) {
        [(NCImagePreviewCell *)cell resetSubviews];
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
    if (self.currentIndex >= self.messageModelArray.count) {
        return;
    }
    self.viewWidth = self.view.bounds.size.width;
    self.previousContentOffsetX = self.currentIndex * self.view.bounds.size.width;
    self.previousMessageId = self.messageModelArray[self.currentIndex].clientId;
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
        NCMessageModel *anchorModel = self.messageModelArray.lastObject;
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
                [strongSelf.messageModelArray addObjectsFromArray:newModels];
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
        NCMessageModel *anchorModel = self.messageModelArray.firstObject;
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
                [strongSelf.messageModelArray insertObjects:newModels
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
    int index = (int)(scrollView.contentOffset.x / self.view.bounds.size.width);
    if (index < self.messageModelArray.count && self.viewWidth == self.view.bounds.size.width && self.isTouchScroll) {
        self.currentIndex = index;
    }
}

- (void)getBackMessagesForModel:(NCMessageModel *)model
                          count:(NSInteger)count
                          times:(int)times
                     completion:(void (^)(NSArray<NCMessageModel *> *models))completion {
    // Page toward newer messages in ascending order.
    [self queryImageMessagesWithAnchorModel:model count:count isAscending:YES completion:^(NSArray<NCMessage *> *messages) {
        NSArray<NCMessageModel *> *messageModels = [self messageModelsWithMessages:messages];
        if (times < 2 && messageModels.count == 0 && messages.count == count && messages.lastObject) {
            NCMessageModel *nextModel = [NCMessageModel modelWithNCMessage:messages.lastObject];
            if (nextModel) {
                [self getLaterMessagesThanModel:nextModel count:count times:times + 1 completion:completion];
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
    // Query older messages in descending order; the database returns ascending results, so no additional reversal is needed.
    [self queryImageMessagesWithAnchorModel:model count:count isAscending:NO completion:^(NSArray<NCMessage *> *messages) {
        NSArray<NCMessageModel *> *messageModels = [self messageModelsWithMessages:messages];
        if (times < 2 && messages.count == count && messageModels.count == 0 && messages.lastObject) {
            NCMessageModel *nextModel = [NCMessageModel modelWithNCMessage:messages.lastObject];
            if (nextModel) {
                [self getOlderMessagesThanModel:nextModel count:count times:times + 1 completion:completion];
                return;
            }
        }
        if (completion) {
            completion(messageModels ?: @[]);
        }
    }];
}

#pragma mark - NCImagePreviewCellDelegate
- (void)imagePreviewCellDidSingleTap:(NCImagePreviewCell *)cell{
    self.isAppear = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePreviewCellDidLongTap:(UILongPressGestureRecognizer *)sender{
    [self longPressed:sender];
}

- (void)longPressed:(id)sender {
    [NCActionSheetView showActionSheetView:nil cellArray:@[NCUILocalizedString(@"save")] cancelTitle:NCUILocalizedString(@"cancel") selectedBlock:^(NSInteger index) {
        [self saveImage];
    } cancelBlock:^{
        
    }];
}

#pragma mark - Notification
- (void)registerNotificationCenter {
    [[NCChatUI shared] addMessageEventObserver:self];
}

- (void)onDeletedMessagesForAll:(NSArray<NCMessage *> *)messages {
    if (messages.count == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NCMessageModel *currentModel = self.messageModelArray[self.currentIndex];
        BOOL isCurrentMessageDeletedForAll = NO;
        for (NCMessage *message in messages) {
            if (message.clientId == currentModel.clientId) {
                isCurrentMessageDeletedForAll = YES;
                break;
            }
        }
        // Dismiss the preview only when the image being viewed is deleted for everyone.
        if (isCurrentMessageDeletedForAll) {
            UIAlertController *alertController = [UIAlertController
                alertControllerWithTitle:nil
                                 message:NCUILocalizedString(@"message_delete_for_all_alert")
                          preferredStyle:UIAlertControllerStyleAlert];
            [alertController
                addAction:[UIAlertAction actionWithTitle:NCUILocalizedString(@"confirm")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                     [self.navigationController dismissViewControllerAnimated:YES
                                                                                                   completion:nil];
                                                 }]];
            [self.navigationController presentViewController:alertController animated:YES completion:nil];
        }
    });
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

- (void)saveImage {
    NCImageMessage *cImageMessage = (NCImageMessage *)self.messageModelArray[self.currentIndex].content;
    UIImage *image;
    if (cImageMessage.localPath.length > 0 &&
        [[NSFileManager defaultManager] fileExistsAtPath:cImageMessage.localPath]) {
        NSString *path = cImageMessage.localPath;
        NSData *imageData = [[NSData alloc] initWithContentsOfFile:path];
        image = [UIImage imageWithData:imageData];
    } else {
        NSData *imageData = [NCChatUIUtility getImageDataForURLString:cImageMessage.remoteUrl];
        if (imageData) {
            image = [UIImage imageWithData:imageData];
        } else {
            image = cImageMessage.thumbnailImage;
        }
    }

    [NCAssetHelper savePhotosAlbumWithImage:image authorizationStatusBlock:^{
        [self showAlertController:NCUILocalizedString(@"access_right_title")
                          message:NCUILocalizedString(@"photo_access_right")
                      cancelTitle:NCUILocalizedString(@"ok")];
    } resultBlock:^(BOOL success) {
        [self showAlertWithSuccess:success];
    }];
}

- (void)showAlertWithSuccess:(BOOL)success {
    if (success) {
        NCLogD(@"save image succeed");
        [self showAlertController:nil
                          message:NCUILocalizedString(@"save_photo_success")
                      cancelTitle:NCUILocalizedString(@"ok")];
    } else {
        NCLogD(@" save image fail");
        [self showAlertController:nil
                          message:NCUILocalizedString(@"save_photo_failed")
                      cancelTitle:NCUILocalizedString(@"ok")];
    }
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    [NCAlertView showAlertController:title message:message cancelTitle:cancelTitle inViewController:self];
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

#pragma mark - Getters and Setters
- (NCImageMessage *)currentPreviewImage {
    if (self.currentIndex < self.messageModelArray.count) {
        return (NCImageMessage *)(self.messageModelArray[self.currentIndex].content);
    }
    return nil;
}

- (NCBaseCollectionView *)collectionView {
    if(!_collectionView) {
        self.flowLayout = [[NCPhotoPreviewCollectionViewFlowLayout alloc] init];
        [self.flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        self.flowLayout.itemSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
        self.flowLayout.minimumLineSpacing = 0;
        self.flowLayout.minimumInteritemSpacing = 0;
        _collectionView = [[NCBaseCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        [_collectionView registerClass:[NCImagePreviewCell class] forCellWithReuseIdentifier:@"NCImagePreviewCell"];
        _collectionView.dataSource = self;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.delegate = self;
        [_collectionView setPagingEnabled:YES];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
    }
    return _collectionView;
}

- (NSMutableArray<NCLocalMessagesByTimeQuery *> *)activeImageQueries {
    if (!_activeImageQueries) {
        _activeImageQueries = [[NSMutableArray alloc] init];
    }
    return _activeImageQueries;
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
