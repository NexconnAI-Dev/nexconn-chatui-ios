//
//  NCGIFPreviewViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCGIFImageView.h"
#import "NCMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCGIFPreviewViewController : NCBaseViewController

/// Data model of the message.
@property (nonatomic, strong) NCMessageModel *messageModel;

@end

NS_ASSUME_NONNULL_END
