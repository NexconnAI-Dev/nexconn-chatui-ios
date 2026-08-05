//
//  NCPhotosPickerController.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>

#import "NCPhotosPickerController.h"
#import "NCAssetModel.h"
#import "NCChatUICommonDefine.h"
#import "NCPhotoPickerCollectCell.h"
#import "NCPhotoPreviewCollectionViewController.h"
#import "NCChatUIConfig.h"
#import "NCAlertView.h"
#import "NCMBProgressHUD.h"
#import "NCBaseButton.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

#define WIDTH ((SCREEN_WIDTH - 20) / 4)
#define SIZE CGSizeMake(WIDTH, WIDTH)

static NSString *const reuseIdentifier = @"Cell";

@interface NCPhotosPickerController () <UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver,NCPhotoPickerCollectCellDelegate>
@property (nonatomic, strong) NSMutableArray<NCAssetModel *> *selectedAssets;

@property (nonatomic, strong) UIView *toolBar;
@property (nonatomic, strong) NCBaseButton *previewBtn;
@property (nonatomic, strong) NCBaseButton *btnSend;
@property (nonatomic, assign) BOOL isFull;
@property (nonatomic, assign) BOOL disableFirstAppear;
@property (nonatomic, assign) BOOL isLoad;
@property (nonatomic, strong) PHCachingImageManager *cachingImageManager;
@property (nonatomic, assign) CGRect previousPreheatRect;
@property (nonatomic, assign) CGSize thumbnailSize;

@property (nonatomic, strong) NCMBProgressHUD *progressHUD;

@end

@implementation NCPhotosPickerController

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.assetArray = [NSMutableArray new];
        self.selectedAssets = [NSMutableArray new];
        self.collectionView.backgroundColor = NCDynamicColor(@"common_background_color");
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

+ (instancetype)imagePickerViewController {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.itemSize = CGSizeMake(WIDTH, WIDTH);
    flowLayout.minimumLineSpacing = 4;
    flowLayout.minimumInteritemSpacing = 4;
    flowLayout.sectionInset = UIEdgeInsetsMake(4, 4, 1, 4);
    flowLayout.footerReferenceSize = CGSizeMake(SCREEN_WIDTH, 49);
    NCPhotosPickerController *pickerViewController =
    [[NCPhotosPickerController alloc] initWithCollectionViewLayout:flowLayout];
    return pickerViewController;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    [self _updateBottomSendImageCountButton];
    if(self.isLoad) {
        return;
    }
    __weak NCPhotosPickerController *weakSelf = self;
    [[NCAssetHelper shareAssetHelper]
     getPhotosOfGroup:self.currentAsset
     results:^(NSArray<NCAssetModel *> *photos) {
        [weakSelf updateDataSource:photos];
    }];
}

- (void)updateDataSource:(NSArray<NCAssetModel *> *)photos {
    self.assetArray = [NSMutableArray arrayWithArray:photos];
    self.isLoad = YES;
    for (int i = 0; i < photos.count; i++) {
        
        for (int j = 0; j < self.selectedAssets.count; j++) {
            if ([self.selectedAssets[j].asset isEqual:photos[i].asset]) {
                self.assetArray[i].isSelect = YES;
                break;
            }
        }
    }
    self.collectionView.alpha = self.disableFirstAppear?1:0;
    [self.collectionView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    self.collectionView.backgroundColor = NCDynamicColor(@"common_background_color");
    self.previousPreheatRect = CGRectZero;
    CGFloat scale = [UIScreen mainScreen].scale;
    self.thumbnailSize = (CGSize){WIDTH * scale, WIDTH * scale};
    
    if (NC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.extendedLayoutIncludesOpaqueBars = YES;
    }
    [self.collectionView registerClass:[NCPhotoPickerCollectCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    [self setNaviItem];
    [self createTopView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGRect statusBarRect = [[UIApplication sharedApplication] statusBarFrame];
    int shouldBeSubtractionHeight = 0;
    if (statusBarRect.size.height == 40) {
        shouldBeSubtractionHeight = 20;
    }
    CGFloat height = 49 + [self getSafeAreaExtraBottomHeight];
    _toolBar.frame = CGRectMake(0, SCREEN_HEIGHT - shouldBeSubtractionHeight - height, SCREEN_WIDTH, height);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateCachedAssets];
    
    if (!self.disableFirstAppear) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGSize size = self.collectionView.frame.size;
            CGSize contentSize = self.collectionView.contentSize;
            CGRect frame = CGRectMake(0, MAX(contentSize.height - size.height, 0), size.width, size.height);
            [self.collectionView scrollRectToVisible:frame animated:NO];
            [UIView animateWithDuration:0.1 animations:^{
                self.collectionView.alpha = 1;
            }];
        });
        self.disableFirstAppear = YES;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.cachingImageManager stopCachingImagesForAllAssets];
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateCachedAssets];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NCPhotoPickerCollectCell *cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    NCAssetModel *model = self.assetArray[indexPath.row];
    model.index = indexPath.row;
    
    [cell configPickerCellWithItem:self.assetArray[indexPath.row] delegate:self];
    
    return cell;
}

#pragma mark - NCPhotoPickerCollectCellDelegate
/// Returns whether the asset can become selected.
- (BOOL)canChangeSelectedState:(NCAssetModel *)asset {
    return [self cellCanChangeSelectedState:asset];
}

- (void)downloadFailFromiCloud {
    NSString *msg = NCUILocalizedString(@"download_fail_fromi_cloud");
    [self showAlertWithMessage:msg];
}

- (void)didChangeSelectedState:(BOOL)selected model:(NCAssetModel *)asset {
    [self cellDidChangeSelectedState:asset selected:selected];
}

- (void)didTapPickerCollectCell:(NCAssetModel *)selectModel {
    __weak typeof(self) weakSelf = self;
    [self checkDownloadFailFromiCloud:selectModel block:^(BOOL downloadFailFromiCloud) {
        [weakSelf doTapPhotoImageView:selectModel isDownloadFail:downloadFailFromiCloud];
    }];
}

- (void)enterPreviewCollectionViewController:(NCAssetModel *)selectModel {
    if(!selectModel) {
        return;
    }
    
    NCPhotoPreviewCollectionViewController *previewController =
    [NCPhotoPreviewCollectionViewController imagePickerViewController];
    previewController.isFull = self.isFull;
    [previewController previewPhotosWithSelectArr:self.selectedAssets
                                     allPhotosArr:self.assetArray
                                     currentIndex:selectModel.index
                                 accordToIsSelect:NO];
    [previewController
     setFinishPreviewAndBackPhotosPicker:^(NSMutableArray *selectArr, NSArray *assetPhotos, BOOL isFull) {
        
        self.selectedAssets = selectArr;
        self.assetArray = assetPhotos.mutableCopy;
        self.isFull = isFull;
        [self setButtonEnable];
        [self.collectionView reloadData];
    }];
    [previewController setFinishiPreviewAndSendImage:^(NSArray *selectArr, BOOL isFull) {
        self.sendPhotosBlock(selectArr, isFull);
    }];
    [self.navigationController pushViewController:previewController animated:YES];
}


- (void)checkDownloadFailFromiCloud:(NCAssetModel *)model block:(void(^)(BOOL downloadFailFromiCloud))block {
    // Request the full-size image or video to verify that it is available.
    model.isDownloadFailFromiCloud = NO;
    void(^callback)(BOOL) = ^(BOOL result) {
        model.isDownloadFailFromiCloud = result;
        if (block) block(result);
    };
    void(^progressHandler)(double, NSError *, BOOL *, NSDictionary *) = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_main_async_safe(^{
            if(progress < 1 && !error && !self.progressHUD) {
                self.progressHUD = [NCMBProgressHUD showHUDAddedTo:self.view animated:YES];
            }
        });
    };
    if (model.mediaType == PHAssetMediaTypeImage) {
        [[NCAssetHelper shareAssetHelper] getOriginImageDataWithAsset:model result:^(NSData *photo, NSDictionary *info, NCAssetModel *assetModel) {
            dispatch_main_async_safe(^{
                if(self.progressHUD) {
                    [self.progressHUD hideAnimated:YES afterDelay:0.5];
                    self.progressHUD = nil;
                }
                callback(!photo);
            });
        } progressHandler:progressHandler];
    } else if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
        [[NCAssetHelper shareAssetHelper] getOriginVideoWithAsset:model.asset result:^(AVAsset *avAsset, NSDictionary *info, NSString *imageIdentifier) {
            dispatch_main_async_safe(^{
                if(self.progressHUD) {
                    [self.progressHUD hideAnimated:YES afterDelay:0.5];
                    self.progressHUD = nil;
                }
                model.avAsset = avAsset;
                callback(!avAsset);
            });
        } progressHandler:progressHandler];
    } else {
        callback(YES);
    }
}


- (void)doTapPhotoImageView:(NCAssetModel *)model isDownloadFail:(BOOL)isDownloadFail {
    if(isDownloadFail|| [model isVideoAssetInvalid]) {
        [self downloadFailFromiCloud];
        return;
    }
    [self enterPreviewCollectionViewController:model];
}

#pragma mark - Target Action

- (void)dismissCurrentModelViewController {
    [self dismissViewControllerAnimated:YES
                             completion:^{
        
    }];
}

- (void)btnSendCliced:(UIButton *)sender {
    self.sendPhotosBlock(self.selectedAssets, self.isFull);
}

- (void)previewBtnCliced:(UIButton *)sender {
    NCPhotoPreviewCollectionViewController *previewController =
    [NCPhotoPreviewCollectionViewController imagePickerViewController];
    previewController.isFull = self.isFull;
    [previewController previewPhotosWithSelectArr:self.selectedAssets
                                     allPhotosArr:self.assetArray
                                     currentIndex:0
                                 accordToIsSelect:YES];
    [previewController
     setFinishPreviewAndBackPhotosPicker:^(NSMutableArray *selectArr, NSArray *assetPhotos, BOOL isFull) {
        self.selectedAssets = selectArr;
        [self setButtonEnable];
        self.assetArray = assetPhotos.mutableCopy;
        self.isFull = isFull;
        [self.collectionView reloadData];
    }];
    [previewController setFinishiPreviewAndSendImage:^(NSArray *selectArr, BOOL isFull) {
        self.sendPhotosBlock(selectArr, isFull);
    }];
    [self.navigationController pushViewController:previewController animated:YES];
}

#pragma mark - Private Methods
- (BOOL)cellCanChangeSelectedState:(NCAssetModel *)assetModel {
    if (!assetModel.isSelect) {
        if (self.selectedAssets.count >= 9) {
            [NCAlertView showAlertController:nil message:NCUILocalizedString(@"max_selected_photos") cancelTitle:NCUILocalizedString(@"i_know_it") inViewController:self];
            return NO;
        }
        
        if (assetModel.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
            CGFloat durationLimit = NCChatUIConfigCenter.message.uploadVideoDurationLimit;
            if (round(assetModel.duration) > durationLimit) {
                NSString *localizedString = durationLimit < 60 ? NCUILocalizedString(@"selected_video_warning_fmt_second") : NCUILocalizedString(@"selected_video_warning_fmt");
                CGFloat limit = durationLimit < 60 ? durationLimit : (durationLimit / 60.0f);
                NSString *format = durationLimit < 60 ? @"%.0f" : @"%.1f";
                NSString *text = [NSString stringWithFormat:format, limit];
                NSString *msg = [NSString stringWithFormat:localizedString, text];
                [self showAlertWithMessage:msg];
                return NO;
            }
        } else if ([[assetModel.asset valueForKey:@"uniformTypeIdentifier"]
                    isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
            if (assetModel.imageSize > NCChatUIConfigCenter.message.gifLimitSize * 1024) {
                [self showAlertWithMessage:NCUILocalizedString(@"gif_above_max_size")];
                return NO;
            }
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)cellDidChangeSelectedState:(NCAssetModel *)asset selected:(BOOL)selected{
    if (selected) {
        asset.isSelect = YES;
        BOOL isNotContains = YES;
        for (int i = 0; i < self.selectedAssets.count; i++) {
            if ([self.selectedAssets[i].asset isEqual:asset.asset]) {
                isNotContains = NO;
                break;
            }
        }
        if (isNotContains) {
            [self.selectedAssets addObject:asset];
        }
        
    } else {
        asset.isSelect = NO;
        for (int i = 0; i < self.selectedAssets.count; i++) {
            if ([self.selectedAssets[i].asset isEqual:asset.asset]) {
                [self.selectedAssets removeObject:self.selectedAssets[i]];
                break;
            }
        }
    }
    for (NCAssetModel *model in self.assetArray) {
        if (model.index == asset.index) {
            model.isSelect = selected;
            break;
        }
    }
    
    [self setButtonEnable];
    [self _updateBottomSendImageCountButton];
}

- (void)setNaviItem{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.titleLabel.font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
    UIColor *color = NCDynamicResourceColor(@"primary_color", @"photoPicker_cancel", @"0x0099ff");
    [btn setTitleColor:color forState:UIControlStateNormal];
    [btn addTarget:self
            action:@selector(dismissCurrentModelViewController)
  forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:NCUILocalizedString(@"cancel") forState:UIControlStateNormal];
    [btn sizeToFit];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    [self.navigationItem setRightBarButtonItem:rightItem];
}

- (void)createTopView {
    CGFloat height = 49 + [self getSafeAreaExtraBottomHeight];
    _toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - height, SCREEN_WIDTH, height)];
    _toolBar.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    [self.view addSubview:_toolBar];
    
    // add button for bottom bar
    _btnSend = [[NCBaseButton alloc] init];
    _btnSend.layer.cornerRadius = 5.0f;
    _btnSend.contentEdgeInsets = UIEdgeInsetsMake(5, 12, 5, 12);

    [_btnSend setTitle:NCUILocalizedString(@"send") forState:UIControlStateNormal];
    [_btnSend addTarget:self action:@selector(btnSendCliced:) forControlEvents:UIControlEventTouchUpInside];
    _btnSend.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_toolBar addSubview:_btnSend];
    
    _previewBtn = [[NCBaseButton alloc] init];
    [_previewBtn setTitle:NCUILocalizedString(@"preview") forState:UIControlStateNormal];
    _previewBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_previewBtn addTarget:self action:@selector(previewBtnCliced:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar addSubview:_previewBtn];
    
    [_btnSend setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_previewBtn setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    if ([NCChatUIUtility isRTL]) {
        [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_previewBtn(30)]"
                                                                         options:kNilOptions
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(_previewBtn)]];
        [_toolBar
         addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_btnSend(30)]"
                                                                options:kNilOptions
                                                                metrics:nil
                                                                  views:NSDictionaryOfVariableBindings(_btnSend)]];
        [_toolBar
         addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_btnSend]"
                                                                options:kNilOptions
                                                                metrics:nil
                                                                  views:NSDictionaryOfVariableBindings(_btnSend)]];
        [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_previewBtn
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_toolBar
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                              constant:-10]];
        
        [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_btnSend
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_toolBar
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1
                                                              constant:10]];
    } else {
        [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_btnSend(30)]"
                                                                         options:kNilOptions
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(_btnSend)]];
        
        [_toolBar
         addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_previewBtn(30)]"
                                                                options:kNilOptions
                                                                metrics:nil
                                                                  views:NSDictionaryOfVariableBindings(_previewBtn)]];
        [_toolBar
         addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_previewBtn]"
                                                                options:kNilOptions
                                                                metrics:nil
                                                                  views:NSDictionaryOfVariableBindings(_previewBtn)]];
        [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_btnSend
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_toolBar
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                              constant:-10]];
        
        [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_previewBtn
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_toolBar
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1
                                                              constant:10]];
    }
    
    [_btnSend setTitleColor:NCDynamicResourceColor(@"control_title_white_color",@"photoPicker_send_disable", @"0x9fcdfd")
                   forState:UIControlStateDisabled];
    [_btnSend setTitleColor:NCDynamicResourceColor(@"control_title_white_color",@"photoPicker_send_normal", @"0x0099ff")
                   forState:UIControlStateNormal];
    [_btnSend setBackgroundColor:NCDynamicColor(@"disabled_color")];
    [self.btnSend setEnabled:NO];
    [_previewBtn setTitleColor:NCDynamicResourceColor(@"text_secondary_color", @"photoPreview_send_disable", @"0x959595")
                      forState:UIControlStateDisabled];
    UIColor *titleColor = NCDynamicColor(@"primary_color");
    [_previewBtn setTitleColor:titleColor forState:UIControlStateNormal];
    [self.previewBtn setEnabled:NO];
}

- (void)setButtonEnable {
    if (self.selectedAssets.count > 0) {
        [self.btnSend setEnabled:YES];
        [self.btnSend setBackgroundColor:NCDynamicColor(@"primary_color")];
        [self.previewBtn setEnabled:YES];
    } else {
        [self.btnSend setEnabled:NO];
        [self.btnSend setBackgroundColor:NCDynamicColor(@"disabled_color")];
        [self.previewBtn setEnabled:NO];
    }
}

// show  alert
- (void)showAlertWithMessage:(NSString *)message {
    [NCAlertView showAlertController:nil message:message cancelTitle:NCUILocalizedString(@"confirm") inViewController:self];
}

- (void)_updateBottomSendImageCountButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.selectedAssets.count && self.toolBar) {
            [self.btnSend setTitle:[NSString stringWithFormat:@"%@ (%lu)",NCUILocalizedString(@"send"), (unsigned long)self.selectedAssets.count] forState:(UIControlStateNormal)];
        } else {
            [self.btnSend setTitle:NCUILocalizedString(@"send") forState:(UIControlStateNormal)];
        }
    });
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    // Photos may call this method on a background queue;
    // switch to the main queue to update the UI.
    dispatch_async(dispatch_get_main_queue(), ^{
        // Check for changes to the displayed album itself
        // (its existence and metadata, not its member assets).
        PHFetchResultChangeDetails *albumChanges = [changeInstance changeDetailsForFetchResult:self.currentAsset];
        if (albumChanges) {
            self.count = albumChanges.fetchResultAfterChanges.count;
            for (int i = 0; i < albumChanges.insertedObjects.count; i++) {
                if ([albumChanges.insertedObjects[i] isKindOfClass:[PHAsset class]]) {
                    BOOL isContain = NO;
                    BOOL isContainVideo = NCChatUIConfigCenter.message.isMediaSelectorContainVideo;
                    for (int j = 0; j < self.assetArray.count; j++) {
                        NCAssetModel *assetModel = self.assetArray[j];
                        PHAsset *newAsset = albumChanges.insertedObjects[i];
                        if (!isContainVideo && newAsset.mediaType == PHAssetMediaTypeVideo) {
                            isContain = YES;
                            break;
                        }
                        PHAsset *asset = assetModel.asset;
                        if ([newAsset.localIdentifier isEqualToString:asset.localIdentifier]) {
                            isContain = YES;
                            break;
                        }
                    }
                    if (!isContain) {
                        NCAssetModel *model = [NCAssetModel modelWithAsset:albumChanges.insertedObjects[i]];
                        [self.assetArray addObject:model];
                    }
                }
            }
            
            [self.collectionView reloadData];
        }
        
    });
}

- (float)getSafeAreaExtraBottomHeight {
    return [NCChatUIUtility getWindowSafeAreaInsets].bottom;
}

#pragma mark - Helper
- (void)updateCachedAssets {
    if (!self.isViewLoaded && !self.view.window) {
        return;
    }
    
    CGRect visibleRect = (CGRect){self.collectionView.contentOffset.x, self.collectionView.contentOffset.y,
        self.collectionView.bounds.size.width, self.collectionView.bounds.size.height};
    CGRect preheatRect = CGRectInset(visibleRect, 0, -0.5 * visibleRect.size.height);
    
    CGFloat delta = fabs(CGRectGetMinY(preheatRect) - CGRectGetMinY(self.previousPreheatRect));
    if (delta < self.collectionView.bounds.size.height / 3) {
        return;
    }
    
    NSArray<NSValue *> *addedRects = [self addedRectsBetween:self.previousPreheatRect and:preheatRect];
    NSArray<NSValue *> *removedRects = [self removedRectsBetween:self.previousPreheatRect and:preheatRect];
    NSArray<PHAsset *> *addAssets = [self assetsInRects:addedRects];
    NSArray<PHAsset *> *removedAssets = [self assetsInRects:removedRects];
    
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.synchronous = NO;
    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
    imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    
    CGFloat screenScale = [UIScreen mainScreen].scale;
    CGSize thumbnailSize = (CGSize){SIZE.width * screenScale, SIZE.height * screenScale};
    [self.cachingImageManager startCachingImagesForAssets:addAssets
                                               targetSize:thumbnailSize
                                              contentMode:PHImageContentModeAspectFill
                                                  options:imageRequestOptions];
    [self.cachingImageManager stopCachingImagesForAssets:removedAssets
                                              targetSize:thumbnailSize
                                             contentMode:PHImageContentModeAspectFill
                                                 options:nil];
    self.previousPreheatRect = preheatRect;
}

- (NSArray<PHAsset *> *)assetsInRects:(NSArray<NSValue *> *)rects {
    NSMutableArray *assets = [[NSMutableArray alloc] initWithCapacity:50];
    [rects enumerateObjectsUsingBlock:^(NSValue *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        CGRect rect = [obj CGRectValue];
        NSArray<UICollectionViewLayoutAttributes *> *attribtutes =
        [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
        [attribtutes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *_Nonnull obj, NSUInteger idx,
                                                  BOOL *_Nonnull stop) {
            if (obj.indexPath.item < self.assetArray.count) {
                NCAssetModel *model = [self.assetArray objectAtIndex:obj.indexPath.item];
                if ([model.asset isKindOfClass:[PHAsset class]]) {
                    [assets addObject:model.asset];
                }
            }
        }];
    }];
    return [assets copy];
}

- (NSArray<NSValue *> *)addedRectsBetween:(CGRect)old and:(CGRect) new {
    if (CGRectIntersectsRect(old, new)) {
        NSMutableArray *rects = [[NSMutableArray alloc] initWithCapacity:2];
        if (CGRectGetMaxY(new) > CGRectGetMaxY(old)) {
            CGRect rect =
            (CGRect){new.origin.x, CGRectGetMaxY(old), new.size.width, CGRectGetMaxY(new) - CGRectGetMaxY(old)};
            [rects addObject:[NSValue valueWithCGRect:rect]];
        }
        if (CGRectGetMinY(old) > CGRectGetMinY(new)) {
            CGRect rect =
            (CGRect){new.origin.x, CGRectGetMinY(new), new.size.width, CGRectGetMinY(old) - CGRectGetMinY(new)};
            [rects addObject:[NSValue valueWithCGRect:rect]];
        }
        return [rects copy];
    } else {
        return @[ [NSValue valueWithCGRect:new] ];
    }
}

- (NSArray<NSValue *> *)removedRectsBetween:(CGRect)old and:(CGRect) new {
    if (CGRectIntersectsRect(old, new)) {
        NSMutableArray *rects = [[NSMutableArray alloc] initWithCapacity:2];
        
        if (CGRectGetMaxY(new) < CGRectGetMaxY(old)) {
            CGRect rect =
            (CGRect){new.origin.x, CGRectGetMaxY(new), new.size.width, CGRectGetMaxY(old) - CGRectGetMaxY(new)};
            [rects addObject:[NSValue valueWithCGRect:rect]];
        }
        if (CGRectGetMinY(old) < CGRectGetMinY(new)) {
            CGRect rect =
            (CGRect){new.origin.x, CGRectGetMinY(old), new.size.width, CGRectGetMinY(new) - CGRectGetMinY(old)};
            [rects addObject:[NSValue valueWithCGRect:rect]];
        }
        return [rects copy];
    } else {
        return @[ [NSValue valueWithCGRect:old] ];
    }
}

#pragma mark - Getters and Setters
- (PHCachingImageManager *)cachingImageManager {
    if (!_cachingImageManager) {
        _cachingImageManager = [[PHCachingImageManager alloc] init];
    }
    return _cachingImageManager;
}
@end
