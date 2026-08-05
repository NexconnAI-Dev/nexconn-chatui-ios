//
//  NCConversationUserInfoCache.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCConversationUserInfoCache.h"
#import <NexconnChatUI/NCChatUILog.h>
#import "NCChatUIUserInfo.h"
#import "NCChannelInfo.h"
#import "NCThreadSafeMutableDictionary.h"
#import "NCInfoProvider.h"
#import "NCImageLoader.h"

static void *cacheRWQueueTag = &cacheRWQueueTag;

@interface NCConversationUserInfoCache ()

// key:GUID(channelType;;;channelId), value:(NSMutableDictionary(key:userId, value:userInfo))
@property (nonatomic, strong) NCThreadSafeMutableDictionary *cache;
@property (nonatomic, strong) dispatch_queue_t conversationUserInfoCacheRWQueue;

@end

@implementation NCConversationUserInfoCache

+ (instancetype)sharedCache {
    static NCConversationUserInfoCache *defaultCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!defaultCache) {
            defaultCache = [[NCConversationUserInfoCache alloc] init];
            defaultCache.cache = [[NCThreadSafeMutableDictionary alloc] init];
        }
    });
    return defaultCache;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.conversationUserInfoCacheRWQueue =  dispatch_queue_create("ai.nexconn.conversationUserInfoCacheRWQueue", NULL);
        dispatch_queue_set_specific(self.conversationUserInfoCacheRWQueue, cacheRWQueueTag, cacheRWQueueTag, NULL);
    }
    return self;
}

- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId
           channelType:(NCChannelType)channelType
                   channelId:(NSString *)channelId {
    NSString *conversationGUID = [NCChannelInfo getConversationGUID:channelType channelId:channelId];
    if (0 == conversationGUID.length || 0 == userId.length) {
        return nil;
    }
    
    __block NCChatUIUserInfo *cacheUserInfo = nil;
    
    // Read synchronously.
    [self performSyncRWQueueBlock:^{
        NSMutableDictionary *cacheUserInfoList = self.cache[conversationGUID];
        if (cacheUserInfoList) {
            cacheUserInfo = cacheUserInfoList[userId];
        }
    }];

    // Cache miss.
    if (nil == cacheUserInfo) {
        // Read from the database.
        NCChatUIUserInfo *dbUserInfo =
            [ncUserInfoReadDBHelper selectUserInfoFromDB:userId channelType:channelType channelId:channelId];
        if (dbUserInfo) {
            cacheUserInfo = dbUserInfo;
            // Update the cache on the serial queue.
            [self performAsyncRWQueueBlock:^{
                NSMutableDictionary *cacheUserInfoList = self.cache[conversationGUID];
                if (!cacheUserInfoList) {
                    cacheUserInfoList = [[NSMutableDictionary alloc] init];
                    [self.cache setObject:cacheUserInfoList forKey:conversationGUID];
                }
                [cacheUserInfoList setValue:cacheUserInfo forKey:userId];
            }];
        }
    }
    return cacheUserInfo;
}

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo
             forUserId:(NSString *)userId
      channelType:(NCChannelType)channelType
              channelId:(NSString *)channelId {
    NSString *conversationGUID = [NCChannelInfo getConversationGUID:channelType channelId:channelId];
    if (0 == conversationGUID.length || 0 == userId.length) {
        return;
    }
    
    __block NCChatUIUserInfo *cacheUserInfo = nil;
    
    // Read synchronously.
    [self performSyncRWQueueBlock:^{
        NSMutableDictionary *cacheUserInfoList = self.cache[conversationGUID];
        if (cacheUserInfoList) {
            cacheUserInfo = cacheUserInfoList[userId];
        }
    }];
    if (![userInfo isEqual:cacheUserInfo]) {
        // Update the cache on the serial queue.
        [self performAsyncRWQueueBlock:^{
            NSMutableDictionary *cacheUserInfoList = self.cache[conversationGUID];
            if (!cacheUserInfoList) {
                cacheUserInfoList = [[NSMutableDictionary alloc] init];
                [self.cache setObject:cacheUserInfoList forKey:conversationGUID];
            }
            [cacheUserInfoList setValue:userInfo forKey:userId];
        }];
            
        dispatch_async(ncUserInfoDBQueue, ^{
            [ncUserInfoWriteDBHelper replaceUserInfoFromDB:userInfo
                                                 forUserId:userId
                                          channelType:channelType
                                                  channelId:channelId];
            NCLogI(@"updateUserInfo:forUserId:channelType;channelId:;;;channelType=%lu,targerId=%@,userId=%@,"
                   @"name=%@,portrait=%@",
                   (unsigned long)channelType, channelId, userInfo.userId, userInfo.name, userInfo.avatarUrl);
            [self.updateDelegate onConversationUserInfoUpdate:userInfo
                                                   inConversation:channelType
                                                         channelId:channelId];
        });
    }
}

- (void)clearConversationUserInfoNetworkCacheOnly:(NSString *)userId
                                 channelType:(NCChannelType)channelType
                                         channelId:(NSString *)channelId {
    NSString *conversationGUID = [NCChannelInfo getConversationGUID:channelType channelId:channelId];
    if (0 == conversationGUID.length || 0 == userId.length) {
        return;
    }
    
    __block NCChatUIUserInfo *cacheUserInfo = nil;
    
    // Read synchronously.
    [self performSyncRWQueueBlock:^{
        NSMutableDictionary *cacheUserInfoList = self.cache[conversationGUID];
        if (cacheUserInfoList) {
            cacheUserInfo = cacheUserInfoList[userId];
        }
    }];

    if (!cacheUserInfo) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(ncUserInfoDBQueue, ^{
            NCChatUIUserInfo *dbUserInfo = [ncUserInfoWriteDBHelper selectUserInfoFromDB:userId
                                                                  channelType:channelType
                                                                          channelId:channelId];
            [weakSelf removeImageCache:dbUserInfo];
        });
    } else {
        [self removeImageCache:cacheUserInfo];
    }
}

- (void)clearConversationUserInfo:(NSString *)userId
                 channelType:(NCChannelType)channelType
                         channelId:(NSString *)channelId {
    NSString *conversationGUID = [NCChannelInfo getConversationGUID:channelType channelId:channelId];
    if (0 == conversationGUID.length || 0 == userId.length) {
        return;
    }
    
    __block NCChatUIUserInfo *cacheUserInfo = nil;
    __block NSMutableDictionary *cacheUserInfoList = nil;
    
    // Read synchronously.
    [self performSyncRWQueueBlock:^{
        cacheUserInfoList = self.cache[conversationGUID];
        if (cacheUserInfoList) {
            cacheUserInfo = cacheUserInfoList[userId];
        }
    }];

    if (!cacheUserInfo) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(ncUserInfoDBQueue, ^{
            NCChatUIUserInfo *dbUserInfo = [ncUserInfoWriteDBHelper selectUserInfoFromDB:userId
                                                                  channelType:channelType
                                                                          channelId:channelId];
            [weakSelf removeImageCache:dbUserInfo];
        });
    } else {
        [self performAsyncRWQueueBlock:^{
            [cacheUserInfoList removeObjectForKey:userId];
            [self.cache setValue:cacheUserInfoList forKey:conversationGUID];
            [self removeImageCache:cacheUserInfo];
        }];
    }
    dispatch_async(ncUserInfoDBQueue, ^{
        [ncUserInfoWriteDBHelper deleteConversationUserInfoFromDB:userId
                                                 channelType:channelType
                                                         channelId:channelId];
        NCLogI(@"clearConversationUserInfo:channelType;channelId:;;;userId:%@,channelType=%lu,targerId=%@",userId, (unsigned long)channelType, channelId);
        NCChatUIUserInfo *userInfo = [[NCChatUIUserInfo alloc] init];
        userInfo.userId = userId;
        [self.updateDelegate onConversationUserInfoUpdate:userInfo
                                               inConversation:channelType
                                                     channelId:channelId];
    });
}

- (void)clearAllConversationUserInfo {
    //    for (NSDictionary *cacheUserInfoList in [self.cache allValues]) {
    //        for (NCChatUIUserInfo *cacheUserInfo in [cacheUserInfoList allValues]) {
    //            [self removeImageCache:cacheUserInfo];
    //        }
    //    }
    
    [self performAsyncRWQueueBlock:^{
        [self.cache removeAllObjects];
    }];

    //    __weak typeof(self) weakSelf = self;
    dispatch_async(ncUserInfoDBQueue, ^{
        //        NSArray *dbUserInfoList = [ncUserInfoWriteDBHelper selectAllConversationUserInfoFromDB];
        //        for (NCChatUIUserInfo *dbUserInfo in dbUserInfoList) {
        //            [weakSelf removeImageCache:dbUserInfo];
        //        }
        [ncUserInfoWriteDBHelper deleteAllConversationUserInfoFromDB];
    });
}

#pragma mark - image cache
- (void)removeImageCache:(NCChatUIUserInfo *)userInfo {
    //    if ([userInfo.avatarUrl length] > 0) {
    //        [[NCImageLoader sharedImageLoader] clearCacheForURL:[NSURL URLWithString:userInfo.avatarUrl]];
    //    }
}

- (void)performAsyncRWQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(cacheRWQueueTag)) {
        block();
    }
    else {
        dispatch_async(self.conversationUserInfoCacheRWQueue, block);
    }
}

- (void)performSyncRWQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(cacheRWQueueTag)) {
        block();
    }
    else {
        dispatch_sync(self.conversationUserInfoCacheRWQueue, block);
    }
}

@end
