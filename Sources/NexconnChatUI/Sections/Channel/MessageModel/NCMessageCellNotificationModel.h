//
//  NCMessageCellNotificationModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>

// Status names that trigger message cell updates
UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_BEGIN;
UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_FAILED;
UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_SUCCESS;
UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_CANCELED;
UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_PROGRESS;
UIKIT_EXTERN NSString *const CONVERSATION_CELL_DATA_IMAGE_KEY_UPDATE;

UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_READ_RECEIPT_INFO; // Read receipt info

#import <Foundation/Foundation.h>

/// Data model for message cell status update notifications
@interface NCMessageCellNotificationModel : NSObject

/// Message ID
@property (nonatomic) long clientId;

/// Name of the updated status
@property (strong, nonatomic) NSString *actionName;

/// Progress value
@property (nonatomic) NSInteger progress;

/// Read receipt info
@property (nonatomic, strong) NCMessageReadReceiptInfo *readReceiptInfo;

@end
