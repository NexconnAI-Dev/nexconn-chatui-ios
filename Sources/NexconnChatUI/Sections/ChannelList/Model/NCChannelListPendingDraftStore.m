//
//  NCChannelListPendingDraftStore.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelListPendingDraftStore.h"
#import "NCChatUILog.h"

static NSTimeInterval const NCPendingDraftCacheTTLSeconds = 30.0;
static NSString *const NCPendingDraftCacheDraftKey = @"draft";
static NSString *const NCPendingDraftCacheUpdatedAtKey = @"updatedAt";

@interface NCChannelListPendingDraftStore ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *pendingDraftCache;

@end

@implementation NCChannelListPendingDraftStore

- (instancetype)init {
    self = [super init];
    if (self) {
        _pendingDraftCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)cacheDraft:(nullable NSString *)draft
       channelType:(NCChannelType)channelType
         channelId:(NSString *)channelId
      subChannelId:(nullable NSString *)subChannelId {
    NSString *cacheKey = [self pendingDraftCacheKeyWithChannelType:channelType
                                                         channelId:channelId
                                                      subChannelId:subChannelId];
    if (cacheKey.length == 0) {
        return;
    }
    NSString *normalizedDraft = draft ?: @"";
    self.pendingDraftCache[cacheKey] = @{
        NCPendingDraftCacheDraftKey : normalizedDraft,
        NCPendingDraftCacheUpdatedAtKey : @([[NSDate date] timeIntervalSince1970]),
    };
}

- (void)mergeDraftIntoModelList:(NSMutableArray<NCChannelModel *> *)modelList {
    [self cleanupExpiredPendingDraftCacheIfNeeded];
    if (self.pendingDraftCache.count == 0 || modelList.count == 0) {
        return;
    }
    NSMutableArray<NSString *> *resolvedKeys = [NSMutableArray array];
    for (NCChannelModel *model in modelList) {
        NSString *cacheKey = [self pendingDraftCacheKeyWithChannelType:model.channelType
                                                             channelId:model.channelId
                                                          subChannelId:model.subChannelId];
        NSDictionary *cacheValue = self.pendingDraftCache[cacheKey];
        if (![cacheValue isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *cachedDraft = cacheValue[NCPendingDraftCacheDraftKey];
        if (![cachedDraft isKindOfClass:[NSString class]]) {
            cachedDraft = @"";
        }
        NSString *backendDraft = model.draft ?: @"";
        if ([backendDraft isEqualToString:cachedDraft]) {
            [resolvedKeys addObject:cacheKey];
            continue;
        }
        model.draft = cachedDraft;
    }
    if (resolvedKeys.count > 0) {
        [self.pendingDraftCache removeObjectsForKeys:resolvedKeys];
    }
}

- (NSString *)pendingDraftCacheKeyWithChannelType:(NCChannelType)channelType
                                        channelId:(NSString *)channelId
                                     subChannelId:(nullable NSString *)subChannelId {
    NSString *normalizedChannelId = channelId ?: @"";
    NSString *normalizedSubChannelId = subChannelId ?: @"";
    return [NSString stringWithFormat:@"%ld_%@_%@", (long)channelType, normalizedChannelId,
                                      normalizedSubChannelId];
}

- (void)cleanupExpiredPendingDraftCacheIfNeeded {
    if (self.pendingDraftCache.count == 0) {
        return;
    }
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSMutableArray<NSString *> *expiredKeys = [NSMutableArray array];
    for (NSString *key in self.pendingDraftCache.allKeys) {
        NSDictionary *cacheValue = self.pendingDraftCache[key];
        NSNumber *updatedAtNumber = cacheValue[NCPendingDraftCacheUpdatedAtKey];
        if (![updatedAtNumber isKindOfClass:[NSNumber class]]) {
            [expiredKeys addObject:key];
            continue;
        }
        NSTimeInterval updatedAt = updatedAtNumber.doubleValue;
        if (now - updatedAt > NCPendingDraftCacheTTLSeconds) {
            [expiredKeys addObject:key];
        }
    }
    if (expiredKeys.count == 0) {
        return;
    }
    [self.pendingDraftCache removeObjectsForKeys:expiredKeys];
    NCLogW(@"clear expired draft cache entries count:%@", @(expiredKeys.count));
}

@end
