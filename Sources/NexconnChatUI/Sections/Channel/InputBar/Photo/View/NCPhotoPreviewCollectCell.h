//
//  NCPhotoPreviewCollectCell.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCollectionViewCell.h"
@class NCAssetModel;
@interface NCPhotoPreviewCollectCell : NCBaseCollectionViewCell

@property (nonatomic, strong) void (^singleTap)(void);

- (void)configPreviewCellWithItem:(NCAssetModel *)model;

- (void)resetSubviews;
@end
