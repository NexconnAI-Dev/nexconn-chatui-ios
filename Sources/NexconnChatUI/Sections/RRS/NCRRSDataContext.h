//
//  NCRRSDataContext.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelModel.h"
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface NCRRSDataContext : NSObject

/// Refreshes cached data when needed.
/// - Parameter conversations: Channel list.
+ (void)refreshConversationsCachedIfNeeded:(NSArray<NCChannelModel *> *)conversations;

/// Refreshes the cache with channel receipt info.
/// - Parameter infoList: Receipt info.
+ (void)refreshCacheWithResponse:(NSArray<NCMessageReadReceiptResponse *> *)infoList;
+ (void)refreshCacheWithReceiptInfo:(NSArray<NCMessageReadReceiptInfo *> *)infoList;
@end

NS_ASSUME_NONNULL_END
