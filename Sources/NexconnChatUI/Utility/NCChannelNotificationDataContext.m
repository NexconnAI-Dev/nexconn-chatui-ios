//
//  NCChannelNotificationDataContext.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelNotificationDataContext.h"
#import "NCReadWriteLock.h"

NSString *const NCChannelNotificationDataContextGlobalNotificationLevel = @"NCChannelNotificationDataContextGlobalNotificationLevel";
NSString *const NCChannelNotificationDataContextNotificationLevelUpdate = @"NCChannelNotificationDataContextNotificationLevelUpdate";

static NSString *const NCChannelNotificationDataContextKeySeparator = @"__";

typedef NS_ENUM(NSInteger, NCNoDisturbQueryStrategy) {
    NCNoDisturbQueryStrategyNone = 0,
    NCNoDisturbQueryStrategyCategory = 1,
    NCNoDisturbQueryStrategyTarget = 2,
    NCNoDisturbQueryStrategyChannel = 3
};

@interface NCChannelNotificationDataContext ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *notificationInfo;
@property (nonatomic, strong) dispatch_queue_t notificationWorkQueue;
@property (nonatomic, strong) NCReadWriteLock *threadLock;
@property (nonatomic, strong) NSDateFormatter *formatter;
@property (nonatomic, strong, nullable) NSDate *dateBegin;
@property (nonatomic, strong, nullable) NSDate *dateEnd;
@end

static NCChannelNotificationDataContext *_instance = nil;
static dispatch_once_t onceToken;

@implementation NCChannelNotificationDataContext

+ (instancetype)sharedInstence {
    dispatch_once(&onceToken, ^{
        _instance = [[NCChannelNotificationDataContext alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _notificationInfo = [NSMutableDictionary dictionary];
        _notificationWorkQueue = dispatch_queue_create("ai.nexconn.notificationWorkQueue", DISPATCH_QUEUE_SERIAL);
        _threadLock = [NCReadWriteLock new];
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat:@"HH:mm:ss"];
    }
    return self;
}

#pragma mark - Public

+ (void)updateNotificationLevelWith:(NSArray<NCBaseChannel *> *)channels {
    if (channels.count == 0) {
        return;
    }
    NCChannelNotificationDataContext *context = [self currentDataContext];
    [context performOperationQueueBlock:^{
        NSMutableDictionary<NSString *, NSNumber *> *dic = [NSMutableDictionary dictionaryWithCapacity:channels.count];
        for (NCBaseChannel *channel in channels) {
            NSString *channelId = channel.channelId ?: @"";
            if (channelId.length == 0) {
                continue;
            }
            NSString *subChannelId = nil;
            if ([channel isKindOfClass:[NCCommunitySubChannel class]]) {
                subChannelId = ((NCCommunitySubChannel *)channel).subChannelId;
            }
            NSString *key = [self keyStringWith:channel.channelType channelId:channelId channelId:subChannelId];
            dic[key] = @(channel.noDisturbLevel);
        }
        [context.threadLock performWriteLockBlock:^{
            [context.notificationInfo addEntriesFromDictionary:dic];
        }];
    }];
}

+ (void)queryNotificationLevelWith:(NCChannelType)type
                          channelId:(NSString *__nullable)channelId
                         channelId:(NSString *__nullable)channelId
                        completion:(void (^)(NCChannelNoDisturbLevel level))completion {
    NCChannelNotificationDataContext *context = [self currentDataContext];
    [context performOperationQueueBlock:^{
        [self queryGlobalNotificationLevel:^(NCChannelNoDisturbLevel level) {
            if (level != NCChannelNoDisturbLevelDefaultLevel) {
                if (completion) {
                    completion(level);
                }
                return;
            }
            [self queryCommonNotificationLevelWith:type
                                          channelId:channelId
                                         channelId:channelId
                                        completion:completion];
        }];
    }];
}

+ (void)queryNotificationLevelWithChannelIdentifier:(NCChannelIdentifier *)channelIdentifier
                                         completion:(void (^)(NCChannelNoDisturbLevel level))completion {
    NCChannelType channelType = channelIdentifier.channelType;
    NSString *channelId = channelIdentifier.channelId;
    NSString *subChannelId = nil;
    if ([channelIdentifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]) {
        subChannelId = ((NCCommunitySubChannelIdentifier *)channelIdentifier).subChannelId;
    }
    [self queryNotificationLevelWith:channelType
                            channelId:channelId
                           channelId:subChannelId
                          completion:completion];
}

+ (void)destroy {
    onceToken = 0;
    _instance = nil;
}

+ (void)clean {
    NCChannelNotificationDataContext *context = [self currentDataContext];
    [context performOperationQueueBlock:^{
        [context.threadLock performWriteLockBlock:^{
            [context.notificationInfo removeAllObjects];
            context.dateBegin = nil;
            context.dateEnd = nil;
        }];
    }];
}

#pragma mark - Query

+ (void)queryGlobalNotificationLevel:(void (^)(NCChannelNoDisturbLevel level))completion {
    NCChannelNotificationDataContext *context = [self currentDataContext];
    __block NSNumber *levelNumber = nil;
    __block NSDate *dateBegin = nil;
    __block NSDate *dateEnd = nil;
    [context.threadLock performReadLockBlock:^{
        levelNumber = context.notificationInfo[NCChannelNotificationDataContextGlobalNotificationLevel];
        dateBegin = context.dateBegin;
        dateEnd = context.dateEnd;
    }];
    NSDate *now = [NSDate date];
    if (dateBegin && dateEnd && [now compare:dateBegin] != NSOrderedAscending && [now compare:dateEnd] == NSOrderedAscending) {
        NCChannelNoDisturbLevel level = levelNumber ? (NCChannelNoDisturbLevel)[levelNumber integerValue] : NCChannelNoDisturbLevelDefaultLevel;
        if (completion) {
            completion(level);
        }
        return;
    }
    [self queryGlobalNotificationLevelInDB:^(NCNoDisturbTimeInfo *setting) {
        [self updateGlobalNotificationLevelWith:setting];
        NCChannelNoDisturbLevel mappedLevel = [self mapNoDisturbTimeLevelToChannelLevel:setting.level];
        if (completion) {
            completion(mappedLevel);
        }
    } error:^(NSInteger status) {
        (void)status;
        if (completion) {
            completion(NCChannelNoDisturbLevelDefaultLevel);
        }
    }];
}

+ (void)queryCommonNotificationLevelWith:(NCChannelType)type
                                channelId:(NSString *__nullable)channelId
                               channelId:(NSString *__nullable)channelId
                              completion:(void (^)(NCChannelNoDisturbLevel level))completion {
    NCNoDisturbQueryStrategy strategy = NCNoDisturbQueryStrategyChannel;
    if ([self isStringEmpty:channelId]) {
        strategy = NCNoDisturbQueryStrategyTarget;
    }
    if ([self isStringEmpty:channelId]) {
        strategy = NCNoDisturbQueryStrategyCategory;
    }
    [self queryNotificationLevelWith:type
                            channelId:channelId
                           channelId:channelId
                            strategy:strategy
                       previousLevel:NCChannelNoDisturbLevelDefaultLevel
                          completion:completion];
}

+ (void)queryNotificationLevelWith:(NCChannelType)type
                          channelId:(NSString *__nullable)channelId
                         channelId:(NSString *__nullable)channelId
                          strategy:(NCNoDisturbQueryStrategy)strategy
                     previousLevel:(NCChannelNoDisturbLevel)previousLevel
                        completion:(void (^)(NCChannelNoDisturbLevel level))completion {
    if (strategy == NCNoDisturbQueryStrategyNone || previousLevel != NCChannelNoDisturbLevelDefaultLevel) {
        if (completion) {
            completion(previousLevel);
        }
        return;
    }
    NSString *strategyTargetId = channelId ?: @"";
    NSString *strategyChannelId = channelId ?: @"";
    if (strategy == NCNoDisturbQueryStrategyTarget) {
        strategyChannelId = @"";
    } else if (strategy == NCNoDisturbQueryStrategyCategory) {
        strategyTargetId = @"";
        strategyChannelId = @"";
    }

    NSString *key = [self keyStringWith:type channelId:strategyTargetId channelId:strategyChannelId];
    NCChannelNotificationDataContext *context = [self currentDataContext];
    __block NSNumber *cachedLevel = nil;
    [context.threadLock performReadLockBlock:^{
        cachedLevel = context.notificationInfo[key];
    }];
    if (cachedLevel) {
        [self queryNotificationLevelWith:type
                                channelId:channelId
                               channelId:channelId
                                strategy:strategy - 1
                           previousLevel:(NCChannelNoDisturbLevel)[cachedLevel integerValue]
                              completion:completion];
        return;
    }

    [self levelInfoInDBWith:type
                   channelId:strategyTargetId
                  channelId:strategyChannelId
                   strategy:strategy
                    success:^(NCChannelNoDisturbLevel level) {
        [context updateNotificationLevelWith:@(level) byKey:key];
        [self queryNotificationLevelWith:type
                                channelId:channelId
                               channelId:channelId
                                strategy:strategy - 1
                           previousLevel:level
                              completion:completion];
    } error:^(NSInteger status) {
        (void)status;
        [self queryNotificationLevelWith:type
                                channelId:channelId
                               channelId:channelId
                                strategy:strategy - 1
                           previousLevel:previousLevel
                              completion:completion];
    }];
}

#pragma mark - Data Source

+ (void)queryGlobalNotificationLevelInDB:(void(^)(NCNoDisturbTimeInfo *setting))successBlock
                                   error:(void (^)(NSInteger status))errorBlock {
    [NCEngine getNoDisturbTimeWithCompletion:^(NCNoDisturbTimeInfo * _Nullable info, NCError * _Nullable error) {
        if (!error && info) {
            if (successBlock) {
                successBlock(info);
            }
            return;
        }
        if (errorBlock) {
            errorBlock(error.code);
        }
    }];
}

+ (void)levelInfoInDBWith:(NCChannelType)type
                 channelId:(NSString *__nullable)channelId
                channelId:(NSString *__nullable)channelId
                 strategy:(NCNoDisturbQueryStrategy)strategy
                  success:(void (^)(NCChannelNoDisturbLevel level))successBlock
                    error:(void (^)(NSInteger status))errorBlock {
    if (strategy == NCNoDisturbQueryStrategyCategory) {
        [self levelInfoInDBWith:type success:successBlock error:errorBlock];
        return;
    }
    [self levelInfoInDBWith:type channelId:channelId channelId:channelId success:successBlock error:errorBlock];
}

+ (void)levelInfoInDBWith:(NCChannelType)type
                 channelId:(NSString *__nullable)channelId
                channelId:(NSString *__nullable)channelId
                  success:(void (^)(NCChannelNoDisturbLevel level))successBlock
                    error:(void (^)(NSInteger status))errorBlock {
    NSString *finalTargetId = channelId ?: @"";
    if (finalTargetId.length == 0) {
        if (successBlock) {
            successBlock(NCChannelNoDisturbLevelDefaultLevel);
        }
        return;
    }
    NCChannelIdentifier *identifier = nil;
    if (type == NCChannelTypeCommunity && channelId.length > 0) {
        identifier = [[NCCommunitySubChannelIdentifier alloc] initWithChannelId:finalTargetId
                                                                     subChannelId:channelId ?: @""];
    } else {
        identifier = [[NCChannelIdentifier alloc] initWithChannelType:type channelId:finalTargetId];
    }
    [NCBaseChannel getChannels:@[identifier] completion:^(NSArray<NCBaseChannel *> * _Nullable channels, NCError * _Nullable error) {
        if (!error && channels.firstObject) {
            if (successBlock) {
                successBlock(channels.firstObject.noDisturbLevel);
            }
            return;
        }
        if (errorBlock) {
            errorBlock(error.code);
        }
    }];
}

+ (void)levelInfoInDBWith:(NCChannelType)type
                  success:(void (^)(NCChannelNoDisturbLevel level))successBlock
                    error:(void (^)(NSInteger status))errorBlock {
    [NCBaseChannel getChannelTypeNoDisturbLevelWithChannelType:type completion:^(NCChannelNoDisturbLevel level, NCError * _Nullable error) {
        if (!error) {
            if (successBlock) {
                successBlock(level);
            }
            return;
        }
        if (errorBlock) {
            errorBlock(error.code);
        }
    }];
}

#pragma mark - Cache

+ (void)updateGlobalNotificationLevelWith:(NCNoDisturbTimeInfo *)setting {
    NCChannelNotificationDataContext *context = [self currentDataContext];
    [context.threadLock performWriteLockBlock:^{
        if (!setting || setting.startTime.length == 0 || setting.spanMinutes <= 0) {
            context.notificationInfo[NCChannelNotificationDataContextGlobalNotificationLevel] = @(NCChannelNoDisturbLevelDefaultLevel);
            context.dateBegin = nil;
            context.dateEnd = nil;
            return;
        }
        NSDate *begin = [context.formatter dateFromString:setting.startTime];
        if (!begin) {
            context.notificationInfo[NCChannelNotificationDataContextGlobalNotificationLevel] = @(NCChannelNoDisturbLevelDefaultLevel);
            context.dateBegin = nil;
            context.dateEnd = nil;
            return;
        }
        context.dateBegin = begin;
        context.dateEnd = [begin dateByAddingTimeInterval:setting.spanMinutes * 60];
        context.notificationInfo[NCChannelNotificationDataContextGlobalNotificationLevel] = @([self mapNoDisturbTimeLevelToChannelLevel:setting.level]);
    }];
}

- (void)updateNotificationLevelWith:(NSNumber *__nullable)level byKey:(NSString *)key {
    if (key.length == 0) {
        return;
    }
    [self.threadLock performWriteLockBlock:^{
        if (level) {
            self.notificationInfo[key] = level;
        } else {
            [self.notificationInfo removeObjectForKey:key];
        }
    }];
}

#pragma mark - Helpers

+ (NCChannelNotificationDataContext *)currentDataContext {
    return [NCChannelNotificationDataContext sharedInstence];
}

- (void)performOperationQueueBlock:(void (^)(void))task {
    if (!task) {
        return;
    }
    dispatch_async(self.notificationWorkQueue, task);
}

+ (NSString *)keyStringWith:(NCChannelType)type
                   channelId:(NSString *__nullable)channelId
                  channelId:(NSString *__nullable)channelId {
    return [NSString stringWithFormat:@"%ld%@%@%@%@",
            (long)type,
            NCChannelNotificationDataContextKeySeparator,
            channelId ?: @"",
            NCChannelNotificationDataContextKeySeparator,
            channelId ?: @""];
}

+ (BOOL)isStringEmpty:(NSString *)string {
    return (string == nil || string.length == 0);
}

+ (NCChannelNoDisturbLevel)mapNoDisturbTimeLevelToChannelLevel:(NCNoDisturbTimeLevel)level {
    switch (level) {
        case NCNoDisturbTimeLevelMention:
            return NCChannelNoDisturbLevelMention;
        case NCNoDisturbTimeLevelMuted:
            return NCChannelNoDisturbLevelMuted;
        case NCNoDisturbTimeLevelDefault:
        default:
            return NCChannelNoDisturbLevelDefaultLevel;
    }
}

@end
