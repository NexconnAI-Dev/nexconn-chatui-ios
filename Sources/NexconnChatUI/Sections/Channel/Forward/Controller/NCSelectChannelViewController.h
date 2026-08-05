//
//  NCSelectChannelViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCBaseViewController.h"

@interface NCSelectChannelViewController : NCBaseViewController

- (instancetype)initSelectConversationViewControllerCompleted:
    (void (^)(NSArray<NCBaseChannel *> *conversationList))completedBlock;

@end
