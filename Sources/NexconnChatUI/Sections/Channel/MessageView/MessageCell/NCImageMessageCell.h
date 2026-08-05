//
//  NCImageMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCImageMessageProgressView.h"
#import "NCMessageCell.h"

/// Image message cell
@interface NCImageMessageCell : NCMessageCell

/// View for displaying the image thumbnail
@property (nonatomic, strong) NCBaseImageView *pictureView;

/// View for displaying the send progress
@property (nonatomic, strong) NCImageMessageProgressView *progressView;

@end
