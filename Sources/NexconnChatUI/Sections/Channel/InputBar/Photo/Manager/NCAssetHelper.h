//
//  NCAssetHelper.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <UIKit/UIKit.h>

#define ShareNCAssetHelper [NCAssetHelper shareAssetHelper]

NS_ASSUME_NONNULL_BEGIN

@class NCAssetModel;
@interface NCAssetHelper : NSObject <PHPhotoLibraryChangeObserver>

/**
 *  return a instance
 *
 *  - Returns: return value description
 */
+ (instancetype)shareAssetHelper;

/**
 *  Get photo library authorization status.
 */
- (BOOL)hasAuthorizationStatusAuthorized;

/**
 *  Get all photos in the group.
 *
 *  - Parameter alGroup: Group to operate on.
 *  - Parameter results: Result callback.
 */
- (void)getPhotosOfGroup:(id)alGroup results:(void (^)(NSArray<NCAssetModel *> *photos))results;

/**
 *  Get album or album list.
 */
- (void)getAlbumsFromSystem:(void (^)(NSArray *assetGroup))result;
/**
 *  Get the image thumbnail.
 *
 *  - Parameter asset: Image asset.
 */
- (void)getThumbnailWithAsset:(id)asset
                         size:(CGSize)size
                       result:(void (^)(UIImage *thumbnailImage))resultBlock;
/**
 *  Get the image preview.
 *
 *  - Parameter asset: Image asset.
 */
- (void)getPreviewWithAsset:(id)asset
                     result:(void (^)(UIImage *photo, NSDictionary *info))resultBlock;

/**
 *  Get the video.
 *
 *  - Parameter asset: Photo asset.
 */
- (PHImageRequestID)getOriginVideoWithAsset:(id)asset
                                     result:(void (^)(AVAsset *avAsset, NSDictionary *info,
                                                      NSString *imageIdentifier))resultBlock
                            progressHandler:(void (^)(double progress, NSError *error, BOOL *stop,
                                                      NSDictionary *info))progressHandler;

/**
 *  Get original image data.
 *
 *  - Parameter assetModel: Image asset.
 *   If the original image cannot be loaded locally, it will be downloaded from iCloud. If the
 * iCloud download also fails, photo is nil.
 */
- (PHImageRequestID)getOriginImageDataWithAsset:(NCAssetModel *)assetModel
                                         result:(void (^)(NSData *photo, NSDictionary *info,
                                                          NCAssetModel *assetModel))resultBlock
                                progressHandler:(void (^)(double progress, NSError *error,
                                                          BOOL *stop,
                                                          NSDictionary *info))progressHandler;

/**
 *  Get the image size.
 *
 *  - Parameter asset: Image asset.
 */
- (PHImageRequestID)getAssetDataSizeWithAsset:(id)asset result:(void (^)(CGFloat size))resultBlock;

/**
 *  Get the cached album list.
 *
 */
- (NSArray *)getCachePhotoGroups;

/**
 *  Get the image identifier.
 *
 */
- (NSString *)getAssetIdentifier:(id)asset;

/**
 *  Save an image to the album. Both PNG and JPG are supported.
 *
 */
+ (void)savePhotosAlbumWithImage:(UIImage *)image
        authorizationStatusBlock:(nullable dispatch_block_t)authorizationStatusBlock
                     resultBlock:(nullable void (^)(BOOL success))resultBlock;

/**
 *  Save a GIF to the album.
 *
 */
+ (void)savePhotosAlbumWithPath:(NSString *)localPath
       authorizationStatusBlock:(nullable dispatch_block_t)authorizationStatusBlock
                    resultBlock:(nullable void (^)(BOOL success))resultBlock;

/**
 *  Save a video to the album.
 *
 */
+ (void)savePhotosAlbumWithVideoPath:(NSString *)videoPath
            authorizationStatusBlock:(nullable dispatch_block_t)authorizationStatusBlock
                         resultBlock:(nullable void (^)(BOOL success))resultBlock;

@end

NS_ASSUME_NONNULL_END
