//
//  NCMessageSelectionUtility.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageSelectionUtility.h"
NSString *const NCMessageMultiSelectStatusChanged = @"NCMessageMultiSelectStatusChanged";

NSString *const NCNotificationMessagesMultiSelectedCountChanged = @"NCNotificationMessagesMultiSelectedCountChanged";

@interface NCMessageSelectionUtility ()
@property (nonatomic, strong) NSMutableArray<NCMessageModel *> *messages;
@end

@implementation NCMessageSelectionUtility
+ (instancetype)sharedManager {
    static NCMessageSelectionUtility *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[[self class] alloc] init];
        manager.messages = [NSMutableArray new];
    });
    return manager;
}

- (void)setMultiSelect:(BOOL)multiSelect {
    if (self.multiSelect != multiSelect) {
        _multiSelect = multiSelect;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NCMessageMultiSelectStatusChanged
                                                                object:@(multiSelect)];
        });
    } else {
        _multiSelect = multiSelect;
    }
}

- (void)addMessageModel:(NCMessageModel *)model {
    BOOL exectued = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(onMessagesMultiSelectedCountWillChanged:model:)]) {
        exectued =
            [self.delegate onMessagesMultiSelectedCountWillChanged:NCMessageMultiSelectStatusSelected model:model];
    }
    if (exectued && model && ![self isContainMessage:model]) {
        [self.messages addObject:model];
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onMessagesMultiSelectedCountDidChanged:model:)]) {
            [self.delegate onMessagesMultiSelectedCountDidChanged:NCMessageMultiSelectStatusSelected model:model];
        }
    }
}

- (void)removeMessageModel:(NCMessageModel *)model {
    BOOL exectued = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(onMessagesMultiSelectedCountWillChanged:model:)]) {
        exectued = [self.delegate onMessagesMultiSelectedCountWillChanged:NCMessageMultiSelectStatusCancelSelected
                                                                    model:model];
    }
    if (exectued) {
        [self.messages removeObject:model];
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onMessagesMultiSelectedCountDidChanged:model:)]) {
            [self.delegate onMessagesMultiSelectedCountDidChanged:NCMessageMultiSelectStatusCancelSelected model:model];
        }
    }
}

- (BOOL)isContainMessage:(NCMessageModel *)model {
    for (int i = 0; i < self.messages.count; i++) {
        NCMessageModel *tmp = self.messages[i];
        if (tmp.channelType == model.channelType && [tmp.channelId isEqualToString:model.channelId] &&
            tmp.clientId == model.clientId) {
            return YES;
        }
    }
    return NO;
}

- (void)removeMessageModelByMessage:(NCMessage *)message {
    if (self.messages.count == 0) {
        return;
    }
    if (!message || message.channelIdentifier.channelId.length == 0 || message.clientId <= 0) {
        return;
    }

    for (int i = 0; i < self.messages.count; i++) {
        NCMessageModel *tmp = self.messages[i];
        if (tmp.channelType == (NSInteger)message.channelIdentifier.channelType &&
            [tmp.channelId isEqualToString:message.channelIdentifier.channelId] &&
            tmp.clientId == message.clientId) {
            [self removeMessageModel:tmp];
            return;
        }
    }
}

- (NSArray<NCMessageModel *> *)selectedMessages {
    [self.messages sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        if (((NCMessageModel *)obj1).sentTime < ((NCMessageModel *)obj2).sentTime) {
            return NSOrderedAscending;
        } else if (((NCMessageModel *)obj1).sentTime == ((NCMessageModel *)obj2).sentTime) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];
    return self.messages;
}

- (void)removeAllMessages {
    [self.messages removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:NCNotificationMessagesMultiSelectedCountChanged
                                                        object:nil];
}

- (void)clear {
    [self.messages removeAllObjects];
    self.multiSelect = NO;
}
@end
