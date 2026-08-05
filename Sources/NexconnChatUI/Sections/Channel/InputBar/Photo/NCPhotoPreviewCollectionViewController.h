//
//  NCPhotoPreviewCollectionViewController.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseCollectionViewController.h"
@class NCAssetModel;

@interface NCPhotoPreviewCollectionViewController : NCBaseCollectionViewController

@property (nonatomic, copy) void (^finishPreviewAndBackPhotosPicker)
    (NSMutableArray *selectArr, NSArray *assetPhotos, BOOL isFull);

@property (nonatomic, copy) void (^finishiPreviewAndSendImage)(NSArray *selectArr, BOOL isFull);

@property (nonatomic, assign) BOOL isFull;

+ (instancetype)imagePickerViewController;

- (void)previewPhotosWithSelectArr:(NSMutableArray *)selectedArr
                      allPhotosArr:(NSArray *)allPhotosArr
                      currentIndex:(NSInteger)currentIndex
                  accordToIsSelect:(BOOL)isSelected;
@end
