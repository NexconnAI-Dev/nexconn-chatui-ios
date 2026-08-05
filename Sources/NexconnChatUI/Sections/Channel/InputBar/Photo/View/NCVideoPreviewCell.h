//
//  NCVideoPreviewCell.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCollectionViewCell.h"

@protocol NCVideoPreviewCellDelegate <NSObject>

- (void)sendPlayActionInCell:(UICollectionViewCell *)cell;

@end

@class NCAssetModel;
@class PHAsset;
@interface NCVideoPreviewCell : NCBaseCollectionViewCell

@property (nonatomic, weak) id<NCVideoPreviewCellDelegate> delegate;

- (void)configPreviewCellWithItem:(NCAssetModel *)model;

- (void)play:(PHAsset *)asset;

- (void)stop;

@end
