//
//  NCChannelInfoCache.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelInfoCache.h"
#import "NCImageLoader.h"
#import "NCInfoProvider.h"
#import "NCThreadSafeMutableDictionary.h"
#import <NexconnChatUI/NCChatUILog.h>

@interface NCChannelInfoCache ()

// key:GUID(channelType;;;channelId), value:coversationInfo
@property (nonatomic, strong) NCThreadSafeMutableDictionary *cache;

@end

@implementation NCChannelInfoCache

+ (instancetype)sharedCache {
    static NCChannelInfoCache *defaultCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      if (!defaultCache) {
          defaultCache = [[NCChannelInfoCache alloc] init];
          defaultCache.cache = [[NCThreadSafeMutableDictionary alloc] init];
      }
    });
    return defaultCache;
}

- (NCChannelInfo *)getConversationInfo:(NCChannelType)channelType channelId:(NSString *)channelId {
    NSString *conversationGUID = [NCChannelInfo getConversationGUID:channelType
                                                          channelId:channelId];
    if (!conversationGUID) {
        return nil;
    }
    NCChannelInfo *cacheConversationInfo = self.cache[conversationGUID];

    if (!cacheConversationInfo) {
        // Read synchronously across threads.
        NCChannelInfo *dbConversationInfo =
            [ncUserInfoReadDBHelper selectConversationInfoFromDB:channelType channelId:channelId];
        if (dbConversationInfo) {
            dbConversationInfo.groupInfo = [dbConversationInfo translateToGroupInfo];
            [self.cache setValue:dbConversationInfo forKey:conversationGUID];
        }
        cacheConversationInfo = dbConversationInfo;
    }
    if (!cacheConversationInfo) {
        return nil;
    }
    NCChannelInfo *conInfo =
        [[NCChannelInfo alloc] initWithConversationId:cacheConversationInfo.channelId
                                          channelType:cacheConversationInfo.channelType
                                                 name:cacheConversationInfo.name
                                            avatarUrl:cacheConversationInfo.avatarUrl
                                                extra:cacheConversationInfo.extra];
    conInfo.groupInfo = cacheConversationInfo.groupInfo;
    return conInfo;
}

- (void)updateConversationInfo:(NCChannelInfo *)conversationInfo
                   channelType:(NCChannelType)channelType
                     channelId:(NSString *)channelId {
    NSString *conversationGUID = [NCChannelInfo getConversationGUID:channelType
                                                          channelId:channelId];
    if (!conversationGUID) {
        return;
    }
    NCChannelInfo *cacheConversationInfo = self.cache[conversationGUID];

    if (![cacheConversationInfo isEqual:conversationInfo]) {
        [self.cache setValue:conversationInfo forKey:conversationGUID];

        __weak typeof(self) weakSelf = self;
        dispatch_async(ncUserInfoDBQueue, ^{
          [ncUserInfoWriteDBHelper replaceConversationInfoFromDB:conversationInfo
                                                     channelType:channelType
                                                       channelId:channelId];
          NCLogI(@"updateConversationInfo:channelType:channelId:;;;channelType=%lu,targerId=%@,"
                 @"name=%@,"
                 @"portrait=%@",
                 (unsigned long)channelType, channelId, conversationInfo.name,
                 conversationInfo.avatarUrl);
          [weakSelf.updateDelegate onConversationInfoUpdate:conversationInfo];
        });
    }
}

- (void)clearConversationInfoNetworkCacheOnly:(NCChannelType)channelType
                                    channelId:(NSString *)channelId {
    NSString *conversationGUID = [NCChannelInfo getConversationGUID:channelType
                                                          channelId:channelId];
    NCChannelInfo *cacheConversationInfo = self.cache[conversationGUID];

    if (!cacheConversationInfo) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(ncUserInfoDBQueue, ^{
          NCChannelInfo *dbConversationInfo =
              [ncUserInfoWriteDBHelper selectConversationInfoFromDB:channelType
                                                          channelId:channelId];
          [weakSelf removeImageCache:dbConversationInfo];
        });
    } else {
        [self removeImageCache:cacheConversationInfo];
    }
}

- (void)clearConversationInfo:(NCChannelType)channelType channelId:(NSString *)channelId {
    NCLogI(@"clearConversationInfo:channelId:;;;channelType=%lu,targerId=%@",
           (unsigned long)channelType, channelId);
    NSString *conversationGUID = [NCChannelInfo getConversationGUID:channelType
                                                          channelId:channelId];
    if (!conversationGUID) {
        return;
    }
    NCChannelInfo *cacheConversationInfo = self.cache[conversationGUID];

    if (cacheConversationInfo) {
        [self removeImageCache:cacheConversationInfo];
        [self.cache removeObjectForKey:conversationGUID];
    }
    //    else {
    //        __weak typeof(self) weakSelf = self;
    //        dispatch_async(ncUserInfoDBQueue, ^{
    //            NCChannelInfo *dbConversationInfo =
    //                [ncUserInfoWriteDBHelper selectConversationInfoFromDB:channelType
    //                channelId:channelId];
    //            [weakSelf removeImageCache:dbConversationInfo];
    //        });
    //    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(ncUserInfoDBQueue, ^{
      [ncUserInfoWriteDBHelper deleteConversationInfoFromDB:channelType channelId:channelId];
      NCChannelInfo *conversationInfo = [[NCChannelInfo alloc] initWithConversationId:channelId
                                                                          channelType:channelType
                                                                                 name:nil
                                                                            avatarUrl:nil
                                                                                extra:nil];
      [weakSelf.updateDelegate onConversationInfoUpdate:conversationInfo];
    });
}

- (void)clearAllConversationInfo {
    //    for (NCChannelInfo *cacheConversationInfo in [self.cache allValues]) {
    //        [self removeImageCache:cacheConversationInfo];
    //    }
    [self.cache removeAllObjects];

    //    __weak typeof(self) weakSelf = self;
    dispatch_async(ncUserInfoDBQueue, ^{
      //        NSArray *dbConversationInfoList = [ncUserInfoWriteDBHelper
      //        selectAllConversationInfoFromDB]; for (NCChannelInfo *dbConversationInfo in
      //        dbConversationInfoList) {
      //            [weakSelf removeImageCache:dbConversationInfo];
      //        }
      [ncUserInfoWriteDBHelper deleteAllConversationInfoFromDB];
    });
}

#pragma mark - image cache
- (void)removeImageCache:(NCChannelInfo *)conversationInfo {
    //    if ([conversationInfo.avatarUrl length] > 0) {
    //        [[NCImageLoader sharedImageLoader] clearCacheForURL:[NSURL
    //        URLWithString:conversationInfo.avatarUrl]];
    //    }
}

@end
