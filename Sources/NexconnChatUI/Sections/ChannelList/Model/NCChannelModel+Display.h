//
//  NCChannelModel+Display.h
//  NexconnChatUI
//
//  Created on 2026/4/3.
//

#import "NCChannelModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Convenience methods for channel list display.
@interface NCChannelModel (Display)

/// Channel display name, preferring data provider values over cached user or group info.
- (nullable NSString *)conversationDisplayName;

/// Channel portrait URL, preferring data provider values over cached user or group info.
- (nullable NSString *)conversationPortraitUri;

/// Cached channel portrait URL.
- (nullable NSString *)conversationCachedPortraitUri;

/// Display name of the last message sender in a group chat, preferring alias, then group member
/// remark, then name.
- (nullable NSString *)senderDisplayNameInGroup;

/// Formatted display content for the last message.
- (nullable NSString *)formattedLastMessageContent;

/// Whether read receipts are enabled for the current channel type.
- (BOOL)isReadReceiptEnabledForCurrentChannelType;

@end

NS_ASSUME_NONNULL_END
