//
//  NCSightMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NexconnChatUI.h"

@class NCSightMessageProgressView;
@interface NCSightMessageCell : NCMessageCell

/// The view that displays the sight message thumbnail.
@property (nonatomic, strong) NCBaseImageView *thumbnailView;

/// The view that displays the send progress.
@property (nonatomic, strong) NCSightMessageProgressView *progressView;

@end
