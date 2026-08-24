//
//  NCAssetModel.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAssetModel.h"
#import "NCAssetHelper.h"
#import "NCChatUICommonDefine.h"

#define WIDTH ([UIScreen mainScreen].bounds.size.width - 20) / 4
#define SIZE CGSizeMake(WIDTH, WIDTH)

@interface NCAssetModel ()
@property (nonatomic, assign) int32_t imageRequestID;
@property (nonatomic, copy) NSString *durationText;

@end
@implementation NCAssetModel
+ (NCAssetModel *)modelWithAsset:(id)asset {
    NCAssetModel *model = [[NCAssetModel alloc] init];
    model.asset = asset;
    return model;
}

- (CGFloat)imageSize {
    if (!_imageSize) {
        [[NCAssetHelper shareAssetHelper]
            getAssetDataSizeWithAsset:self.asset
                               result:^(CGFloat size) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                   _imageSize = size;
                                 });
                               }];
    }
    return _imageSize;
}

- (void)setValue:(id)value forKey:(NSString *)key {
}

- (PHImageRequestID)fetchOriginData {
    // Cancel any existing full-size asset request before restarting it; PhotoKit can continue from
    // previously fetched data.
    if (self.imageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
        self.imageRequestID = 0;
    }
    if (self.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
        return [[NCAssetHelper shareAssetHelper]
            getOriginVideoWithAsset:self.asset
                             result:^(AVAsset *avAsset, NSDictionary *info,
                                      NSString *imageIdentifier) {
                               if (![[[NCAssetHelper shareAssetHelper]
                                       getAssetIdentifier:self.asset]
                                       isEqualToString:imageIdentifier]) {
                                   return;
                               }
                               BOOL downloadFinined =
                                   (![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                    ![info objectForKey:PHImageErrorKey] &&
                                    ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                               if (downloadFinined) {
                                   self.avAsset = avAsset;
                               }
                             }
                    progressHandler:^(double progress, NSError *_Nonnull error, BOOL *_Nonnull stop,
                                      NSDictionary *_Nonnull info){
                    }];
    } else {
        return [[NCAssetHelper shareAssetHelper]
            getOriginImageDataWithAsset:self
                                 result:^(NSData *imageData, NSDictionary *info,
                                          NCAssetModel *assetModel) {
                                   if (!imageData) {
                                       return;
                                   }
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                     BOOL downloadFinined =
                                         (![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                          ![info objectForKey:PHImageErrorKey] &&
                                          ![[info objectForKey:PHImageResultIsDegradedKey]
                                              boolValue]);
                                     if (downloadFinined) {
                                         self.asset = assetModel.asset;
                                     }
                                   });
                                 }
                        progressHandler:^(double progress, NSError *_Nonnull error,
                                          BOOL *_Nonnull stop, NSDictionary *_Nonnull info){

                        }];
    }
}

- (void)setIsSelect:(BOOL)isSelect {
    _isSelect = isSelect;
    if (isSelect) {
        // Prefetch the full-size asset after selection.
        self.imageRequestID = [self fetchOriginData];
    } else {
        // Cancel the full-size asset request after deselection.
        if (self.imageRequestID) {
            [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
            self.imageRequestID = 0;
        }
    }
}

- (BOOL)isVideoAssetInvalid {
    if (self.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
        if (self.avAsset) {
            return NO;
        } else {
            return YES;
        }
    }
    return NO;
}

- (void)fetchThumbnailImage {
    [[NCAssetHelper shareAssetHelper]
        getThumbnailWithAsset:self.asset
                         size:CGSizeMake((WIDTH * SCREEN_SCALE), (WIDTH * SCREEN_SCALE))
                       result:^(UIImage *thumbnailImage) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                           _thumbnailImage = thumbnailImage;
                         });
                       }];
}

- (PHAssetMediaType)mediaType {
    return ((PHAsset *)self.asset).mediaType;
}

- (NSTimeInterval)duration {
    if (0 == _duration) {
        _duration = ((PHAsset *)self.asset).duration;
    }
    if (0 == _duration && self.avAsset) {
        _duration = CMTimeGetSeconds(self.avAsset.duration);
    }
    return _duration;
}

- (NSString *)durationText {
    if (!_durationText && self.duration != 0) {
        NSTimeInterval duration = round(self.duration);
        NSTimeInterval fmiutes = duration / 60;
        NSUInteger minutes = fmiutes;
        NSUInteger seconds = round(duration - minutes * 60);
        if (seconds == 60) {
            minutes += 1;
            seconds = 0;
        }
        if (minutes != 0 || seconds != 0) {
            _durationText = [NSString
                stringWithFormat:@"%02lu:%02lu", (unsigned long)minutes, (unsigned long)seconds];
        }
    }
    return _durationText;
}

@end
