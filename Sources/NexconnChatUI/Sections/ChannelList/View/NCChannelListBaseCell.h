//
//  NCChannelListBaseCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelModel.h"
#import <UIKit/UIKit.h>
#import "NCBaseTableViewCell.h"
/// Base class for channel cells.
@interface NCChannelListBaseCell : NCBaseTableViewCell

/// Data model for the channel cell.
@property (nonatomic, strong) NCChannelModel *model;

/*!
 Set the data model of the conversation cell

 @param model Data model of the conversation cell
 */
- (void)setDataModel:(NCChannelModel *)model;

@end
