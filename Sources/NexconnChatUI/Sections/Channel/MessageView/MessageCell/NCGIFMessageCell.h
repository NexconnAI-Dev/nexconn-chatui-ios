//
//  NCGIFMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGIFImageView.h"
#import "NCImageMessageProgressView.h"
#import "NCMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCGIFMessageCell : NCMessageCell

/// View for displaying the image thumbnail
@property (nonatomic, strong) NCGIFImageView *gifImageView;

/// View for displaying the send progress
@property (nonatomic, strong) NCImageMessageProgressView *progressView;

@end

NS_ASSUME_NONNULL_END
