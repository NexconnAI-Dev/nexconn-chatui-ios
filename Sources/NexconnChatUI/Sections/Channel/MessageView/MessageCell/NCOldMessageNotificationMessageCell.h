//
//  NCOldMessageNotificationMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageBaseCell.h"
#import <Foundation/Foundation.h>

@interface NCOldMessageNotificationMessageCell : NCMessageBaseCell

/// The label that displays the tip message.
@property (strong, nonatomic) NCTipLabel *tipMessageLabel;

@end
