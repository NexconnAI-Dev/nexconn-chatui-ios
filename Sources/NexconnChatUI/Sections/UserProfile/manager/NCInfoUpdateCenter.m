//
//  NCInfoUpdateCenter.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCInfoUpdateCenter.h"
#import "NCChatUIUserInfo.h"
#import "NCChatUIGroup.h"

@implementation NCInfoUpdateCenter

+ (NSHashTable<id<NCInfoUpdateDelegate>> *)infoUpdateDelegates {
    static NSHashTable<id<NCInfoUpdateDelegate>> *delegates = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delegates = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality];
    });
    return delegates;
}

+ (void)addInfoUpdateDelegate:(id<NCInfoUpdateDelegate>)delegate {
    if (!delegate) {
        return;
    }
    NSHashTable<id<NCInfoUpdateDelegate>> *delegates = [self infoUpdateDelegates];
    @synchronized(delegates) {
        if (![delegates containsObject:delegate]) {
            [delegates addObject:delegate];
        }
    }
}

+ (void)removeInfoUpdateDelegate:(id<NCInfoUpdateDelegate>)delegate {
    if (!delegate) {
        return;
    }
    NSHashTable<id<NCInfoUpdateDelegate>> *delegates = [self infoUpdateDelegates];
    @synchronized(delegates) {
        [delegates removeObject:delegate];
    }
}

+ (NSArray<id<NCInfoUpdateDelegate>> *)infoUpdateDelegateSnapshot {
    NSHashTable<id<NCInfoUpdateDelegate>> *delegates = [self infoUpdateDelegates];
    @synchronized(delegates) {
        return delegates.allObjects;
    }
}

+ (BOOL)containsInfoUpdateDelegate:(id<NCInfoUpdateDelegate>)delegate {
    NSHashTable<id<NCInfoUpdateDelegate>> *delegates = [self infoUpdateDelegates];
    @synchronized(delegates) {
        return [delegates containsObject:delegate];
    }
}

+ (void)dispatchInfoUpdate:(dispatch_block_t)block {
    dispatch_async(dispatch_get_main_queue(), block);
}

#pragma mark -- dispatch update

+ (void)dispatchUserInfoUpdate:(NCChatUIUserInfo *)userInfo {
    if (!userInfo.userId) {
        return;
    }
    NSArray<id<NCInfoUpdateDelegate>> *delegates = [self infoUpdateDelegateSnapshot];
    [self dispatchInfoUpdate:^{
        for (id<NCInfoUpdateDelegate> delegate in delegates) {
            if (![self containsInfoUpdateDelegate:delegate]) {
                continue;
            }
            if ([delegate respondsToSelector:@selector(onUserInfoUpdate:)]) {
                [delegate onUserInfoUpdate:userInfo];
            }
        }
    }];
}

+ (void)dispatchGroupMemberInfoUpdate:(NCChatUIUserInfo *)userInfo
                               groupId:(NSString *)groupId {
    if (!groupId || !userInfo.userId) {
        return;
    }
    NSArray<id<NCInfoUpdateDelegate>> *delegates = [self infoUpdateDelegateSnapshot];
    [self dispatchInfoUpdate:^{
        for (id<NCInfoUpdateDelegate> delegate in delegates) {
            if (![self containsInfoUpdateDelegate:delegate]) {
                continue;
            }
            if ([delegate respondsToSelector:@selector(onGroupMemberInfoUpdate:groupId:)]) {
                [delegate onGroupMemberInfoUpdate:userInfo groupId:groupId];
            }
        }
    }];
}

+ (void)dispatchGroupInfoUpdate:(NCChatUIGroup *)groupInfo {
    if (groupInfo.groupId) {
        NSArray<id<NCInfoUpdateDelegate>> *delegates = [self infoUpdateDelegateSnapshot];
        [self dispatchInfoUpdate:^{
            for (id<NCInfoUpdateDelegate> delegate in delegates) {
                if (![self containsInfoUpdateDelegate:delegate]) {
                    continue;
                }
                if ([delegate respondsToSelector:@selector(onGroupInfoUpdate:)]) {
                    [delegate onGroupInfoUpdate:groupInfo];
                }
            }
        }];
    }
}

@end
