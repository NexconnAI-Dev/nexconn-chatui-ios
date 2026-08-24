//
//  NCSightSlideViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import <UIKit/UIKit.h>

@class NCMessageModel;

@interface NCSightSlideViewController : NCBaseViewController

/*!
 Data model of the current message.
 */
@property (nonatomic, strong) NCMessageModel *messageModel;

@property (nonatomic, assign) BOOL topRightBtnHidden;

/*!
 Whether to preview only the current video message. The default is NO, which supports swipe preview
 for video messages in the current channel. If set to YES, only the current video message is
 previewed.
*/
@property (nonatomic, assign) BOOL onlyPreviewCurrentMessage;

@end
