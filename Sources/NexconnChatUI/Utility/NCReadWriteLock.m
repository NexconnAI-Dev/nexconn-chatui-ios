//
//  NCReadWriteLock.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCReadWriteLock.h"
// Imports
#import <pthread.h>

@interface NCReadWriteLock()
@property (nonatomic, assign) pthread_rwlock_t rwlock;
@end

@implementation NCReadWriteLock

+ (instancetype)createRWLock {
    return [[NCReadWriteLock alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_rwlock_init(&_rwlock, NULL);
    }
    return self;
}

- (void)performReadLockBlock:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    pthread_rwlock_rdlock(&_rwlock);
    block();
    pthread_rwlock_unlock(&_rwlock);
}

- (void)performWriteLockBlock:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    pthread_rwlock_wrlock(&_rwlock);
    block();
    pthread_rwlock_unlock(&_rwlock);
}

- (void)dealloc {
    pthread_rwlock_destroy(&_rwlock);
}
@end
