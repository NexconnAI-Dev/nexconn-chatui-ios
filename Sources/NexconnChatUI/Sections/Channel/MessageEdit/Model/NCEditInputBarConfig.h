//
//  NCEditInputBarConfig.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCMentionedStringRangeInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCEditInputBarConfig : NSObject

/// Unique message identifier
@property (nonatomic, copy, nullable) NSString *messageId;

/// Message sent time
@property (nonatomic, assign) long long sentTime;

/// Text content of the edited message
@property (nonatomic, copy, nullable) NSString *textContent;

/// Sender name of the referenced message
@property (nonatomic, copy, nullable) NSString *referencedSenderName;

/// Content of the referenced message
@property (nonatomic, copy, nullable) NSString *referencedContent;

/// Status of the referenced message.
@property (nonatomic, assign) NCReferenceMessageStatus referencedMsgStatus;

/// Mention information
@property (nonatomic, copy, nullable) NSArray<NCMentionedStringRangeInfo *> *mentionedRangeInfo;

/// Initialize with encoded data
- (instancetype)initWithData:(NSString *)data;

/// Encode to string
- (NSString *)encode;

@end

NS_ASSUME_NONNULL_END
