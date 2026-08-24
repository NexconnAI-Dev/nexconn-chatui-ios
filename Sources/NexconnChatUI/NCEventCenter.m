//
//  NCEventCenter.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCEventCenter.h"

@interface NCEventCenter ()

@property (nonatomic, strong)
    NSHashTable<id<NCChatUIConnectionStatusDelegate>> *connectionStatusDelegates;
@property (nonatomic, strong)
    NSHashTable<id<NCChatUINetworkStatusDelegate>> *networkStatusDelegates;

@end
@implementation NCEventCenter
+ (instancetype)sharedManager {
    static NCEventCenter *shareManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      shareManager = [[NCEventCenter alloc] init];
      shareManager.connectionStatusDelegates = [NSHashTable weakObjectsHashTable];
      shareManager.networkStatusDelegates = [NSHashTable weakObjectsHashTable];
    });
    return shareManager;
}

- (void)addConnectionStatusChangeDelegate:(id<NCChatUIConnectionStatusDelegate>)delegate {
    @synchronized(self) {
        if (delegate) {
            [self.connectionStatusDelegates addObject:delegate];
        }
    }
}

- (void)removeConnectionStatusChangeDelegate:(id<NCChatUIConnectionStatusDelegate>)delegate {
    @synchronized(self) {
        if (delegate) {
            [self.connectionStatusDelegates removeObject:delegate];
        }
    }
}

- (NSArray<id<NCChatUIConnectionStatusDelegate>> *)allConnectionStatusChangeDelegates {
    @synchronized(self) {
        return self.connectionStatusDelegates.allObjects;
    }
}

#pragma mark - Network Status Observers

- (void)addNetworkStatusChangeDelegate:(id<NCChatUINetworkStatusDelegate>)delegate {
    @synchronized(self) {
        if (delegate) {
            [self.networkStatusDelegates addObject:delegate];
        }
    }
}

- (void)removeNetworkStatusChangeDelegate:(id<NCChatUINetworkStatusDelegate>)delegate {
    @synchronized(self) {
        if (delegate) {
            [self.networkStatusDelegates removeObject:delegate];
        }
    }
}

- (NSArray<id<NCChatUINetworkStatusDelegate>> *)allNetworkStatusChangeDelegates {
    @synchronized(self) {
        return self.networkStatusDelegates.allObjects;
    }
}

@end
