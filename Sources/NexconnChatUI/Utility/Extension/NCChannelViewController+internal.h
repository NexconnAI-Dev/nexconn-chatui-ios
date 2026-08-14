//
//  NCChannelViewController+internal.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NCChannelViewController_internal_h
#define NCChannelViewController_internal_h
#import "NCChannelViewController.h"

@class NCChannelCollectionViewHeader;
@class NCChannelVCUtil;

@interface NCChannelViewController ()
@property (nonatomic, strong, readonly) NCChannelVCUtil *util;
@property (nonatomic, strong, readonly) NCChannelCollectionViewHeader *collectionViewHeader;
@property (nonatomic, assign, readonly) BOOL isConversationAppear;
@property (nonatomic, assign) BOOL sendMsgAndNeedScrollToBottom;
@property (nonatomic, assign) BOOL isTouchScrolled;

- (void)updateUnreadMsgCountLabel;
- (void)updateForMessageSendSuccess:(NCMessage *)message;
- (void)setupUnReadMessageView;
- (BOOL)shouldMarkMessagesAsRead;
@end

#endif /* NCChannelViewController_internal_h */
