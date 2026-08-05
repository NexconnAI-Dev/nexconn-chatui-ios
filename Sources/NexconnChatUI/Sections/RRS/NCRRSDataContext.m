//
//  NCRRSDataContext.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCRRSDataContext.h"
#import "NCReadWriteLock.h"
#import "NCChannelModel+RRS.h"
#import "NCRRSUtil.h"

static NCMessageReadReceiptInfo *NCReadReceiptInfoFromResponse(NCMessageReadReceiptResponse *response) {
    if (!response || response.messageId.length == 0) {
        return nil;
    }
    NCChannelIdentifier *channelIdentifier = response.channelIdentifier;
    if (!channelIdentifier || channelIdentifier.channelId.length == 0) {
        return nil;
    }
    NCMessageReadReceiptInfo *info = [[NCMessageReadReceiptInfo alloc] init];
    info.channelIdentifier = channelIdentifier;
    info.messageId = response.messageId;
    info.readCount = response.readCount;
    info.unreadCount = response.unreadCount;
    info.totalCount = response.totalCount;
    return info;
}

@interface NCRRSDataContext()
@property (nonatomic, strong) NCReadWriteLock *lock;
@property (nonatomic, strong) NSMutableDictionary *cacheInfo;
@end

@implementation NCRRSDataContext

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.lock = [[NCReadWriteLock alloc] init];
        self.cacheInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)keyByChannelIdentifier:(NCChannelIdentifier *)identifier {
    if (!identifier || identifier.channelId.length == 0) {
        return nil;
    }
    NSString *subChannelId = @"null";
    if ([identifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]) {
        NSString *channelId = ((NCCommunitySubChannelIdentifier *)identifier).subChannelId;
        if (channelId.length > 0) {
            subChannelId = channelId;
        }
    }
    return [NSString stringWithFormat:@"%@-%lu-%@", identifier.channelId, (unsigned long)identifier.channelType, subChannelId];
}

+ (void)refreshCacheWithReceiptInfo:(NSArray<NCMessageReadReceiptInfo *> *)infoList {
    NCRRSDataContext *instance = [NCRRSDataContext sharedInstance];
    [instance refreshCacheWithReceiptInfo:infoList];
}

- (void)refreshCacheWithReceiptInfo:(NSArray<NCMessageReadReceiptInfo *> *)infoList {
    [self.lock performWriteLockBlock:^{
        for (NCMessageReadReceiptInfo *info in infoList) {
            NSString *key = [self keyByChannelIdentifier:info.channelIdentifier];
            if (key) {
                self.cacheInfo[key] = info;
            }
        }
    }];
}

+ (void)refreshCacheWithResponse:(NSArray<NCMessageReadReceiptResponse *> *)infoList {
    NCRRSDataContext *instance = [NCRRSDataContext sharedInstance];
    [instance refreshCacheWithResponse:infoList];
}

- (void)refreshCacheWithResponse:(NSArray<NCMessageReadReceiptResponse *> *)infoList {
    NSMutableArray *array = [NSMutableArray array];
    for (NCMessageReadReceiptResponse *info in infoList) {
        if (info.channelIdentifier.channelType == NCChannelTypeDirect) {// Only direct channels are supported.
            [array addObject:info];
        }
    }
    [self.lock performWriteLockBlock:^{
        for (NCMessageReadReceiptResponse *response in array) {
            NSString *key = [self keyByChannelIdentifier:response.channelIdentifier];
            if (key) {
                NCMessageReadReceiptInfo *info = NCReadReceiptInfoFromResponse(response);
                if (info) {
                    self.cacheInfo[key] = info;
                }
            }
        }
    }];
}

+ (void)refreshConversationsCachedIfNeeded:(NSArray <NCChannelModel *>*)conversations {
    NCRRSDataContext *instance = [NCRRSDataContext sharedInstance];
    [instance refreshConversationsCachedIfNeeded:conversations];
}

- (void)refreshConversationsCachedIfNeeded:(NSArray <NCChannelModel *>*)conversations {
    if (conversations.count == 0) {
        return;
    }
    
    // Copy a cache snapshot to avoid holding the read lock during iteration.
    __block NSDictionary *cacheSnapshot = nil;
    [self.lock performReadLockBlock:^{
        cacheSnapshot = [self.cacheInfo copy];
    }];
    
    // Iterate through channels and look up each cache entry by key.
    for (NCChannelModel *model in conversations) {
        if (![model rrs_couldFetchConversationReadReceipt]) {
            continue;
        }
        // Build the cache key.
        NCChannelIdentifier *identifier = nil;
        if (model.channelType == NCChannelTypeCommunity && model.subChannelId.length > 0) {
            identifier = [[NCCommunitySubChannelIdentifier alloc] initWithChannelId:model.channelId
                                                                        subChannelId:model.subChannelId];
        } else {
            identifier = [[NCChannelIdentifier alloc] initWithChannelType:model.channelType
                                                                channelId:model.channelId];
        }
        NSString *key = [self keyByChannelIdentifier:identifier];
        // Look up the cached receipt info.
        id cachedValue = cacheSnapshot[key];
        if (!cachedValue) {
            continue;
        }
        
        if ([cachedValue isKindOfClass:[NCMessageReadReceiptInfo class]]) {
            NCMessageReadReceiptInfo *info = (NCMessageReadReceiptInfo *)cachedValue;
            // Verify that the message ID still matches.
            if ([info.messageId isEqualToString:model.latestMessageId]) {
                model.readReceiptInfo = info;
            }
        }
    }
}
@end
