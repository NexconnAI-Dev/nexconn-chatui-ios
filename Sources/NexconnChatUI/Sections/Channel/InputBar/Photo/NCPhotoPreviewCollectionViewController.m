//
//  NCPhotoPreviewCollectionViewController.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPhotoPreviewCollectionViewController.h"
#import "NCAssetHelper.h"
#import "NCAssetModel.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCPhotoPreviewCollectCell.h"
#import "NCVideoPreviewCell.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "NCAlertView.h"
#import "NCPhotoPreviewCollectionViewFlowLayout.h"
#import "NCChatUIConfig.h"
#import "NCSemanticContext.h"
#import "NCBaseButton.h"
static NSString *const reuseIdentifier = @"Cell";
static NSString *const videoCellReuseIdentifier = @"VideoPreviewCell";

@interface NCPhotoPreviewCollectionViewController () <NCVideoPreviewCellDelegate>
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) NCBaseButton *selectedButton;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) NCBaseButton *fullButton;
@property (nonatomic, strong) NCBaseButton *editButton;
@property (nonatomic, strong) NCBaseButton *sendButton;

@property (nonatomic, strong) NSMutableArray<NCAssetModel *> *previewPhotosArr;
@property (nonatomic, strong) NSArray<NCAssetModel *> *allPhotosArr;

@property (nonatomic, strong) NSMutableArray<NCAssetModel *> *selectedArr;
@property (nonatomic, strong) NSMutableArray<NCAssetModel *> *selectedVideoArray;
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, copy) NSString *currentAssetIdentifier;

@property (nonatomic, assign) int32_t imageRequestID;

@end

@implementation NCPhotoPreviewCollectionViewController
#pragma mark - Life Cycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.allPhotosArr = [NSArray new];
        self.selectedArr = [NSMutableArray new];
        self.selectedVideoArray = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.collectionView.scrollsToTop = NO;
    self.collectionView.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.contentSize = CGSizeMake(SCREEN_WIDTH * self.previewPhotosArr.count, SCREEN_HEIGHT);
    self.collectionView.pagingEnabled = YES;
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.collectionView addGestureRecognizer:gesture];

    [self.collectionView registerClass:[NCPhotoPreviewCollectCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerClass:NCVideoPreviewCell.class forCellWithReuseIdentifier:videoCellReuseIdentifier];
    [self creatTopView];
    [self createBottomView];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    // On iOS 14 and later, scrolling in viewWillAppear has no effect before the collection view finishes layout.
    // Delaying by 0.1 seconds avoids repeated scrolling from viewDidLayoutSubviews during scrolling or rotation. Reference: https://www.jianshu.com/p/482703c25fb6
    if (@available(iOS 14.0, *)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                animated:NO];
        });
    } else {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                            animated:NO];
    }
    [self _updateTopBarStatus];
    _fullButton.selected = self.isFull;
    if (_fullButton.selected) {
        [self updateImageSize];
    }
}

#pragma mark - Public Methods
+ (instancetype)imagePickerViewController {
    NCPhotoPreviewCollectionViewFlowLayout *flowLayout = [[NCPhotoPreviewCollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    flowLayout.itemSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT);
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    NCPhotoPreviewCollectionViewController *previewViewController =
        [[NCPhotoPreviewCollectionViewController alloc] initWithCollectionViewLayout:flowLayout];
    return previewViewController;
}

- (void)previewPhotosWithSelectArr:(NSMutableArray *)selectedArr
                      allPhotosArr:(NSArray *)allPhotosArr
                      currentIndex:(NSInteger)currentIndex
                  accordToIsSelect:(BOOL)isSelected {
    if (isSelected) {
        _previewPhotosArr = [NSMutableArray arrayWithArray:selectedArr];
    } else {
        _previewPhotosArr = [allPhotosArr mutableCopy];
    }
    _selectedArr = selectedArr;
    _allPhotosArr = allPhotosArr;
    _currentIndex = currentIndex;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.previewPhotosArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.previewPhotosArr.count <= indexPath.row) {
        return nil;
    }
    NCAssetModel *model = self.previewPhotosArr[indexPath.row];
//    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_0 &&
//        [UIView appearance].semanticContentAttribute == UISemanticContentAttributeForceRightToLeft) {
//        /* For RTL testing, set [UIView appearance].semanticContentAttribute =
//         UISemanticContentAttributeForceRightToLeft in the app delegate.
//         Arabic layouts use this setting on iOS 9 and later. UIKit then exposes
//         the incoming array in reverse visual order, so reverse it here.
//         */
//        NSArray *reversePhotoArray = [self.previewPhotosArr reverseObjectEnumerator].allObjects;
//        model = reversePhotoArray[indexPath.row];
//    }
    NCPhotoPreviewCollectCell *cell = nil;
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:videoCellReuseIdentifier forIndexPath:indexPath];
        NCVideoPreviewCell *videoCell = (NCVideoPreviewCell *)cell;
        videoCell.delegate = self;
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
        //    [self _updateTopBarStatus];
        __weak typeof(self) weakSelf = self;
        [cell setSingleTap:^{
            weakSelf.topView.hidden = !weakSelf.topView.hidden;
            weakSelf.bottomView.hidden = weakSelf.topView.hidden;
        }];
    }
    [cell configPreviewCellWithItem:model];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[NCPhotoPreviewCollectCell class]]) {
        [(NCPhotoPreviewCollectCell *)cell resetSubviews];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint offSet = scrollView.contentOffset;
    int index = (int)roundf(offSet.x / self.view.frame.size.width);
    if (index != self.currentIndex){
        self.currentIndex = index;
        [self _updateTopBarStatus];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self _updateTopBarStatus];
    [self _updateFullButton];
    [self _updateEditButton];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    NCAssetModel *model = self.previewPhotosArr[self.currentIndex];
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
        NCVideoPreviewCell *videoCell = (NCVideoPreviewCell *)[self.collectionView
            cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];
        [videoCell stop];
    }
}

#pragma mark - NCVideoPreviewCellDelegate

- (void)sendPlayActionInCell:(UICollectionViewCell *)cell {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    NCAssetModel *model = self.previewPhotosArr[indexPath.item];
    NCVideoPreviewCell *videocell = (NCVideoPreviewCell *)cell;
    [videocell play:model.asset];
}

#pragma mark - Gesture Action

- (void)tapAction:(UIGestureRecognizer *)gesture {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    CGPoint point = [gesture locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    NCAssetModel *model = self.previewPhotosArr[indexPath.row];
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
        NCVideoPreviewCell *videoCell = (NCVideoPreviewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [videoCell stop];
    }

    self.topView.hidden = !self.topView.hidden;
    self.bottomView.hidden = self.topView.hidden;
}

- (void)backButtonAction {
    self.finishPreviewAndBackPhotosPicker(self.selectedArr, self.allPhotosArr, self.fullButton.selected);
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)isSelectedButtonAction:(UIButton *)button {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    NCAssetModel *selectModel = self.previewPhotosArr[self.currentIndex];
    if (!selectModel) {
        return;
    }
    // Report an error if the current video thumbnail cannot be downloaded from iCloud.
    if(selectModel.isDownloadFailFromiCloud ) {
        [NCAlertView showAlertController:nil message:NCUILocalizedString(@"download_fail_fromi_cloud") cancelTitle:NCUILocalizedString(@"confirm") inViewController:self];
        return;
    }
    // Preserve the thumbnail for a selected asset.
    [selectModel fetchThumbnailImage];
    [self selectedImageCanSend:selectModel
                      complete:^(BOOL canSend) {
                          if (canSend) {
                              NSInteger i = selectModel.index;
                              if (self.selectedButton.selected) {
                                  NCAssetModel *model = self.previewPhotosArr[self.currentIndex];
                                  for (int i = 0; i < self.selectedArr.count; i++) {
                                      if ([self.selectedArr[i].asset isEqual:model.asset]) {
                                          [self.selectedArr removeObject:self.selectedArr[i]];
                                          break;
                                      }
                                  }
                                  self.previewPhotosArr[self.currentIndex].isSelect = NO;
                                  self.allPhotosArr[i].isSelect = NO;
                                  [self _updateTopBarStatus];
                              } else {
                                  if (self.selectedArr.count < 9) {
                                      [self animationWithLayer:self.selectedButton.layer];
                                      NCAssetModel *model = self.previewPhotosArr[self.currentIndex];
                                      model.isSelect = YES;
                                      BOOL isNotContains = YES;
                                      for (int i = 0; i < self.selectedArr.count; i++) {
                                          if ([self.selectedArr[i].asset isEqual:model.asset]) {
                                              isNotContains = NO;
                                              break;
                                          }
                                      }
                                      if (isNotContains) {
                                          if (model.mediaType == PHAssetMediaTypeVideo &&
                                              NSClassFromString(@"NCSightCapturer")) {
                                              CGFloat durationLimit = NCChatUIConfigCenter.message.uploadVideoDurationLimit;
                                              if (round(model.duration) <= durationLimit) {
                                                  [self.selectedArr addObject:model];
                                              } else {
                                                  NSString *localizedString = durationLimit < 60 ? NCUILocalizedString(@"selected_video_warning_fmt_second") : NCUILocalizedString(@"selected_video_warning_fmt");
                                                  CGFloat limit = durationLimit < 60 ? durationLimit : (durationLimit / 60.0f);
                                                  NSString *format = durationLimit < 60 ? @"%.0f" : @"%.1f";
                                                  NSString *text = [NSString stringWithFormat:format, limit];
                                                  NSString *msg = [NSString stringWithFormat:localizedString, text];
                                                  [self showAlertWithMessage:msg];
                                                  model.isSelect = NO;
                                                  return;
                                              }
                                          } else {
                                              [self.selectedArr addObject:model];
                                          }
                                      }
                                      if (!self.allPhotosArr[i].isSelect) {
                                          self.allPhotosArr[i].isSelect = YES;
                                      }
                                      [self _updateTopBarStatus];
                                  } else {
                                      [NCAlertView showAlertController:nil message:NCUILocalizedString(@"max_selected_photos") cancelTitle:NCUILocalizedString(@"i_know_it") inViewController:self];
                                  }
                              }
                              [self _updateBottomSendImageCountButton];
                          }
                      }];
}

- (void)fullBtnCliced:(UIButton *)sender {
    self.fullButton.selected = !self.fullButton.selected;
    self.isFull = !self.isFull;
    if (_fullButton.selected) {
        if (!self.selectedButton.selected) {
            [self isSelectedButtonAction:nil];
        };
        [self updateImageSize];
    } else {
        _fullButton.titleLabel.text = [NSString stringWithFormat:@"%@", NCUILocalizedString(@"full_image")];
        [_fullButton setTitle:[NSString stringWithFormat:@"%@", NCUILocalizedString(@"full_image")]
                     forState:UIControlStateNormal];
    }
}

- (void)editBtnClick:(UIButton *)sender {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
}

- (void)sendImageMessageButton:(UIButton *)sender {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    if (self.selectedArr.count == 0) {
        [self.selectedArr addObject:self.previewPhotosArr[self.currentIndex]];
    }
    self.finishiPreviewAndSendImage(self.selectedArr, self.fullButton.selected);
}

#pragma mark - Private Methods

- (void)creatTopView {
    CGFloat originY = NC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") ? 20 : 0;
    CGFloat statusBarHeight = [NCChatUIUtility getStatusBarHeightForView:self.view];
    BOOL hasExtendedStatusBar = statusBarHeight > 25;
    if (hasExtendedStatusBar) {
        originY = 44;
    }
    self.topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, originY + 44)];
    _topView.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
    [self.view addSubview:_topView];
    NCBaseButton *backButton = [NCBaseButton buttonWithType:UIButtonTypeCustom];
    UIImage *img = NCDynamicImage(@"photo_preview_navigator_white_back_img");
    img = [NCSemanticContext imageflippedForRTL:img];
    [backButton setImage:img forState:UIControlStateNormal];
    [backButton setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 6)];
    [backButton sizeToFit];
    if (hasExtendedStatusBar) {
        backButton.frame = CGRectMake(10, _topView.frame.size.height / 2, 44, 44);
    } else {
        backButton.frame = CGRectMake(10, _topView.frame.size.height / 2 - 44 / 2, 44, 44);
    }

    [backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:backButton];

    NCBaseButton *stateButton = [NCBaseButton buttonWithType:UIButtonTypeCustom];
    [stateButton setImage:NCDynamicImage(@"photo_preview_uncheck_img") forState:UIControlStateNormal];
    [stateButton setImage:NCDynamicImage(@"photo_preview_check_img") forState:UIControlStateSelected];
    [stateButton sizeToFit];
    stateButton.imageEdgeInsets = (UIEdgeInsets){12, 12, 12, 12};
    if (hasExtendedStatusBar) {
        stateButton.frame = CGRectMake(_topView.frame.size.width - 10 - 44, _topView.frame.size.height / 2, 44, 44);
    } else {
        stateButton.frame =
            CGRectMake(_topView.frame.size.width - 10 - 44, _topView.frame.size.height / 2 - 44 / 2, 44, 44);
    }
    // Apply RTL ordering.
    [NCSemanticContext swapFrameForRTL:backButton withView:stateButton];
    
    [stateButton addTarget:self action:@selector(isSelectedButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:self.selectedButton = stateButton];
}

- (void)createBottomView {
    CGFloat safeAreaHomeBarHeight = [NCChatUIUtility getWindowSafeAreaInsetsForView:self.view].bottom;
    _bottomView = [[UIView alloc]
        initWithFrame:CGRectMake(0, self.view.bounds.size.height - 49 - safeAreaHomeBarHeight,
                                 self.view.bounds.size.width, 49 + safeAreaHomeBarHeight)];
    _bottomView.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
    [self.view addSubview:_bottomView];
    // add button for bottom bar
    _sendButton = [[NCBaseButton alloc] init];
    _sendButton.layer.cornerRadius = 5.0f;
    _sendButton.contentEdgeInsets = UIEdgeInsetsMake(5, 12, 5, 12);
    [_sendButton setTitle:NCUILocalizedString(@"send") forState:UIControlStateNormal];
    [_sendButton setTitleColor:NCDynamicResourceColor(@"control_title_white_color",@"photoPreview_send_disable", @"0x959595")
                   forState:UIControlStateDisabled];
    [_sendButton setTitleColor:NCDynamicResourceColor(@"control_title_white_color", @"photoPicker_send_normal", @"0x0099ff")
                      forState:UIControlStateNormal];
    [_sendButton setBackgroundColor:NCDynamicColor(@"disabled_color")];

    [_sendButton addTarget:self action:@selector(sendImageMessageButton:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_sendButton];
    [self _updateBottomSendImageCountButton];
    _fullButton = [[NCBaseButton alloc] init];
    [_fullButton setTitle:[NSString stringWithFormat: @"%@", NCUILocalizedString(@"full_image")]
                 forState:UIControlStateNormal];
    _fullButton.contentMode = UIViewContentModeLeft;
    _fullButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_fullButton addTarget:self action:@selector(fullBtnCliced:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_fullButton];

    _editButton = [NCBaseButton buttonWithType:(UIButtonTypeCustom)];
    [_editButton setTitle:NCUILocalizedString(@"edit") forState:(UIControlStateNormal)];
    [_editButton setTitleColor:NCDynamicResourceColor(@"text_secondary_color", @"photoPreview_send_disable", @"0x959595")
                      forState:UIControlStateNormal];
    [_editButton addTarget:self action:@selector(editBtnClick:) forControlEvents:(UIControlEventTouchUpInside)];
    [_bottomView addSubview:_editButton];

    [_sendButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_editButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_fullButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    _fullButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    if ([NCChatUIUtility isRTL]) {
        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_fullButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_fullButton)]];

        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_sendButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_sendButton)]];
        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_editButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_editButton)]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_fullButton
                                                                attribute:NSLayoutAttributeRight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeRight
                                                               multiplier:1
                                                                 constant:-10]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_sendButton
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1
                                                                 constant:10]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_editButton
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1
                                                                 constant:0]];
    } else {
        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_sendButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_sendButton)]];

        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_fullButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_fullButton)]];
        [_bottomView
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_editButton(30)]"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_editButton)]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_sendButton
                                                                attribute:NSLayoutAttributeRight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeRight
                                                               multiplier:1
                                                                 constant:-10]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_fullButton
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1
                                                                 constant:10]];

        [_bottomView addConstraint:[NSLayoutConstraint constraintWithItem:_editButton
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_bottomView
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1
                                                                 constant:0]];
    }

  
    [_fullButton setTitleColor:NCDynamicResourceColor(@"control_title_white_color",@"photoPreview_original_normal_text", @"0x999999")
                      forState:UIControlStateNormal];
    [_fullButton setTitleColor:NCDynamicResourceColor(@"control_title_white_color",@"photoPreview_original_selected_text", @"0xffffff")
                      forState:UIControlStateSelected];
    [_fullButton setImage:NCDynamicImage(@"photo_preview_uncheck_img") forState:UIControlStateNormal];
    [_fullButton setImage:NCDynamicImage(@"photo_preview_check_img") forState:UIControlStateSelected];
    _fullButton.imageEdgeInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    [self.bottomView setNeedsUpdateConstraints];
    [self.bottomView updateConstraintsIfNeeded];
    [self.bottomView layoutIfNeeded];
    [self _updateFullButton];
    [self _updateEditButton];
    if([NCSemanticContext isRTL]){
        _fullButton.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        _sendButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    }else{
        _fullButton.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        _sendButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    }
}

- (void)selectedImageCanSend:(NCAssetModel *)selectModel complete:(void (^)(BOOL canSend))completeBlock {
    if ([[selectModel.asset valueForKey:@"uniformTypeIdentifier"] isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
        [[NCAssetHelper shareAssetHelper]
            getOriginImageDataWithAsset:selectModel
                                 result:^(NSData *imageData, NSDictionary *info, NCAssetModel *assetModel) {
                                    if(!imageData) {
                                        if(completeBlock) {
                                            completeBlock(NO);
                                        }
                                        return;
                                    }
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                         if (imageData.length >
                                             NCChatUIConfigCenter.message.gifLimitSize * 1024) {
                                             completeBlock(NO);
                                             UIAlertController *alertController = [UIAlertController
                                                 alertControllerWithTitle:NCUILocalizedString(@"gif_above_max_size")
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleAlert];
                                             [alertController
                                                 addAction:[UIAlertAction
                                                               actionWithTitle:NCUILocalizedString(@"ok")
                                                                         style:UIAlertActionStyleDefault
                                                                       handler:nil]];
                                             [self presentViewController:alertController animated:YES completion:nil];
                                         } else {
                                             completeBlock(YES);
                                         }
                                     });
                                 }
         progressHandler:^(double progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
            
        }];
    } else {
        if (completeBlock) {
            completeBlock(YES);
        }
    }
}

- (void)_updateTopBarStatus {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    NCAssetModel *asset = self.previewPhotosArr[self.currentIndex];
    self.selectedButton.selected = asset.isSelect;
    if (self.fullButton.selected) {
        [self updateImageSize];
    }
}

- (void)_updateFullButton {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    NCAssetModel *model = self.previewPhotosArr[self.currentIndex];
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
        _fullButton.hidden = YES;
    } else {
        _fullButton.hidden = NO;
    }
}

- (void)_updateEditButton {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    self.editButton.hidden = YES;
}

- (void)_updateBottomSendImageCountButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.selectedArr.count && self.bottomView) {
            self.sendButton.enabled = YES;
            [self.sendButton setBackgroundColor:NCDynamicColor(@"primary_color")];

            if ([NCChatUIUtility isRTL]) {
                [self.sendButton setTitle:[NSString stringWithFormat:@"(%lu) %@", (unsigned long)self.selectedArr.count, NCUILocalizedString(@"send")] forState:(UIControlStateNormal)];
            } else {
                [self.sendButton setTitle:[NSString stringWithFormat:@"%@ (%lu)",NCUILocalizedString(@"send"), (unsigned long)self.selectedArr.count] forState:(UIControlStateNormal)];
            }
        } else {
            self.sendButton.enabled = NO;
            [self.sendButton setBackgroundColor:NCDynamicColor(@"disabled_color")];

            [self.sendButton setTitle:NCUILocalizedString(@"send") forState:(UIControlStateNormal)];
        }
    });
}

// show  alert
- (void)showAlertWithMessage:(NSString *)message {
    [NCAlertView showAlertController:nil message:message cancelTitle:NCUILocalizedString(@"confirm") inViewController:self];
}

- (void)animationWithLayer:(CALayer *)layer {
    NSNumber *animationScale1 = @(0.7);
    NSNumber *animationScale2 = @(0.92);

    [UIView animateWithDuration:0.15
        delay:0
        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
        animations:^{
            [layer setValue:animationScale1 forKeyPath:@"transform.scale"];
        }
        completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15
                delay:0
                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                animations:^{
                    [layer setValue:animationScale2 forKeyPath:@"transform.scale"];
                }
                completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.1
                                          delay:0
                                        options:UIViewAnimationOptionBeginFromCurrentState |
                                                UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         [layer setValue:@(1.0) forKeyPath:@"transform.scale"];
                                     }
                                     completion:nil];
                }];
        }];
}

- (void)updateImageSize {
    if (self.previewPhotosArr.count <= self.currentIndex) {
        return;
    }
    _fullButton.titleLabel.text = [NSString stringWithFormat:@"%@", NCUILocalizedString(@"full_image")];
    [_fullButton setTitle:[NSString stringWithFormat:@"%@", NCUILocalizedString(@"full_image")]
                 forState:UIControlStateNormal];

    NCAssetModel *model = self.previewPhotosArr[self.currentIndex];
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
        return;
    }
    if (model.imageSize) {
        [self getImageSize:model.imageSize];
    } else {
        [self.indicatorView startAnimating];
        // Cancel the pending size request after deselection.
        if (self.imageRequestID) {
            [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
        }
        self.currentAssetIdentifier = [[NCAssetHelper shareAssetHelper] getAssetIdentifier:model.asset];
        self.imageRequestID = [[NCAssetHelper shareAssetHelper]
            getAssetDataSizeWithAsset:self.previewPhotosArr[self.currentIndex].asset
                               result:^(CGFloat size) {
                                   if ([self.currentAssetIdentifier
                                           isEqualToString:[[NCAssetHelper shareAssetHelper]
                                                               getAssetIdentifier:model.asset]]) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [self getImageSize:size];
                                       });
                                   }
                               }];
    }
}

- (void)getImageSize:(CGFloat)size {
    NSString *imageSize = nil;
    if (size / 1024 / 1024 < 1) {
        imageSize = [NSString stringWithFormat:@"%dK", (int)size / 1024];
    } else {
        imageSize = [NSString stringWithFormat:@"%0.2fM", size / 1024 / 1024];
    }
    [self.indicatorView stopAnimating];
    self.fullButton.titleLabel.text = [NSString stringWithFormat:@"%@ (%@)", NCUILocalizedString(@"full_image"), imageSize];
    [self.fullButton
        setTitle:[NSString stringWithFormat:@"%@ (%@)", NCUILocalizedString(@"full_image"), imageSize]
        forState:UIControlStateNormal];
}

#pragma mark - Getters and Setters
- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        if ([NCChatUIUtility isRTL]) {
            _indicatorView.frame = CGRectMake(CGRectGetMinX(self.fullButton.frame) - 20 - 6, 18, 20, 20);
        } else {
            _indicatorView.frame = CGRectMake(CGRectGetMaxX(self.fullButton.titleLabel.frame) + 20, 18, 20, 20);
        }
        [self.bottomView addSubview:_indicatorView];
    }
    return _indicatorView;
}

@end
