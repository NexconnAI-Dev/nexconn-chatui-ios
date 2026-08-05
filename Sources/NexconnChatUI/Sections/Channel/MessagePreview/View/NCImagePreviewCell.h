//
//  NCImagePreviewCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCollectionViewCell.h"

@class NCMessageModel, NCImagePreviewCell;
@protocol NCImagePreviewCellDelegate <NSObject>

- (void)imagePreviewCellDidSingleTap:(NCImagePreviewCell *)cell;

- (void)imagePreviewCellDidLongTap:(UILongPressGestureRecognizer *)sender;

@end

@interface NCImagePreviewCell : NCBaseCollectionViewCell

@property (nonatomic, weak)  id<NCImagePreviewCellDelegate> delegate;

@property (nonatomic, strong) NCMessageModel *messageModel;

- (void)configPreviewCellWithItem:(NCMessageModel *)model;

- (void)resetSubviews;

@end

