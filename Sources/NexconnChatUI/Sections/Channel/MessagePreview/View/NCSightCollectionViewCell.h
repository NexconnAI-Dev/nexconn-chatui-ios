//
//  NCSightCollectionViewCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCollectionViewCell.h"
@class NCSightModel;

@protocol NCSightCollectionViewCellDelegate <NSObject>
@optional
- (void)closeSight;

- (void)playEnd;

- (void)sightLongPressed:(NSString *)localPath;

@end

@interface NCSightCollectionViewCell : NCBaseCollectionViewCell

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, weak) id<NCSightCollectionViewCellDelegate> delegate;

@property (nonatomic, assign, getter=isAutoPlay) BOOL autoPlay;

- (void)setDataModel:(NCSightModel *)model;

- (void)stopPlay;

- (void)resetPlay;

@end
