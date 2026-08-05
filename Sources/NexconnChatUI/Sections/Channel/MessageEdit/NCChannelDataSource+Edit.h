//
//  NCChannelDataSource+Edit.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelDataSource.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCChannelDataSource (Edit)

/// Updates referenced message edit statuses, including recalled or deleted states.
- (void)edit_setUIReferenceMessagesEditStatus:(NCReferenceMessageStatus)status
                        forMessageIds:(NSArray<NSString *> *)messageIds;

/// Refreshes the edited status for messages.
- (void)edit_refreshUIMessagesEditedStatus:(NSArray<NCMessageModel *> *)models;

@end

NS_ASSUME_NONNULL_END
