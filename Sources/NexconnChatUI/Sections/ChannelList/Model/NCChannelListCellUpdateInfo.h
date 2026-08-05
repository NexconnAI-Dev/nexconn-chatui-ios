//
//  NCChannelListCellUpdateInfo.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelModel.h"
#import <Foundation/Foundation.h>

UIKIT_EXTERN NSString *const NCChatUIChannelListCellUpdateNotification;

typedef NS_ENUM(NSUInteger, NCChannelListCellUpdateType) {
    NCChannelListCellMessageContentUpdate = 1,
    NCChannelListCellSentStatusUpdate = 2,
    NCChannelListCellReceivedStatusUpdate = 3,
    NCChannelListCellUnreadCountUpdate = 4,
};

@interface NCChannelListCellUpdateInfo : NSObject

@property (nonatomic, strong) NCChannelModel *model;
@property (nonatomic, assign) NCChannelListCellUpdateType updateType;

@end
