//
//  NCCollectionViewModelProtocol.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NCCollectionViewModelResponder <NSObject>

@optional

/// reload data
- (void)reloadCollectionViewData;

@end

/// NCCollectionViewModelProtocol
@protocol NCCollectionViewModelProtocol <NSObject>

@optional

/// collectionView section count
- (NSInteger)numberOfSectionsInCollectionView;

/// collectionView section item count
- (NSInteger)numberOfItemsInSection:(NSInteger)section;

/// Returns the cell
///
/// @param collectionView collectionView
/// @param indexPath indexPath
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath;

/// Configures the content insets
///
/// @param collectionView collectionView
/// @param collectionViewLayout collectionViewLayout
/// @param section section
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section;

/// Handles cell tap
///
/// @param collectionView collectionView
/// @param indexPath indexPath
- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
