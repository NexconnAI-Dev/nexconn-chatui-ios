//
//  NCChannelDataSource+RRS.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCChannelDataSource (RRS)
- (void)rrs_fetchReadReceiptInfo:(NSArray<NCMessageModel *> *)models;
- (void)rrs_respondReadReceipt:(NSDictionary *)dic;
@end

NS_ASSUME_NONNULL_END
