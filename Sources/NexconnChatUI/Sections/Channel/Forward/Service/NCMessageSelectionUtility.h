//
//  NCMessageSelectionUtility.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageModel.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    NCMessageMultiSelectStatusSelected = 0,
    NCMessageMultiSelectStatusCancelSelected,
} NCMessageMultiSelectStatus;
/// The message cell selection status changed.
UIKIT_EXTERN NSString *const NCMessageMultiSelectStatusChanged;

/// Delegate for changes to the message cell selection count.
@protocol NCMessagesMultiSelectedProtocol <NSObject>
@optional
/*!
Callback before the message cell selection count changes.

- Parameter status: The message cell selection status.
- Parameter model: The message cell data model.
*/
- (BOOL)onMessagesMultiSelectedCountWillChanged:(NCMessageMultiSelectStatus)status
                                          model:(NCMessageModel *)model;

/*!
Callback after the message cell selection count changes.

- Parameter status: The message cell selection status.
- Parameter model: The message cell data model.
*/
- (void)onMessagesMultiSelectedCountDidChanged:(NCMessageMultiSelectStatus)status
                                         model:(NCMessageModel *)model;

@end

@interface NCMessageSelectionUtility : NSObject
// Forward
@property (nonatomic, assign) BOOL multiSelect;
@property (nonatomic, weak) id<NCMessagesMultiSelectedProtocol> delegate;

+ (instancetype)sharedManager;
- (void)addMessageModel:(NCMessageModel *)model;
- (void)removeMessageModel:(NCMessageModel *)model;
- (BOOL)isContainMessage:(NCMessageModel *)model;
- (NSArray<NCMessageModel *> *)selectedMessages;
- (void)removeAllMessages;
- (void)clear;
- (void)removeMessageModelByMessage:(NCMessage *)message;
@end
