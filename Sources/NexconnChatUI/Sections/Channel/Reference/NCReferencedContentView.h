//
//  NCReferencedContentView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCMessageModel.h"
#import "NCBaseImageView.h"
#import "NCBaseLabel.h"
#import "NCAttributedLabel.h"
#define name_and_image_view_space 5
@protocol NCReferencedContentViewDelegate <NSObject>
@optional

- (void)didTapReferencedContentView:(NCMessageModel *)message;

@end
@interface NCReferencedContentView : UIView
/// Left line indicator for the referenced message
@property (nonatomic, strong) UIView *leftLimitLine;

/// Sender name label of the referenced message
@property (nonatomic, strong) NCBaseLabel *nameLabel;

/// Text label for the referenced message content
@property (nonatomic, strong) UILabel *textLabel;

/// Image view for referenced image messages
@property (nonatomic, strong) NCBaseImageView *msgImageView;

@property (nonatomic, weak) id<NCReferencedContentViewDelegate> delegate;

- (void)setMessage:(NCMessageModel *)message contentSize:(CGSize)contentSize;
@end
