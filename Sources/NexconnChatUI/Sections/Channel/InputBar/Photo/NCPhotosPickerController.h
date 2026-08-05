//
//  NCPhotosPickerController.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAssetHelper.h"
#import "NCBaseCollectionViewController.h"
@class NCAssetModel;
@interface NCPhotosPickerController : NCBaseCollectionViewController
@property (nonatomic, strong) NSMutableArray<NCAssetModel *> *assetArray;
@property (nonatomic, assign) long count;
@property (nonatomic, strong) id currentAsset;
@property (nonatomic, copy) void (^sendPhotosBlock)(NSArray *photos, BOOL isFull);

+ (instancetype)imagePickerViewController;
@end
