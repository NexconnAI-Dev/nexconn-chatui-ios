//
//  NCReadWriteLock.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

/*
 //  This class wraps a read-write lock. Use it for short-running tasks.
 1. Only one thread can write at a time.
 2. Multiple threads can read at the same time.
 3. Reads and writes cannot happen at the same time.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCReadWriteLock : NSObject

// Creates an instance. Each call generates a new instance.
+ (instancetype)createRWLock;

// Locks for reading. Multiple threads can read at the same time.
- (void)performReadLockBlock:(dispatch_block_t)block;

// Locks for writing. Only one thread can write at a time.
- (void)performWriteLockBlock:(dispatch_block_t)block;

@end


NS_ASSUME_NONNULL_END
