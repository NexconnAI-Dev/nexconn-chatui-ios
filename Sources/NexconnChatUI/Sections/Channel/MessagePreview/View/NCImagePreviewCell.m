//
//  NCImagePreviewCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCImagePreviewCell.h"
#import "NCBaseScrollView.h"
#import "NCChatUICommonDefine.h"
#import "NCImageMessageProgressView.h"
#import "NCImageView.h"
#import "NCMessageModel.h"
@interface NCImagePreviewCell () <UIScrollViewDelegate, NCImageViewDelegate>
@property (nonatomic, strong) NCBaseScrollView *scrollView;
@property (nonatomic, strong) NCImageView *previewImageView;
@property (nonatomic, strong) NCImageMessageProgressView *progressView;
@property (nonatomic, strong) UILabel *labFailed;
@property (nonatomic, strong) UIImageView *imgFailed;
@end

@implementation NCImagePreviewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self creatPreviewCollectionCell];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.scrollView.frame = self.bounds;
    [self resetSubviews];
    [self.scrollView setContentSize:CGSizeMake(self.previewImageView.frame.size.width,
                                               self.previewImageView.frame.size.height)];
    [self.progressView
        setCenter:CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2)];
}

#pragma mark - Public Methods

- (void)configPreviewCellWithItem:(NCMessageModel *)model {
    self.labFailed.text = nil;
    self.imgFailed.image = nil;
    self.messageModel = model;
    [self.scrollView setZoomScale:1.0];
    [self.progressView
        setCenter:CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2)];
    NCImageMessage *imageContent = (NCImageMessage *)model.content;
    self.previewImageView.placeholderImage = imageContent.thumbnailImage;
    if (imageContent.localPath.length > 0 &&
        [[NSFileManager defaultManager] fileExistsAtPath:imageContent.localPath]) {
        [self.previewImageView setImageURL:[NSURL URLWithString:imageContent.localPath]];
        [self resizeSubviews];
    } else {
        if ([imageContent.remoteUrl hasPrefix:@"http"]) {
            // Check whether the image is already loaded.
            if ([[NCImageLoader sharedImageLoader]
                    hasLoadedImageURL:[NSURL URLWithString:imageContent.remoteUrl]]) {
                [self.previewImageView setImageURL:[NSURL URLWithString:imageContent.remoteUrl]];
            } else {
                self.previewImageView.delegate = self;
                [self.previewImageView setImageURL:[NSURL URLWithString:imageContent.remoteUrl]];
                self.progressView.hidden = NO;
                [self.progressView startAnimating];
            }
        } else {
            [self.previewImageView setImageURL:[NSURL URLWithString:imageContent.remoteUrl]];
        }
    }
}

- (void)resetSubviews {
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self resizeSubviews];
}

#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.previewImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setImageCenter:scrollView];
}

#pragma mark -  NCImageViewDelegate

- (void)imageViewLoadedImage:(NCImageView *)imageView {
    // Remove the loading indicator after the image loads successfully.
    if (!self.progressView.hidden) {
        [self.progressView stopAnimating];
        self.progressView.hidden = YES;
    }
    [self resizeSubviews];
    [self.scrollView
        setContentSize:CGSizeMake(imageView.frame.size.width, imageView.frame.size.height)];
}

- (void)imageViewFailedToLoadImage:(NCImageView *)imageView error:(NSError *)error {
    [NSTimer scheduledTimerWithTimeInterval:60.0
                                     target:self
                                   selector:@selector(action:)
                                   userInfo:imageView
                                    repeats:NO];
}

#pragma mark - target action

- (void)singleTap:(UITapGestureRecognizer *)sender {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(imagePreviewCellDidSingleTap:)]) {
        [self.delegate imagePreviewCellDidSingleTap:self];
    }
}

- (void)doubleTap:(UITapGestureRecognizer *)sender {
    if (self.scrollView.contentSize.width > self.frame.size.width) {
        [self.scrollView setZoomScale:1.0 animated:YES];
    } else {
        CGPoint touchPoint = [sender locationInView:self.scrollView];
        CGFloat newZoomScale = self.scrollView.maximumZoomScale;
        CGFloat xsize = self.frame.size.width / newZoomScale;
        CGFloat ysize = self.frame.size.height / newZoomScale;
        [self.scrollView
            zoomToRect:CGRectMake(touchPoint.x - xsize / 2, touchPoint.y - ysize / 2, xsize, ysize)
              animated:YES];
    }
}

- (void)longPressed:(UILongPressGestureRecognizer *)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(imagePreviewCellDidLongTap:)]) {
            [self.delegate imagePreviewCellDidLongTap:sender];
        }
    }
}

- (UILabel *)labFailed {
    if (!_labFailed) {
        UILabel *failLabel = [[UILabel alloc] init];
        failLabel.textAlignment = NSTextAlignmentCenter;
        failLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _labFailed = failLabel;
    }
    return _labFailed;
}

- (UIImageView *)imgFailed {
    if (!_imgFailed) {
        _imgFailed = [UIImageView new];
    }
    return _imgFailed;
}

- (void)action:(NSTimer *)scheduledTimer {
    self.previewImageView.image = nil;
    NCImageMessage *message = (NCImageMessage *)self.messageModel.content;
    NSString *imageUrl = message.remoteUrl;
    if (!self.progressView.hidden) {
        [self.progressView stopAnimating];
        [self.progressView setHidden:YES];
    }
    if ([imageUrl hasPrefix:@"http"]) {
        self.imgFailed.image = NCDynamicImage(@"channel_msg_cell_image_broken_img");
        self.imgFailed.frame = CGRectMake(0, 0, 81, 60);
        self.imgFailed.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        self.labFailed.frame =
            CGRectMake(self.frame.size.width / 2 - 75, self.frame.size.height / 2 + 44, 150, 30);
        self.labFailed.text = NCUILocalizedString(@"image_load_failed");
    } else {
        self.imgFailed.image = NCDynamicImage(@"image_preview_exclamation_img");
        self.imgFailed.frame = CGRectMake(0, 0, 71, 71);
        self.imgFailed.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        self.labFailed.frame =
            CGRectMake(self.frame.size.width / 2 - 75, self.frame.size.height / 2 + 49.5, 150, 30);
        self.labFailed.text = NCUILocalizedString(@"image_has_been_deleted");
    }
}

#pragma mark - layout
- (void)creatPreviewCollectionCell {
    [self.contentView addSubview:self.labFailed];
    [self.contentView addSubview:self.imgFailed];

    [self.contentView addSubview:self.scrollView];
    [self.scrollView addSubview:self.previewImageView];

    UITapGestureRecognizer *singleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];

    UITapGestureRecognizer *doubleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired = 2;

    // A long press lets the user choose whether to save the image.
    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];

    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.contentView addGestureRecognizer:singleTap];
    [self.contentView addGestureRecognizer:doubleTap];
    [self.contentView addGestureRecognizer:longPress];
}

- (void)resizeSubviews {
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    UIImage *image = self.previewImageView.image;
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    if (imageWidth <= 0) {
        imageWidth = 1;
    }
    if (imageHeight <= 0) {
        imageHeight = 1;
    }
    CGPoint viewCenter = CGPointMake(width / 2, height / 2);
    if (width < height) {
        if (imageWidth < width) {
            /*
             When both dimensions fit, scale the width to the viewport while preserving the aspect
             ratio and center the image. When the image is taller than the viewport, keep its
             original size, center it horizontally, and align it to the top.
             */
            if (imageHeight < height) {
                CGFloat scale = imageHeight / imageWidth;
                imageWidth = width;
                imageHeight = width * scale;
                [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
                self.previewImageView.center = viewCenter;
            } else {
                [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
                self.previewImageView.center = CGPointMake(width / 2, imageHeight / 2);
            }
        } else {
            /*
             Scale the image width to the viewport while preserving the aspect ratio.
             Center it vertically when the scaled height fits; otherwise keep it aligned to the top.
             */
            CGFloat scale = imageHeight / imageWidth;
            imageWidth = width;
            imageHeight = width * scale;
            [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            if (imageHeight < height) {
                self.previewImageView.center = viewCenter;
            }
        }
    } else {

        /*
         Landscape layout always preserves the image's aspect ratio:
         1. For ratios below 0.45, retain the original size when it fits; otherwise scale the width
         to the viewport. Align tall images to the top.
         2. For ratios from 0.45 up to 1.7, scale the height to the viewport and center the image.
         3. For ratios of 1.7 or greater, scale the width to the viewport and center the image when
         its height fits.
         */
        if (imageWidth / imageHeight < 0.45) {
            if (imageWidth < width) {
                [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            } else {
                CGFloat scale = imageHeight / imageWidth;
                imageWidth = width;
                imageHeight = width * scale;
                [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            }
            if (imageHeight > height) {
                self.previewImageView.center = CGPointMake(width / 2, imageHeight / 2);
            } else {
                self.previewImageView.center = viewCenter;
            }
        } else if (imageWidth / imageHeight < 1.7) {
            CGFloat scale = imageWidth / imageHeight;
            imageWidth = height * scale;
            imageHeight = height;
            [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            self.previewImageView.center = viewCenter;
        } else {
            CGFloat scale = imageHeight / imageWidth;
            imageWidth = width;
            imageHeight = width * scale;
            [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            if (imageHeight > height) {
                self.previewImageView.center = CGPointMake(width / 2, imageHeight / 2);
            } else {
                self.previewImageView.center = viewCenter;
            }
        }
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

#pragma mark - Getter

- (NCBaseScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[NCBaseScrollView alloc] initWithFrame:self.bounds];
        _scrollView.minimumZoomScale = 1.0;
        _scrollView.maximumZoomScale = 4.0;
        [_scrollView setZoomScale:1.0];
        _scrollView.multipleTouchEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.delaysContentTouches = NO;
    }
    return _scrollView;
}

- (NCImageView *)previewImageView {
    if (!_previewImageView) {
        _previewImageView = [[NCImageView alloc] initWithFrame:CGRectZero];
        _previewImageView.clipsToBounds = YES;
        _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _previewImageView;
}

- (NCImageMessageProgressView *)progressView {
    if (!_progressView) {
        _progressView =
            [[NCImageMessageProgressView alloc] initWithFrame:CGRectMake(0, 0, 135, 135)];
        _progressView.label.hidden = YES;
        _progressView.indicatorView.color = NCDynamicColor(@"pop_layer_background_color");
        _progressView.backgroundColor = [UIColor clearColor];
        [_progressView
            setCenter:CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2)];
        _progressView.userInteractionEnabled = NO;
        _progressView.indicatorView.userInteractionEnabled = NO;
        [self.contentView addSubview:_progressView];
    }
    return _progressView;
}
@end
