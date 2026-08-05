//
//  NCCombineMessageUtility.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCMessageModel;
@class NCCombineMessage;

NS_ASSUME_NONNULL_BEGIN

@interface NCCombineMessageUtility : NSObject

+ (NSString *)getCombineMessageSummaryTitle:(NCCombineMessage *)message;

+ (NSString *)getCombineMessagePreviewVCTitle:(NCCombineMessage *)message;

+ (NSString *)getCombineMessageSummaryContent:(NCCombineMessage *)message;

+ (BOOL)allSelectedCombineForwordMessagesAreLegal:(NSArray<NCMessageModel *> *)allSelectedMessages;

+ (BOOL)allSelectedOneByOneForwordMessagesAreLegal:(NSArray<NCMessageModel *> *)allSelectedMessages;

@end

NS_ASSUME_NONNULL_END
