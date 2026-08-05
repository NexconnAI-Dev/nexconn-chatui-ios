//
//  NCOldMessageNotificationMessage.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

#define NCOldMessageNotificationMessageTypeIdentifier @"RC:OldMsgNtf"
#ifndef NCInformationNotificationMessageIdentifier
#define NCInformationNotificationMessageIdentifier @"RC:InfoNtf"
#endif
#ifndef NCGroupNotificationMessageIdentifier
#define NCGroupNotificationMessageIdentifier @"RC:GrpNtf"
#endif

NS_ASSUME_NONNULL_BEGIN

/// Displays historical message text.
@interface NCOldMessageNotificationMessage : NCCustomMessageContent

+ (NSString *)messageType;

@end

@interface NCInformationNotificationMessage : NCCustomMessageContent

@property (nonatomic, copy) NSString *message;

+ (instancetype)notificationWithMessage:(NSString *)message extra:(nullable NSString *)extra;
- (NSString *)conversationDigest;

@end

@interface NCGroupNotificationMessage : NCCustomMessageContent

@property (nonatomic, copy) NSString *operation;
@property (nonatomic, copy) NSString *operatorUserId;
@property (nonatomic, copy) NSString *data;
@property (nonatomic, copy) NSString *message;

+ (instancetype)notificationWithOperation:(NSString *)operation
                           operatorUserId:(NSString *)operatorUserId
                                     data:(NSString *)data
                                  message:(NSString *)message
                                    extra:(nullable NSString *)extra;
- (NSString *)conversationDigest;

@end

NS_ASSUME_NONNULL_END
