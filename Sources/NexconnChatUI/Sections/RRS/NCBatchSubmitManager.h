//
//  NCBatchSubmitManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Batch submit result callback.

 @param code Submit result error code. 0 means success; other values mean failure.
 @param refillData Whether data should be refilled. Some failure cases need refill for retry.
 */
typedef void (^NCBatchSubmitResultCallback)(NSInteger code, BOOL refillData);

/**
 Batch submit callback.

 @param items Data list to submit.
 @param resultCallback Submit result callback. It must be called after the business logic finishes.
 */
typedef void (^NCBatchSubmitCallback)(NSArray *items, NCBatchSubmitResultCallback resultCallback);

/**
 Batch submit manager.
 Used to batch high-frequency operations and reduce the number of network requests.

 Features:
 1. Debounce: multiple calls within the specified delay are merged into one submit.
 2. State machine management: clear state transitions avoid race conditions.
 3. Thread safety: a unified state lock ensures multi-thread safety.
 4. Order guarantee: NSMutableOrderedSet preserves task insertion order.
 5. Deduplication guarantee: duplicate tasks are removed automatically, based on isEqual: and hash.
 6. Batch limit: at most 100 data items are submitted each time.
 7. Failure retry: failed data can be refilled to the head of the queue for priority processing.
 8. Connection-state awareness: task processing is automatically paused or resumed according to
 connection state.

 State machine:
 IDLE ⇄ ACTIVE

 State descriptions:
 - IDLE: idle state, with no pending data and no scheduled task.
 - ACTIVE: active state, with pending data or processing in progress.

 Connection-state awareness:
 - When disconnected: new tasks are only added to the queue, and submit does not start.
 - When the connection recovers: pending tasks in the queue are started automatically.

 @note Added data types must correctly implement isEqual: and hash to support deduplication.
 */
@interface NCBatchSubmitManager : NSObject

/**
 Sets the batch submit callback.

 @param callback Batch submit callback.
 */
- (void)setupSubmitCallback:(NCBatchSubmitCallback)callback;

/**
 Adds data to the batch processing queue.

 @param item Data to add. It is deduplicated automatically.
 @note Data types must correctly implement isEqual: and hash.
 */
- (void)addSubmitTask:(id)item;

/**
 Stops receiving connection status notifications while preserving internal state so remaining tasks
 can continue until completion.

 @note After this method is called, BatchSubmitManager no longer responds to connection state
 changes, but added tasks continue to execute until they complete or fail.
 */
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
