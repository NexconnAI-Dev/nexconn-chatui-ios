//
//  NCFileMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageCell.h"
#import <UIKit/UIKit.h>
#import "NCProgressView.h"
/// File message cell
@interface NCFileMessageCell : NCMessageCell

/// Label displaying the file name
@property (strong, nonatomic) UILabel *nameLabel;

/// Label displaying the file size
@property (strong, nonatomic) UILabel *sizeLabel;

/// Image view for the file type icon
@property (strong, nonatomic) NCBaseImageView *typeIconView;

/// Progress view for upload or download
@property (nonatomic, strong) NCProgressView *progressView;

/// Cancel send button
@property (nonatomic, strong) NCBaseButton *cancelSendButton;

/// Label displaying "Cancelled"
@property (nonatomic, strong) UILabel *cancelLabel;

@end
