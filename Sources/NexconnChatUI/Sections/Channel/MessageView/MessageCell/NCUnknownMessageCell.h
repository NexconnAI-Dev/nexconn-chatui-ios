//
//  NCUnknownMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageBaseCell.h"

/// Unknown message cell
@interface NCUnknownMessageCell : NCMessageBaseCell

/// Label for displaying the message
@property (strong, nonatomic) NCTipLabel *messageLabel;

/*!
 Set the data model of the current message cell

 @param model Data model of the message cell
 */
- (void)setDataModel:(NCMessageModel *)model;

@end
