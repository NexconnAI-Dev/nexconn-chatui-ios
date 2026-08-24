//
//  NCChannelListPendingDraftStore.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelModel.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCChannelListPendingDraftStore : NSObject

- (void)cacheDraft:(nullable NSString *)draft
       channelType:(NCChannelType)channelType
         channelId:(NSString *)channelId
      subChannelId:(nullable NSString *)subChannelId;

- (void)mergeDraftIntoModelList:(NSMutableArray<NCChannelModel *> *)modelList;

@end

NS_ASSUME_NONNULL_END
