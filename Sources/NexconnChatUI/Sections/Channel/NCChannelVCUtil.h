//
//  NCChannelVCUtil.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCMessageCellNotificationModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCChatUIErrorCode.h"

@class NCChannelViewController,NCMessageModel,NCEditInputBarConfig,NCInformationNotificationMessage;

@interface NCChannelVCUtil : NSObject
- (instancetype)init:(NCChannelViewController *)chatVC;

#pragma mark - Message Handling
// Performs the actual message sending action on the channel page.
- (void)doSendMessage:(NCMessageContent *)messageContent pushContent:(NSString *)pushContent;
// Dedicated send path without internal burn-after-reading logic.
- (void)doOnlySendMessage:(NCMessageContent *)messageContent pushContent:(NSString *)pushContent;

// Sends selected media messages from the album in batches, including images, videos, and GIFs.
- (void)doSendSelectedMediaMessage:(NSArray *)selectedImages fullImageRequired:(BOOL)full;
// Syncs the unread count.
- (void)syncReadStatus;
- (void)syncReadStatusWithDelay:(BOOL)delay;
// Stops playing the voice message if needed.
- (void)stopVoiceMessageIfNeed:(NCMessageModel *)model;
// Notifies the message cell status.
- (void)sendMessageStatusNotification:(NSString *)actionNametatus clientId:(long)clientId progress:(NSInteger)progress;

- (void)sendMessageReadReceiptNotification:(NCMessageModel *)model;

#pragma mark - UI
// Calculates the extra message height. Default is 14; add 44 when showing time and 16 when showing the name.
- (CGFloat)referenceExtraHeight:(Class)cellClass messageModel:(NCMessageModel *)model;
// Finds the data-source position of the message.
- (NSIndexPath *)findDataIndexFromMessageList:(NCMessageModel *)model;
// Calculates whether each message cell on the channel page needs to show time.
- (void)figureOutAllConversationDataRepository;
// Calculates timestamp display only for a newly changed message window and its next boundary.
- (void)figureOutConversationDataRepositoryFromIndex:(NSInteger)startIndex
                                             toIndex:(NSInteger)endIndex;
// Calculates whether a specific message needs to show time in the message list.
- (void)figureOutLatestModel:(NCMessageModel *)model;
// Adapts the unread count button size.
- (void)adaptUnreadButtonSize:(UILabel *)sender;

#pragma mark - Conditions
// Whether the message can send a read receipt.
- (BOOL)enabledReadReceiptMessage:(NCMessageModel *)model;
// Whether delete for all can be performed.
- (BOOL)canDeleteMessageForAllOfModel:(NCMessageModel *)model;
// Whether the message can be referenced.
- (BOOL)canReferenceMessage:(NCMessageModel *)message;


/// Gets a model by message ID.
/// - Parameter messageID
- (NCMessageModel *)modelByMessageID:(NSInteger)messageID;

/// Gets the model on the page by message UId.
- (NCMessageModel *)modelByMessageUId:(NSString *)messageId;

#pragma mark - Util
// Saves the draft if needed.
- (void)saveDraftIfNeed;
// Gets the HQ voice message cache path.
- (NSString *)getHQVoiceMessageCachePath;

- (NCInformationNotificationMessage *)getInfoNotificationMessageByErrorCode:(NCChatUIErrorCode)errorCode;

+ (CGFloat)incrementOfTimeLabelBy:(NCMessageModel *)model;

#pragma mark - Edit

/// Gets the editing state.
- (NCEditInputBarConfig *)getCacheEditConfig;

/// Clears the editing state.
- (void)clearEditingState;

@end
