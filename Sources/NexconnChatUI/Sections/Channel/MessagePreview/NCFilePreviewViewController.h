//
//  NCFilePreviewViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCMessageModel.h"

@interface NCFilePreviewViewController : NCBaseViewController

/// Data model of the current file message.
@property (nonatomic, strong) NCMessageModel *messageModel;

/*!
 Opens the file with another app. Apps can override this for customization.

 - Parameter localPath: Local path of the file.
 */
- (void)openInOtherApp:(NSString *)localPath;

@end
