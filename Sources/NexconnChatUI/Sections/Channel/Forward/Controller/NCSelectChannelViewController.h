//
//  NCSelectChannelViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>

@interface NCSelectChannelViewController : NCBaseViewController

- (instancetype)initSelectConversationViewControllerCompleted:
    (void (^)(NSArray<NCBaseChannel *> *conversationList))completedBlock;

@end
