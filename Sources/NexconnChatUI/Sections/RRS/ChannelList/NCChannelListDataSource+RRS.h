//
//  NCChannelListDataSource+RRS.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCChannelListDataSource (RRS)
- (void)rrs_didReceiveMessageReadReceiptResponses:(NSArray<NCMessageReadReceiptResponse *> *)responses;
- (void)rrs_refreshCachedAndFetchReceiptInfo:(NSArray <NCChannelModel *>*)conversations;
@end

NS_ASSUME_NONNULL_END
