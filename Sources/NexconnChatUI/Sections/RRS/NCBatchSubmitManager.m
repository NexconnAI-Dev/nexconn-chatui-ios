//
//  NCBatchSubmitManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBatchSubmitManager.h"
#import <NexconnChatUI/NCChatUILog.h>
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <pthread.h>

/// Log tag.
static NSString *const kNCBatchSubmitManagerTag = @"NCBatchSubmitManager";
static NSString *const kNCBatchSubmitManagerConnectionStatusHandlerIdentifier = @"NCBatchSubmitManager";

/// Default delay in milliseconds.
static const NSInteger kDefaultDelayMs = 100;

/// Maximum number of items per submission.
static const NSInteger kMaxBatchSize = 100;

/**
 Batch submission state.
 */
typedef NS_ENUM(NSInteger, NCSubmitState) {
    NCSubmitStateIdle,      // No pending items or scheduled work.
    NCSubmitStateActive     // Items are pending or being processed.
};

@interface NCBatchSubmitManager () <NCConnectionStatusHandler> {
    /// Mutex protecting pending items and submission state across supported iOS versions.
    pthread_mutex_t _lock;
}

/// Pending items, kept in insertion order and deduplicated by NSMutableOrderedSet.
@property (nonatomic, strong) NSMutableOrderedSet *pendingItems;

/// Current submission state.
@property (nonatomic, assign) NCSubmitState currentState;

/// Submission delay in milliseconds.
@property (nonatomic, assign) NSInteger delayMs;

/// Batch submission callback.
@property (nonatomic, copy, nullable) NCBatchSubmitCallback submitCallback;

/// Cancellable delayed GCD block.
@property (nonatomic, strong) dispatch_block_t batchSubmitBlock;

/// Whether the SDK is connected.
@property (nonatomic, assign) BOOL isConnected;

@end

@implementation NCBatchSubmitManager

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize the mutex.
        pthread_mutex_init(&_lock, NULL);
        
        _pendingItems = [NSMutableOrderedSet orderedSet];
        _currentState = NCSubmitStateIdle;
        _delayMs = kDefaultDelayMs;
        _isConnected = [NCEngine getConnectionStatus] == NCConnectionStatusConnected;
        
        // Register for connection status changes.
        [NCEngine addConnectionStatusHandlerWithIdentifier:kNCBatchSubmitManagerConnectionStatusHandlerIdentifier
                                                   handler:self];
    }
    return self;
}

- (void)dealloc {
    [self invalidate];
    // Destroy the mutex.
    pthread_mutex_destroy(&_lock);
}

#pragma mark - Public Methods

- (void)setupSubmitCallback:(NCBatchSubmitCallback)callback {
    _submitCallback = callback;
}

- (void)addSubmitTask:(id)item {
    if (!item) {
        return;
    }
    
    pthread_mutex_lock(&_lock);
    
    // Add the item in insertion order; NSMutableOrderedSet deduplicates via isEqual: and hash.
    if ([self.pendingItems containsObject:item]) {
        pthread_mutex_unlock(&_lock);
        NCLogD(@"[%@] Item already exists in pending queue, skipped", kNCBatchSubmitManagerTag);
        return;
    }
    
    [self.pendingItems addObject:item];
    
    NCLogD(@"[%@] Added item to pending queue, total: %lu, state: %ld, connected: %d",
          kNCBatchSubmitManagerTag,
          (unsigned long)self.pendingItems.count,
          (long)self.currentState,
          self.isConnected);
    
    // Schedule new delayed work only while connected and idle.
    if (self.isConnected && self.currentState == NCSubmitStateIdle) {
        NCLogD(@"[%@] Scheduling delayed submit (state: IDLE -> ACTIVE)", kNCBatchSubmitManagerTag);
        [self scheduleDelayedSubmit];
        self.currentState = NCSubmitStateActive;
    } else {
        NCLogD(@"[%@] Not scheduling: connected=%d, state=%ld", 
              kNCBatchSubmitManagerTag,
              self.isConnected,
              (long)self.currentState);
    }
    // While disconnected, keep the item queued without scheduling work.
    pthread_mutex_unlock(&_lock);
}

- (void)invalidate {
    // Stop receiving connection status updates.
    [NCEngine removeConnectionStatusHandlerForIdentifier:kNCBatchSubmitManagerConnectionStatusHandlerIdentifier];
    NCLogD(@"[%@] Connection status listener removed", kNCBatchSubmitManagerTag);
}

#pragma mark - Private Methods

/**
 Schedule a delayed batch submission.
 
 @warning The caller must hold _lock while scheduling the block.
 */
- (void)scheduleDelayedSubmit {
    // The caller already holds _lock, so this method must not lock it again.
    
    // Cancel any previously scheduled block.
    if (self.batchSubmitBlock) {
        dispatch_block_cancel(self.batchSubmitBlock);
        self.batchSubmitBlock = nil;
    }
    
    // Create the delayed submission block.
    __weak typeof(self) weakSelf = self;
    dispatch_block_t block = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf executeBatchSubmit];
        }
    });
    
    self.batchSubmitBlock = block;
    
    // The block runs later on the main queue, after the scheduling caller has normally released _lock.
    NSTimeInterval delay = _delayMs / 1000.0;  // Access the ivar directly while the caller holds _lock.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   block);
}

/**
 Execute a batch submission.
 */
- (void)executeBatchSubmit {
    NSArray *itemsToSubmit = nil;
    NCBatchSubmitCallback callback = nil;
    
    pthread_mutex_lock(&_lock);
    if (self.pendingItems.count == 0) {
        // Return to idle when there is no pending work.
        self.currentState = NCSubmitStateIdle;
        pthread_mutex_unlock(&_lock);
        return;
    }
    
    // Submit at most 100 items and leave the remainder queued.
    NSInteger count = MIN(self.pendingItems.count, kMaxBatchSize);
    NSRange range = NSMakeRange(0, count);
    itemsToSubmit = [[self.pendingItems objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]] copy];
    
    // Remove this batch from the pending queue.
    [self.pendingItems removeObjectsInRange:range];
    
    callback = self.submitCallback;
    
    NCLogD(@"[%@] Preparing to submit %lu items, remaining: %lu",
          kNCBatchSubmitManagerTag,
          (unsigned long)itemsToSubmit.count,
          (unsigned long)self.pendingItems.count);
    pthread_mutex_unlock(&_lock);
    
    if (itemsToSubmit.count > 0 && callback) {
        __weak typeof(self) weakSelf = self;
        @try {
            callback(itemsToSubmit, ^(NSInteger code, BOOL refillData) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                NCLogD(@"[%@] Batch submit result: %ld, refillData: %d",
                      kNCBatchSubmitManagerTag,
                      (long)code,
                      refillData);
                
                // Reinsert failed items at the front so retries remain prioritized.
                if (refillData) {
                    [strongSelf refillData:itemsToSubmit];
                }
                
                [strongSelf onBatchSubmitComplete];
            });
        } @catch (NSException *exception) {
            NCLogD(@"[%@] Exception during batch submit: %@", kNCBatchSubmitManagerTag, exception);
            // Reinsert the batch at the front after an exception.
            [self refillData:itemsToSubmit];
            [self onBatchSubmitComplete];
        }
    } else {
        if (!callback) {
            NCLogD(@"[%@] No submit callback; discarding %lu items",
                  kNCBatchSubmitManagerTag,
                  (unsigned long)itemsToSubmit.count);
        }
        [self onBatchSubmitComplete];
    }
}

/**
 Reinsert items at the front of the queue.
 
 @param itemsToRefill Items to reinsert.
 */
- (void)refillData:(NSArray *)itemsToRefill {
    if (!itemsToRefill || itemsToRefill.count == 0) {
        return;
    }
    
    pthread_mutex_lock(&_lock);
    // Put reinserted items before the items already waiting in the queue.
    NSMutableOrderedSet *newPendingItems = [NSMutableOrderedSet orderedSetWithArray:itemsToRefill];
    [newPendingItems unionOrderedSet:_pendingItems];
    
    _pendingItems = newPendingItems;
    
    NCLogD(@"[%@] Refilled %lu items to queue head, total pending: %lu",
          kNCBatchSubmitManagerTag,
          (unsigned long)itemsToRefill.count,
          (unsigned long)_pendingItems.count);
    pthread_mutex_unlock(&_lock);
}

/**
 Handle batch submission completion.
 */
- (void)onBatchSubmitComplete {
    pthread_mutex_lock(&_lock);
    NCLogD(@"[%@] onBatchSubmitComplete called, pending items: %lu, state: %ld, connected: %d",
          kNCBatchSubmitManagerTag,
          (unsigned long)_pendingItems.count,
          (long)_currentState,
          self.isConnected);
    
    if (_pendingItems.count == 0) {
        // Return to idle when no new items are pending.
        _currentState = NCSubmitStateIdle;
        NCLogD(@"[%@] No pending items, state -> IDLE", kNCBatchSubmitManagerTag);
    } else if (self.isConnected) {
        // Stay active and schedule the next batch while connected.
        NCLogD(@"[%@] Has %lu pending items, scheduling next batch", 
              kNCBatchSubmitManagerTag, 
              (unsigned long)_pendingItems.count);
        [self scheduleDelayedSubmit];
    } else {
        // Return to idle while disconnected; connection recovery will restart submission.
        _currentState = NCSubmitStateIdle;
        NCLogD(@"[%@] Pending items remain while disconnected; waiting for connection recovery", kNCBatchSubmitManagerTag);
    }
    pthread_mutex_unlock(&_lock);
}

#pragma mark - NCConnectionStatusHandler

/**
 Handle a connection status change.
 */
- (void)onConnectionStatusChanged:(NCConnectionStatusChangedEvent *)event {
    NCConnectionStatus status = event.status;
    pthread_mutex_lock(&_lock);
    self.isConnected = (status == NCConnectionStatusConnected);
    NCLogD(@"[%@] Connection status changed: %ld, pending items: %lu",
          kNCBatchSubmitManagerTag,
          (long)status,
          (unsigned long)self.pendingItems.count);
    
    if (self.isConnected) {
        // On reconnection, schedule pending work when the manager is idle.
        if (self.pendingItems.count > 0 && self.currentState == NCSubmitStateIdle) {
            [self scheduleDelayedSubmit];
            self.currentState = NCSubmitStateActive;
        }
    }
    pthread_mutex_unlock(&_lock);
}

@end
