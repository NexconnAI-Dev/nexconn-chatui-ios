//
//  NCUserInfoCache.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUserInfoCache.h"
#import "NCChatUIExtensionManager.h"
#import "NCChatUIUserInfo.h"
#import "NCImageLoader.h"
#import "NCInfoProvider.h"
#import "NCThreadSafeMutableDictionary.h"
#import <NexconnChatUI/NCChatUILog.h>

@interface NCUserInfoCache ()

// key:userId, value:userInfo
@property (nonatomic, strong) NCThreadSafeMutableDictionary *cache;

@end

@implementation NCUserInfoCache

+ (instancetype)sharedCache {
    static NCUserInfoCache *defaultCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      if (!defaultCache) {
          defaultCache = [[NCUserInfoCache alloc] init];
          defaultCache.cache = [[NCThreadSafeMutableDictionary alloc] init];
      }
    });
    return defaultCache;
}

- (NCChatUIUserInfo *)getUserInfo:(NSString *)userId {
    NCChatUIUserInfo *cacheUserInfo = self.cache[userId];
    if (!cacheUserInfo) {
        // Read synchronously across threads.
        NCChatUIUserInfo *dbUserInfo = [ncUserInfoReadDBHelper selectUserInfoFromDB:userId];
        if (dbUserInfo) {
            cacheUserInfo = dbUserInfo;
            [self.cache setObject:cacheUserInfo forKey:userId];
        }
    }
    return cacheUserInfo;
}

- (void)updateUserInfo:(NCChatUIUserInfo *)userInfo forUserId:(NSString *)userId {
    NCChatUIUserInfo *cacheUserInfo = self.cache[userId];
    if ([userId isEqualToString:[NCEngine getCurrentUserId]]) {
        [[NCChatUIExtensionManager sharedManager] didCurrentUserInfoUpdated:userInfo];
    }
    if (![userInfo isEqual:cacheUserInfo]) {
        [self.cache setObject:userInfo forKey:userId];

        __weak typeof(self) weakSelf = self;
        dispatch_async(ncUserInfoDBQueue, ^{
          [ncUserInfoWriteDBHelper replaceUserInfoFromDB:userInfo forUserId:userId];
          NCLogI(@"updateUserInfo:forUserId:;;;userId=%@", userId);
          [weakSelf.updateDelegate onUserInfoUpdate:userInfo];
        });
    }
}

- (void)clearUserInfoNetworkCacheOnly:(NSString *)userId {
    NCChatUIUserInfo *cacheUserInfo = self.cache[userId];
    if (!cacheUserInfo) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(ncUserInfoDBQueue, ^{
          NCChatUIUserInfo *dbUserInfo = [ncUserInfoWriteDBHelper selectUserInfoFromDB:userId];
          [weakSelf removeImageCache:dbUserInfo];
        });
    } else {
        [self removeImageCache:cacheUserInfo];
    }
}

- (void)clearUserInfo:(NSString *)userId {
    NCLogI(@"clearUserInfo:;;;userId=%@", userId);
    NCChatUIUserInfo *cacheUserInfo = self.cache[userId];
    if (cacheUserInfo) {
        [self removeImageCache:cacheUserInfo];
        [self.cache removeObjectForKey:userId];
    }
    //    else {
    //        __weak typeof(self) weakSelf = self;
    //        dispatch_async(ncUserInfoDBQueue, ^{
    //            NCChatUIUserInfo *dbUserInfo = [ncUserInfoWriteDBHelper
    //            selectUserInfoFromDB:userId]; [weakSelf removeImageCache:dbUserInfo];
    //        });
    //    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(ncUserInfoDBQueue, ^{
      NCChatUIUserInfo *dbUserInfo = [ncUserInfoWriteDBHelper selectUserInfoFromDB:userId];
      if (!dbUserInfo) {
          return;
      }
      [ncUserInfoWriteDBHelper deleteUserInfoFromDB:userId];
      NCChatUIUserInfo *userInfo = [[NCChatUIUserInfo alloc] init];
      userInfo.userId = userId;
      [weakSelf.updateDelegate onUserInfoUpdate:userInfo];
    });
}

- (void)clearAllUserInfo {
    //    for (NCChatUIUserInfo *cacheUserInfo in [self.cache allValues]) {
    //        [self removeImageCache:cacheUserInfo];
    //    }
    [self.cache removeAllObjects];

    //    __weak typeof(self) weakSelf = self;
    dispatch_async(ncUserInfoDBQueue, ^{
      //        NSArray *dbUserInfoList = [ncUserInfoWriteDBHelper selectAllUserInfoFromDB];
      //        for (NCChatUIUserInfo *dbUserInfo in dbUserInfoList) {
      //            [weakSelf removeImageCache:dbUserInfo];
      //        }
      [ncUserInfoWriteDBHelper deleteAllUserInfoFromDB];
    });
}

#pragma mark - image cache
- (void)removeImageCache:(NCChatUIUserInfo *)userInfo {
    //    if ([userInfo.avatarUrl length] > 0) {
    //        [[NCImageLoader sharedImageLoader] clearCacheForURL:[NSURL
    //        URLWithString:userInfo.avatarUrl]];
    //    }
}

@end
