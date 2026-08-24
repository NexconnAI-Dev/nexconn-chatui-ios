//
//  NCPhotoPreviewCollectCell.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPhotoPreviewCollectCell.h"
#import "NCAssetHelper.h"
#import "NCAssetModel.h"
#import "NCBaseScrollView.h"
#import "NCGIFImage.h"
#import "NCGIFImageView.h"
#import <MobileCoreServices/UTCoreTypes.h>
@interface NCPhotoPreviewCollectCell () <UIScrollViewDelegate>
@property (nonatomic, strong) NCBaseScrollView *scrollView;
@property (nonatomic, strong) NCGIFImageView *previewImageView;
@property (nonatomic, assign) int32_t imageRequestID;
@property (nonatomic, strong) NCAssetModel *model;
@property (nonatomic, copy) NSString *representedAssetIdentifier;
@end
#define ImageMaximumZoomScale 2.0
@implementation NCPhotoPreviewCollectCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self creatPreviewCollectionCell];
    }
    return self;
}

#pragma mark - Public Methods

- (void)configPreviewCellWithItem:(NCAssetModel *)model {
    self.model = model;
    self.representedAssetIdentifier =
        [[NCAssetHelper shareAssetHelper] getAssetIdentifier:model.asset];
    if (self.imageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
    }
    [self.scrollView setZoomScale:1.0];
    self.previewImageView.image = nil;
    if ([self showGifImageView]) {
        return;
    }
    [[NCAssetHelper shareAssetHelper]
        getPreviewWithAsset:model.asset
                     result:^(UIImage *photo, NSDictionary *info) {
                       if (![self.representedAssetIdentifier
                               isEqualToString:[[NCAssetHelper shareAssetHelper]
                                                   getAssetIdentifier:model.asset]]) {
                           return;
                       }
                       if (!photo) {
                           return;
                       }
                       dispatch_async(dispatch_get_main_queue(), ^{
                         self.previewImageView.image = photo;
                         [self resizeSubviews];
                       });
                     }];
}

- (void)resetSubviews {
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self resizeSubviews];
}

- (BOOL)showGifImageView {
    if ([[self.model.asset valueForKey:@"uniformTypeIdentifier"]
            isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
        [[NCAssetHelper shareAssetHelper]
            getOriginImageDataWithAsset:self.model
                                 result:^(NSData *imageData, NSDictionary *info,
                                          NCAssetModel *assetModel) {
                                   if (!imageData) {
                                       return;
                                   }
                                   NCGIFImage *gifImage =
                                       [NCGIFImage animatedImageWithGIFData:imageData];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                     self.previewImageView.animatedImage = gifImage;
                                     [self resetSubviews];
                                   });
                                 }
                        progressHandler:^(double progress, NSError *_Nonnull error,
                                          BOOL *_Nonnull stop, NSDictionary *_Nonnull info){

                        }];
        return YES;
    }
    return NO;
}

#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.previewImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setImageCenter:scrollView];
}

#pragma mark - Private Methods
- (void)creatPreviewCollectionCell {
    _scrollView = [[NCBaseScrollView alloc] initWithFrame:self.bounds];
    _scrollView.maximumZoomScale = ImageMaximumZoomScale;
    _scrollView.minimumZoomScale = 1.0;
    _scrollView.multipleTouchEnabled = YES;
    _scrollView.delegate = self;
    _scrollView.scrollsToTop = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.delaysContentTouches = NO;
    [self.contentView addSubview:_scrollView];

    _previewImageView = [[NCGIFImageView alloc] initWithFrame:CGRectZero];
    _previewImageView.clipsToBounds = YES;
    _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.scrollView addSubview:_previewImageView];

    UITapGestureRecognizer *singleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];

    UITapGestureRecognizer *doubleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired = 2;

    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.contentView addGestureRecognizer:singleTap];
    [self.contentView addGestureRecognizer:doubleTap];
}

- (void)singleTap:(UITapGestureRecognizer *)sender {
    self.singleTap();
}

- (void)doubleTap:(UITapGestureRecognizer *)sender {
    if (self.model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
        return;
    }
    if (self.scrollView.zoomScale > 1.0f) {
        [self.scrollView setZoomScale:1.0 animated:YES];
    } else {
        CGPoint touchPoint = [sender locationInView:self.previewImageView];
        CGFloat newZoomScale = self.scrollView.maximumZoomScale;
        CGFloat xsize = self.frame.size.width / newZoomScale;
        CGFloat ysize = self.frame.size.height / newZoomScale;
        [self.scrollView
            zoomToRect:CGRectMake(touchPoint.x - xsize / 2, touchPoint.y - ysize / 2, xsize, ysize)
              animated:YES];
    }
}

- (void)resizeSubviews {
    UIImage *image = self.previewImageView.image;
    if (image) {
        CGRect frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        CGFloat imageWidth = image.size.width;
        CGFloat imageHeight = image.size.height;
        CGFloat scrollViewWidth = self.scrollView.frame.size.width;
        CGFloat scrollViewHeight = self.scrollView.frame.size.height;
        CGPoint center = CGPointMake(scrollViewWidth / 2, scrollViewHeight / 2);

        if (imageHeight / imageWidth > scrollViewHeight / scrollViewWidth) {
            frame.size.height = floor(imageHeight / (imageWidth / scrollViewWidth));
            center.y = frame.size.height / 2;
        } else {
            CGFloat height = imageHeight / imageWidth * scrollViewWidth;
            if (height < 1 || isnan(height))
                height = scrollViewHeight;
            height = floor(height);
            frame.size.height = height;
        }

        self.previewImageView.frame = frame;
        self.previewImageView.center = center;
        self.scrollView.contentSize =
            CGSizeMake(self.frame.size.width,
                       MAX(self.frame.size.height, self.previewImageView.frame.size.height));
        [self.scrollView scrollRectToVisible:self.bounds animated:NO];
        self.scrollView.alwaysBounceVertical =
            self.previewImageView.frame.size.height > scrollViewHeight;
        // If the default maximum zoom still cannot fill the screen vertically, raise it to the
        // ratio required to fill the screen.
        self.scrollView.maximumZoomScale =
            frame.size.height * ImageMaximumZoomScale < scrollViewHeight
                ? (scrollViewHeight / frame.size.height)
                : ImageMaximumZoomScale;
    }
}

- (void)setImageCenter:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.frame.size.width > scrollView.contentSize.width)
                          ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5
                          : 0.0;
    CGFloat offsetY = (scrollView.frame.size.height > scrollView.contentSize.height)
                          ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5
                          : 0.0;
    self.previewImageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                               scrollView.contentSize.height * 0.5 + offsetY);
}
@end
