//
//  NCMessageModel+Edit.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCMessageModel (Edit)

/// Whether this message is editable.
- (BOOL)edit_isMessageEditable;

/// Whether the current message is a reference message.
- (BOOL)edit_hasReferenceMessage;

/// Returns the message's own clientId if it is a reference message whose referenced content needs refreshing; otherwise returns nil.
+ (nullable NSString *)edit_refreshableReferenceMessageUIdFromMessage:(NCMessage *)message;

/// Returns the text message content, or nil for non-text messages.
- (nullable NCTextMessage *)edit_textMessage;

/// Returns the reference message content, or nil for non-reference messages.
- (nullable NCReferenceMessage *)edit_referenceMessage;

/// Returns the text content of the current editable message. Only valid for text and reference messages.
- (nullable NSString *)edit_editableText;

/// Returns the sender userId of the referenced message, or nil for non-reference messages.
- (nullable NSString *)edit_referenceMessageUserId;

/// Returns the messageId of the referenced message, or nil for non-reference messages.
- (nullable NSString *)edit_referenceMessageUId;

/// Returns the referenced message status, or the default status for non-reference messages.
- (NCReferenceMessageStatus)edit_referenceMessageStatus;

/// Updates the referenced message status. Has no effect for non-reference messages.
- (void)edit_setReferenceMessageStatus:(NCReferenceMessageStatus)status;

/// Returns the plain text content in the referenced message, or nil for non-text messages.
- (nullable NSString *)edit_referencedText;

/// Returns the formatted display text for the referenced message, or nil when there is no referenced message.
- (nullable NSString *)edit_formattedReferencedMessageContent;

/// Updates the referenced message preview text from a new message model using the existing same-type rules. Has no effect when it does not match.
- (void)edit_updateReferencedMessagePreviewContentFromModel:(nullable NCMessageModel *)model;

/// Updates the referenced message content from a new message model. Has no effect for non-reference messages.
- (void)edit_updateReferencedMessageContentFromModel:(nullable NCMessageModel *)model;

@end

NS_ASSUME_NONNULL_END
