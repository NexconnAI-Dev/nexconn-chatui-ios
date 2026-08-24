//
//  NCSelectChannelCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseTableViewCell.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>

@interface NCSelectChannelCell : NCBaseTableViewCell

- (void)setConversation:(NCBaseChannel *)conversation ifSelected:(BOOL)ifSelected;

@end
