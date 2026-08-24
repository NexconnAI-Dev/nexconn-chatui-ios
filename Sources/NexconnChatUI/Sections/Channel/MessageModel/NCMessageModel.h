//
//  NCMessageModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIUserInfo.h"
#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/*!
 Data model class for message cells
 */
@interface NCMessageModel : NSObject

/*!
 Whether to display the timestamp
 */
@property (nonatomic, assign) BOOL isDisplayMessageTime;

/*!
 Whether to display the username
 */
@property (nonatomic, assign) BOOL isDisplayNickname;

/*!
 User information
 */
@property (nonatomic, strong, nullable) NCChatUIUserInfo *userInfo;

/*!
 Conversation type
 */
@property (nonatomic, assign) NCChannelType channelType;

/*!
 Target conversation ID
 */
@property (nonatomic, copy) NSString *channelId;

/*!
 Message ID
 */
@property (nonatomic, assign) long clientId;

/*!
 Message direction
 */
@property (nonatomic, assign) NCMessageDirection messageDirection;

/*!
 Sender's user ID
 */
@property (nonatomic, copy) NSString *senderUserId;

/// Received status info of the message (applies to received messages only)
@property (nonatomic, strong, nullable) NCMessageReceivedStatusInfo *receivedStatusInfo;

/*!
 Message send status
 */
@property (nonatomic, assign) NCMessageSentStatus sentStatus;

/*!
 Message receive time (Unix timestamp, milliseconds)
 */
@property (nonatomic, assign) long long receivedTime;

/*!
 Message send time (Unix timestamp, milliseconds)
 */
@property (nonatomic, assign) long long sentTime;

/*!
 Message type name
 */
@property (nonatomic, copy) NSString *objectName;

/*!
 Message content
 */
@property (nonatomic, strong) NCMessageContent *content;

/*!
 Whether the message is persisted
 */
@property (nonatomic, assign) BOOL isPersisted;

/*!
 Extra field of the message
 */
@property (nonatomic, copy, nullable) NSString *extra;

/*!
 Cell height for displaying the message

  Optimized for displaying large volumes of messages
 */
@property (nonatomic) CGSize cellSize;
/*!
 Globally unique ID

  Server message unique ID (globally unique within the same AppKey)
 */
@property (nonatomic, copy, nullable) NSString *messageId;

/*!
 Whether the message can contain extension info

  This property is determined at send time and cannot be modified afterward
  Extension info is only supported in private and group chats
*/
@property (nonatomic, assign) BOOL canIncludeExpansion;

/*!
 Message extension info list

  Extension info is only supported in private and group chats
*/
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *expansionDic;
/*!
 Media message upload progress
*/
@property (nonatomic, assign) NSInteger uploadProgress;

/// Whether the message has been edited
@property (nonatomic, assign) BOOL hasChanged;

/// Message update info
@property (nonatomic, strong) NCMessageUpdateInfo *updateInfo;

/// Read receipt operation flag for the message.
///
/// @note Specific to read receipt V5.
@property (nonatomic, assign) BOOL needReceipt;

/// Whether the read receipt has been sent.
///
/// @note Specific to read receipt V5.
@property (nonatomic, assign) BOOL sentReceipt;

/// Read receipt info
@property (nonatomic, strong) NCMessageReadReceiptInfo *readReceiptInfo;

/*!
 Initialize message cell data model

 @param message   NC message entity
 @return Message cell data model object
 */
+ (instancetype)modelWithNCMessage:(NCMessage *)message;

/*!
 Initialize message cell data model

 @param message   NC message entity
 @return Message cell data model object
 */
- (instancetype)initWithNCMessage:(NCMessage *)message;
@end
NS_ASSUME_NONNULL_END
