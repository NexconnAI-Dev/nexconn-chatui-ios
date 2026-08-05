//
//  NCPhotoPickerCollectCell.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCollectionViewCell.h"
@class NCAssetModel;

@protocol NCPhotoPickerCollectCellDelegate <NSObject>

/**
 *  Callback after the button is tapped.
 *  Returns whether the button state can be changed.
 */
- (BOOL)canChangeSelectedState:(NCAssetModel *)asset;

/**
 *  Callback when downloading from iCloud fails: album data is read first, then iCloud is tried if that fails. This callback is triggered if iCloud also fails.
 *  Mutually exclusive with didChangeSelectedState below.
 */
- (void)downloadFailFromiCloud;

/// Callback after the button selected state changes.
- (void)didChangeSelectedState:(BOOL)selected model:(NCAssetModel *)asset;

- (void)didTapPickerCollectCell:(NCAssetModel *)model;

@end

@interface NCPhotoPickerCollectCell : NCBaseCollectionViewCell


@property (nonatomic, copy) NSString *representedAssetIdentifier;

- (void)configPickerCellWithItem:(NCAssetModel *)model delegate:(id<NCPhotoPickerCollectCellDelegate>)delegate;

@end
