//
//  NCAssetModel.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <UIKit/UIKit.h>

@interface NCAssetModel : NSObject

@property (nonatomic, strong) id asset;
/**
 *   Thumbnail image. Assigned only when selected, ensuring at most 9 instances keep thumbnails in
 * memory.
 */
@property (nonatomic, strong) UIImage *thumbnailImage;

/**
 *   Original image size.
 */
@property (nonatomic, assign) CGFloat imageSize;

@property (nonatomic, assign) BOOL isSelect;

@property (nonatomic, assign) NSInteger index;

/**
 Asset type.
 */
@property (nonatomic, assign, readonly) PHAssetMediaType mediaType;

// If self is a video asset and avAsset is nil, the video data could not be loaded from local
// storage or iCloud.
@property (nonatomic, strong) AVAsset *avAsset;

/**
 Asset duration in seconds.
 */
@property (nonatomic, assign) NSTimeInterval duration;

@property (nonatomic, copy, readonly) NSString *durationText;

/// YES when loading the thumbnail also tries to fetch the full-size image, but it is unavailable
/// locally and the iCloud download fails.
@property (nonatomic, assign) BOOL isDownloadFailFromiCloud;

// Returns YES if this is a video asset and avAsset contains invalid data; otherwise returns NO.
- (BOOL)isVideoAssetInvalid;

// To improve performance with large albums, thumbnails are not stored by default; selected photos
// or videos need to keep them.
- (void)fetchThumbnailImage;

+ (NCAssetModel *)modelWithAsset:(id)asset;
@end
