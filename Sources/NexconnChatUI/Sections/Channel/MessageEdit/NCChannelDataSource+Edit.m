//
//  NCChannelDataSource+Edit.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelDataSource+Edit.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCChannelViewController.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIErrorCode.h"
#import "NCMessageModel+Edit.h"

@interface NCChannelDataSource ()

@property (nonatomic, weak) NCChannelViewController *chatVC;

@end

@implementation NCChannelDataSource (Edit)

- (void)edit_refreshReferenceMessage:(NSArray<NCMessage *> *)messages
                            complete:(void (^)(NSArray<NCMessage *> * _Nonnull))complete {

    if (self.chatVC.channelType != NCChannelTypeDirect
        && self.chatVC.channelType != NCChannelTypeGroup) {
        if (complete) {
            complete(messages);
        }
        return;
    }
    // Select reference messages from the result set.
    NSMutableArray *referenceMessages = [NSMutableArray array];
    for (NCMessage *message in messages) {
        NSString *messageId = [NCMessageModel edit_refreshableReferenceMessageUIdFromMessage:message];
        if (messageId.length > 0) {
            [referenceMessages addObject:messageId];
        }
    }
    if (referenceMessages.count == 0) {
        if (complete) {
            complete(messages);
        }
        return;
    }

    NCChannelIdentifier *channelIdentifier = [self edit_channelIdentifier];
    if (!channelIdentifier) {
        if (complete) {
            complete(messages);
        }
        return;
    }
    NCRefreshReferenceMessageParams *params =
        [[NCRefreshReferenceMessageParams alloc] initWithChannelIdentifier:channelIdentifier
                                                                messageIds:referenceMessages];
    
    // Start the local/remote result merge window.
    [self edit_setupCombineCallbackWithMessages:messages complete:complete];
    
    [NCBaseChannel refreshReferenceMessageWithParams:params localMessageHandler:^(NSArray<NCMessageResult *> * _Nonnull results) {
        [self edit_handleLocalResults:results];
    } remoteMessageHandler:^(NSArray<NCMessageResult *> * _Nonnull results) {
        [self edit_handleRemoteResults:results];
    } errorHandler:^(NCError * _Nullable error) {
        NCChatUIErrorCode code = error ? (NCChatUIErrorCode)error.code : NCChatUIErrorCodeMessageResponseTimeout;
        [self edit_handleError:code];
    }];
}

// Apply updated referenced-message state by message ID, then refresh affected list items.
- (void)edit_setUIReferenceMessagesEditStatus:(NCReferenceMessageStatus)status
                        forMessageIds:(NSArray<NSString *> *)messageIds {
    if (messageIds.count == 0) {
        return;
    }
    NSSet<NSString *> *uidSet = [NSSet setWithArray:messageIds];
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSArray<NCMessageModel *> *repository = self.chatVC.channelDataRepository;
    for (NSUInteger i = 0; i < repository.count; i++) {
        NCMessageModel *model = repository[i];
        NSString *referenceMessageUId = [model edit_referenceMessageUId];
        if (referenceMessageUId.length > 0 && [uidSet containsObject:referenceMessageUId]) {
            [model edit_setReferenceMessageStatus:status];
            model.cellSize = CGSizeZero;
            [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
        }
    }
    if (indexPaths.count == 0) {
        return;
    }
    dispatch_main_async_safe(^{
        [self.chatVC.messageCollectionView reloadItemsAtIndexPaths:indexPaths];
    });
}

- (void)edit_refreshUIMessagesEditedStatus:(NSArray<NCMessageModel *> *)models {
    if (models.count == 0 || self.chatVC.channelDataRepository.count == 0) {
        return;
    }
    
    NSDictionary<NSString *, NCMessageModel *> *newMessageDict = [self edit_buildUIdToModelDict:models];
    if (newMessageDict.count == 0) {
        return;
    }

    void (^updateCallback)(void) = ^{
        BOOL shouldKeepBottomAfterReload = [self isAtTheBottomOfTableView];
        NSArray<NCMessageModel *> *repository = self.chatVC.channelDataRepository;
        NSMutableDictionary<NSString *, NSNumber *> *uidToIndex = [NSMutableDictionary dictionaryWithCapacity:repository.count];
        NSMutableDictionary<NSString *, NSMutableIndexSet *> *referUidToIndexes = [NSMutableDictionary dictionary];

        [self edit_buildRepositoryIndexes:repository
                               uidToIndex:uidToIndex
                        referUidToIndexes:referUidToIndexes];

        NSIndexSet *needUpdateIndexes = [self edit_applyUpdatesWithNewMessageDict:newMessageDict
                                                                       repository:repository
                                                                       uidToIndex:uidToIndex
                                                                referUidToIndexes:referUidToIndexes];
        if (needUpdateIndexes.count > 0) {
            [self reloadCollectionViewAtIndexes:needUpdateIndexes keepBottomIfNeeded:shouldKeepBottomAfterReload];
        }
    };
    
    // Perform collection view updates on the main thread.
    if ([NSThread isMainThread]) {
        updateCallback();
    } else {
        dispatch_async(dispatch_get_main_queue(), updateCallback);
    }
}

#pragma mark - Private Helpers

- (nullable NCChannelIdentifier *)edit_channelIdentifier {
    NSString *channelId = self.chatVC.channelId ?: @"";
    switch (self.chatVC.channelType) {
        case NCChannelTypeDirect:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeDirect
                                                          channelId:channelId];
        case NCChannelTypeGroup:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeGroup
                                                          channelId:channelId];
        case NCChannelTypeSystem:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeSystem
                                                          channelId:channelId];
        default:
            return nil;
    }
}

- (BOOL)edit_isNewMessageModel:(NCMessageModel *)newModel olderThanCurrentModel:(NCMessageModel *)currentModel {
    long long currentTimestamp = currentModel.updateInfo.timestamp;
    if (currentTimestamp <= 0) {
        return NO;
    }
    long long newTimestamp = newModel.updateInfo.timestamp;
    if (newTimestamp <= 0) {
        return YES;
    }
    return newTimestamp < currentTimestamp;
}

// Build a messageId-to-model lookup table.
- (NSDictionary<NSString *, NCMessageModel *> *)edit_buildUIdToModelDict:(NSArray<NCMessageModel *> *)models {
    if (models.count == 0) {
        return @{};
    }
    NSMutableDictionary<NSString *, NCMessageModel *> *dict = [NSMutableDictionary dictionaryWithCapacity:models.count];
    for (NCMessageModel *model in models) {
        if (model.messageId.length > 0 && model.content) {
            dict[model.messageId] = model;
        }
    }
    return dict.copy;
}

// Build messageId-to-index and referenced-messageId-to-index-set lookup tables.
- (void)edit_buildRepositoryIndexes:(NSArray<NCMessageModel *> *)repository
                         uidToIndex:(NSMutableDictionary<NSString *, NSNumber *> *)uidToIndex
                  referUidToIndexes:(NSMutableDictionary<NSString *, NSMutableIndexSet *> *)referUidToIndexes {
    for (NSUInteger idx = 0; idx < repository.count; idx++) {
        NCMessageModel *model = repository[idx];
        if (model.messageId.length > 0) {
            uidToIndex[model.messageId] = @(idx);
        }
        NSString *referenceMessageUId = [model edit_referenceMessageUId];
        if (referenceMessageUId.length > 0) {
            NSMutableIndexSet *set = referUidToIndexes[referenceMessageUId];
            if (!set) {
                set = [NSMutableIndexSet indexSet];
                referUidToIndexes[referenceMessageUId] = set;
            }
            [set addIndex:idx];
        }
    }
}

// Apply message updates and return the affected indexes.
- (NSIndexSet *)edit_applyUpdatesWithNewMessageDict:(NSDictionary<NSString *, NCMessageModel *> *)newMessageDict
                                         repository:(NSArray<NCMessageModel *> *)repository
                                         uidToIndex:(NSDictionary<NSString *, NSNumber *> *)uidToIndex
                                  referUidToIndexes:(NSDictionary<NSString *, NSMutableIndexSet *> *)referUidToIndexes {
    NSMutableIndexSet *needUpdateIndexes = [NSMutableIndexSet indexSet];
    
    [newMessageDict enumerateKeysAndObjectsUsingBlock:^(NSString *uid, NCMessageModel *newModel, BOOL *stop) {
        NSNumber *indexNumber = uidToIndex[uid];
        if (indexNumber) {
            NSUInteger idx = indexNumber.unsignedIntegerValue;
            NCMessageModel *oldModel = repository[idx];
            if ([self edit_isNewMessageModel:newModel olderThanCurrentModel:oldModel]) {
                return;
            }

            if ([oldModel edit_hasReferenceMessage] && [newModel edit_hasReferenceMessage]) {
                NCReferenceMessageStatus oldStatus = [oldModel edit_referenceMessageStatus];
                NCReferenceMessageStatus newStatus = [newModel edit_referenceMessageStatus];
                if (oldStatus > newStatus) {
                    [newModel edit_setReferenceMessageStatus:oldStatus];
                }
            }
            
            oldModel.content = newModel.content;
            oldModel.updateInfo = newModel.updateInfo;
            oldModel.hasChanged = newModel.hasChanged;
            oldModel.cellSize = CGSizeZero;
            [needUpdateIndexes addIndex:idx];
        }
        
        NSMutableIndexSet *refIndexes = referUidToIndexes[uid];
        if (refIndexes.count > 0) {
            [refIndexes enumerateIndexesUsingBlock:^(NSUInteger refIdx, BOOL *stopRef) {
                NCMessageModel *refModel = repository[refIdx];
                if (![refModel edit_hasReferenceMessage]) {
                    return;
                }
                
                if (newModel.hasChanged) {
                    [refModel edit_setReferenceMessageStatus:NCReferenceMessageStatusUpdated];
                }
                [refModel edit_updateReferencedMessagePreviewContentFromModel:newModel];
                
                refModel.cellSize = CGSizeZero;
                [needUpdateIndexes addIndex:refIdx];
            }];
        }
    }];
    
    return needUpdateIndexes.copy;
}

/// Reloads the affected collection view items.
- (void)reloadCollectionViewAtIndexes:(NSIndexSet *)indexes {
    [self reloadCollectionViewAtIndexes:indexes keepBottomIfNeeded:NO];
}

/// Reloads affected items and preserves the bottom position when already pinned there.
- (void)reloadCollectionViewAtIndexes:(NSIndexSet *)indexes keepBottomIfNeeded:(BOOL)keepBottom {
    if (indexes.count == 0) return;
    
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray arrayWithCapacity:indexes.count];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
    }];
    
    @try {
        [self.chatVC.messageCollectionView reloadItemsAtIndexPaths:indexPaths];
    } @catch (NSException *exception) {
        NCLogE(@"CollectionView reload failed: %@", exception.reason);
        // Reload the full collection view when item updates cannot be applied safely.
        [self.chatVC.messageCollectionView reloadData];
    }
    [self edit_scrollToBottomAfterEditedMessageReloadIfNeeded:keepBottom];
}

- (void)edit_scrollToBottomAfterEditedMessageReloadIfNeeded:(BOOL)keepBottom {
    if (!keepBottom) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf.chatVC.messageCollectionView setNeedsLayout];
        [strongSelf.chatVC.messageCollectionView layoutIfNeeded];
        [strongSelf.chatVC scrollToBottomAnimated:NO];
    });
}

#pragma mark - Local and Remote Result Merging

/**
 * Starts the result merge window and timeout.
 * @param messages The original message list.
 * @param complete The completion callback.
 */
- (void)edit_setupCombineCallbackWithMessages:(NSArray<NCMessage *> *)messages 
                                complete:(void (^)(NSArray<NCMessage *> *))complete {
    // Clear any previous merge state.
    [self edit_cleanupCombineState];
    
    // Retain the original messages and completion callback.
    self.pendingLocalMessages = messages;
    self.pendingCompleteBlock = complete;
    self.isWaitingForRemoteResults = YES;
    
    // Limit the merge window to 1000 ms.
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.combineTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(self.combineTimer, dispatch_time(DISPATCH_TIME_NOW, 1000 * NSEC_PER_MSEC), DISPATCH_TIME_FOREVER, 0);
    dispatch_source_set_event_handler(self.combineTimer, ^{
        [weakSelf edit_handleCombineTimeout];
    });
    dispatch_resume(self.combineTimer);
}

/**
 * Applies local query results while the merge window is active.
 * @param results The locally queried messages.
 */
- (void)edit_handleLocalResults:(NSArray<NCMessageResult *> *)results {
    if (!self.isWaitingForRemoteResults) {
        return;
    }
    
    // Replace message content when local results are available.
    if (results.count > 0) {
        NSArray *updatedMessages = [self edit_replaceMessages:self.pendingLocalMessages withResults:results];
        self.pendingLocalMessages = updatedMessages;
    }
    
    // Continue waiting for remote results or the timeout.
}

/**
 * Applies remote query results.
 * @param results The remotely queried messages.
 */
- (void)edit_handleRemoteResults:(NSArray<NCMessageResult *> *)results {
    if (!self.isWaitingForRemoteResults) {
        // Refresh remote reference results independently after the merge window closes.
        [self edit_handleRemoteReferenceMessageResults:results];
        return;
    }
    
    // Merge remote results that arrive within the active window.
    self.pendingRemoteResults = results;
    [self edit_executeCombinedCallback];
}

/**
 * Completes the merge when the timeout expires.
 */
- (void)edit_handleCombineTimeout {
    if (!self.isWaitingForRemoteResults) {
        return;
    }
    
    // Return local results now; later remote results are handled independently.
    [self edit_executeCombinedCallback];
}

/**
 * Handles a query failure.
 * @param code The query error code.
 */
- (void)edit_handleError:(NCChatUIErrorCode)code {
    void (^completeBlock)(NSArray<NCMessage *> *) = self.pendingCompleteBlock;
    NSArray<NCMessage *> *originalMessages = self.pendingLocalMessages;
    (void)code;
    
    [self edit_cleanupCombineState];
    
    if (completeBlock) {
        // Preserve the original messages when the query fails.
        completeBlock(originalMessages);
    }
}

/**
 * Completes the active result merge.
 */
- (void)edit_executeCombinedCallback {
    if (!self.isWaitingForRemoteResults) {
        return;
    }
    
    // Snapshot the current merge state.
    NSArray<NCMessage *> *localMessages = self.pendingLocalMessages;
    NSArray<NCMessageResult *> *remoteResults = self.pendingRemoteResults;
    void (^completeBlock)(NSArray<NCMessage *> *) = self.pendingCompleteBlock;
    
    // Clear state before invoking the callback to prevent duplicate completion.
    [self edit_cleanupCombineState];
    
    if (completeBlock) {
        // Apply any remote replacements to the local message snapshot.
        NSArray *finalMessages = localMessages;
        if (remoteResults.count > 0) {
            finalMessages = [self edit_replaceMessages:finalMessages withResults:remoteResults];
        }
        // Return the merged message list.
        completeBlock(finalMessages);
    }
}

/**
 * Clears the result merge state.
 */
- (void)edit_cleanupCombineState {
    self.isWaitingForRemoteResults = NO;
    
    // Cancel and release the timeout source.
    if (self.combineTimer) {
        dispatch_source_cancel(self.combineTimer);
        self.combineTimer = nil;
    }
    
    // Release cached merge data.
    self.pendingRemoteResults = nil;
    self.pendingLocalMessages = nil;
    self.pendingCompleteBlock = nil;
}

#pragma mark - Private Methods

- (NSArray<NCMessage *> *)edit_replaceMessages:(NSArray<NCMessage *> *)messages
                                   withResults:(NSArray<NCMessageResult *> *)results {
    if (messages.count == 0 && results.count == 0) {
        return nil;
    }
    if (results.count == 0) {
        return messages;
    }
    // Build a message ID lookup to avoid an O(n*m) nested scan.
    NSMutableDictionary<NSString *, NCMessage *> *uidToMessage = [NSMutableDictionary dictionaryWithCapacity:results.count];
    for (NCMessageResult *result in results) {
        NCMessage *message = result.message;
        if (result.messageId.length > 0 && message) {
            uidToMessage[result.messageId] = message;
        }
    }
    if (uidToMessage.count == 0) {
        return messages;
    }
    NSMutableArray *finalMessages = [NSMutableArray arrayWithCapacity:messages.count];
    for (NCMessage *message in messages) {
        NCMessage *replacement = uidToMessage[message.messageId];
        [finalMessages addObject:(replacement ?: message)];
    }
    return finalMessages;
}

- (void)edit_handleRemoteReferenceMessageResults:(NSArray<NCMessageResult *> *)results {
    if (results.count == 0) {
        return;
    }
    NSMutableArray *models = [NSMutableArray array];
    for (NCMessageResult *result in results) {
        NCMessage *message = result.message;
        if (message.content) {
            NCMessageModel *model = [NCMessageModel modelWithNCMessage:message];
            if (model) {
                [models addObject:model];
            }
        }
    }
    [self edit_refreshUIMessagesEditedStatus:models];
}

@end
