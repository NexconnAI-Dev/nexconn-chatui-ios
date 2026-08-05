//
//  NCChannelModel+RRS.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface NCChannelModel (RRS)

/// Whether read receipt info can be fetched.
- (BOOL)rrs_couldFetchConversationReadReceipt;

/// Whether read receipt info should be fetched.
- (BOOL)rrs_shouldFetchConversationReadReceipt;

/// Message identifier.
- (NCMessageIdentifier *)rrs_messageIdentifier;
@end

NS_ASSUME_NONNULL_END
