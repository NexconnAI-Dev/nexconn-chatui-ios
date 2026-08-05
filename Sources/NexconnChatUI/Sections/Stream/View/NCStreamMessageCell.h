//
//  NCStreamMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageCell.h"
#import "NCReferencedContentView.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const NCStreamMessageCellUpdateEndNotification;

@interface NCStreamMessageCell : NCMessageCell

@property (nonatomic, weak) UICollectionView *hostView;

/// Container view for referenced content
@property (nonatomic, strong) NCReferencedContentView *referencedContentView;

@end

NS_ASSUME_NONNULL_END
