//
//  NCTextMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAttributedLabel.h"
#import "NCMessageCell.h"

#define Text_Message_Font_Size 17

/*!
 Text message cell
 */
@interface NCTextMessageCell : NCMessageCell <NCAttributedLabelDelegate>

/*!
 Label for displaying message content
 */
@property (strong, nonatomic) NCAttributedLabel *textLabel;

/*!
 Set the data model of the current message cell

 @param model Data model of the message cell
 */
- (void)setDataModel:(NCMessageModel *)model;

@end
