//
//  NCImageSlideController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import <UIKit/UIKit.h>

@class NCMessageModel;
@class NCImageMessage;

@interface NCImageSlideController : NCBaseViewController

/*!
 Data model for initializing image preview
 */
@property (nonatomic, strong) NCMessageModel *messageModel;

/*!
 Currently previewed image message
 */
@property (nonatomic, strong) NCImageMessage *currentPreviewImage;

/*!
 Whether to preview only the current image; defaults to NO (supports swiping through images in the
 conversation); set YES to preview only the current image
 */
@property (nonatomic, assign) BOOL onlyPreviewCurrentMessage;

/**
 Callback for long-pressing image content

 @param sender Long-press gesture

  To use the SDK's default long-press handling, call [super longPressed:sender].
 */
- (void)longPressed:(id)sender;

@end
