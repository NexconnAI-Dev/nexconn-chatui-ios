//
//  NCComplexTextMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const NCComplexTextMessageCellIdentifier;

/// Cell for asynchronous rendering of complex text
@interface NCComplexTextMessageCell : NCMessageCell

/// attributeDictionary
@property (nonatomic, strong) NSDictionary *attributeDictionary;

/*!
 Set the data model of the current message cell

 @param model Data model of the message cell
 */
- (void)setDataModel:(NCMessageModel *)model;

@end

NS_ASSUME_NONNULL_END
