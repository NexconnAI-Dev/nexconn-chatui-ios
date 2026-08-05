//
//  NCChatUIErrorCode.h
//  NexconnChatUI
//
//  Created on 2026/04/08.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Error codes returned by NexconnChatUI operations.
typedef NS_ENUM(NSInteger, NCChatUIErrorCode) {
    /// The operation completed successfully.
    NCChatUIErrorCodeSuccess = 0,
    /// The request frequency exceeded the server limit.
    NCChatUIErrorCodeRequestOverFrequency = 20607,
    /// The user profile service is unavailable.
    NCChatUIErrorCodeUserProfileServiceUnavailable = 24369,
    /// The online status subscription service is unavailable.
    NCChatUIErrorCodeSubscribeOnlineServiceUnavailable = 26020,
    /// The number of users subscribed to the current user exceeds the limit.
    NCChatUIErrorCodeBeSubscribedUserIdsCountExceedLimit = 26021,
    /// The number of subscribed user IDs exceeds the limit.
    NCChatUIErrorCodeSubscribedUserIdsExceedLimit = 26022,
    /// The user ID list parameter is invalid.
    NCChatUIErrorCodeInvalidParameterUserIdList = 34215,
    /// The message parameter is invalid.
    NCChatUIErrorCodeInvalidParameterMessage = 34243,
    /// The message content parameter is invalid.
    NCChatUIErrorCodeInvalidParameterMessageContent = 34205,
    /// The target ID parameter is invalid.
    NCChatUIErrorCodeInvalidParameterTargetId = 34210,
    /// The file size exceeds the upload limit.
    NCChatUIErrorCodeFileSizeExceedLimit = 26106,
    /// The file size parameter is missing or invalid.
    NCChatUIErrorCodeInvalidParameterSizeNotFound = 26107,
    /// The message UID parameter is invalid.
    NCChatUIErrorCodeInvalidParameterMessageUid = 34203,
    /// The message was sent after sensitive words were replaced.
    NCChatUIErrorCodeMessageReplacedSensitiveWord = 21502,
    /// The target channel is invalid.
    NCChatUIErrorCodeChannelInvalid = 30001,
    /// The network is unavailable.
    NCChatUIErrorCodeNetworkUnavailable = 30002,
    /// The message response timed out.
    NCChatUIErrorCodeMessageResponseTimeout = 30003,
    /// The file upload failed.
    NCChatUIErrorCodeFileUploadFailed = 34011,
    /// An unknown error occurred.
    NCChatUIErrorCodeUnknown = -1,
    /// Read receipt v5 is unavailable.
    NCChatUIErrorCodeRrsv5Unavailable = 26314,
    /// Read receipt v5 is not supported.
    NCChatUIErrorCodeRrsv5ReadReceiptNotSupport = 26315,
    /// Message read receipt is not supported.
    NCChatUIErrorCodeMessageReadReceiptNotSupport = 34029,
    /// A media processing exception occurred.
    NCChatUIErrorCodeMediaException = 34018,
    /// The original message does not exist.
    NCChatUIErrorCodeOriginalMessageNotExist = 22201,
    /// The message contains dangerous content.
    NCChatUIErrorCodeDangerousContent = 20112,
    /// The content review rejected the message.
    NCChatUIErrorCodeContentReviewRejected = 20113,
    /// The message can no longer be modified because the modification window has expired.
    NCChatUIErrorCodeMessageOverModifyTimeFail = 20114,
    /// The modified message request timed out.
    NCChatUIErrorCodeModifiedMessageTimeout = 33402,
    /// The current user is not in the group.
    NCChatUIErrorCodeNotInGroup = 22406,
    /// The operation was rejected by a blacklist rule.
    NCChatUIErrorCodeRejectedByBlacklist = 405,
    /// The current user is forbidden from sending messages in the group.
    NCChatUIErrorCodeForbiddenInGroup = 22408,
    /// The information audit failed.
    NCChatUIErrorCodeInformationAuditFailed = 25480,
    /// Network data is still synchronizing.
    NCChatUIErrorCodeNetDataIsSynchronizing = 34329,
    /// The queried user profile does not exist.
    NCChatUIErrorCodeUserProfileUserNotExist = 24366,
    /// The connection token is incorrect.
    NCChatUIErrorCodeConnectTokenIncorrect = 31004,
    /// The connected user is blocked.
    NCChatUIErrorCodeConnectUserBlocked = 31009,
    /// The user is not in the group.
    NCChatUIErrorCodeGroupUserNotInGroup = 25418,
    /// The group invitation requires invitee acceptance.
    NCChatUIErrorCodeGroupNeedInviteeAccept = 25427,
    /// Joining the group requires manager approval.
    NCChatUIErrorCodeGroupJoinNeedManagerAccept = 25424,
};

NS_ASSUME_NONNULL_END
