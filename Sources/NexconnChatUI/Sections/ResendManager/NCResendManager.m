//
//  NCResendManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCResendManager.h"
#import <NexconnChatUI/NCChatUILog.h>
#import "NCChatUIErrorCode.h"
#import "NCChatUI.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"

static NSString *const NCResendManagerConnectionStatusHandlerIdentifier = @"NCResendManager";

@interface NCResendManager () <NCConnectionStatusHandler>

@property (nonatomic, strong) NSMutableArray *messageClientIds;

@property (nonatomic, strong) NSMutableDictionary *messageCacheDict;

@property (nonatomic, strong) NSTimer *resendTimer;

@property (nonatomic, assign) BOOL isProcessing;

@property (nonatomic, strong) NSString *currentUserId;

@end

static BOOL NCResendShouldNeedReadReceipt(NCChannelType channelType) {
    return channelType == NCChannelTypeDirect || channelType == NCChannelTypeGroup;
}

static NCBaseChannel *NCResendChannelFromIdentifier(NCChannelIdentifier *identifier) {
    if (!identifier || identifier.channelId.length == 0) {
        return nil;
    }
    switch (identifier.channelType) {
        case NCChannelTypeDirect:
            return [[NCDirectChannel alloc] initWithChannelId:identifier.channelId];
        case NCChannelTypeGroup:
            return [[NCGroupChannel alloc] initWithChannelId:identifier.channelId];
        case NCChannelTypeSystem:
            return [[NCSystemChannel alloc] initWithChannelId:identifier.channelId];
        case NCChannelTypeCommunity: {
            NSString *subChannelId =
                [identifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]
                    ? (((NCCommunitySubChannelIdentifier *)identifier).subChannelId ?: @"")
                    : @"";
            return [[NCCommunitySubChannel alloc] initWithChannelId:identifier.channelId
                                                        subChannelId:subChannelId];
        }
        default:
            return nil;
    }
}

@implementation NCResendManager

+ (instancetype)sharedManager {
    static NCResendManager *resendManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (resendManager == nil) {
            resendManager = [[NCResendManager alloc] init];
        }
    });
    return resendManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.currentUserId = [NCEngine getCurrentUserId];
        self.messageCacheDict = [[NSMutableDictionary alloc] init];
        self.messageClientIds = [[NSMutableArray alloc] init];
        [NCEngine addConnectionStatusHandlerWithIdentifier:NCResendManagerConnectionStatusHandlerIdentifier
                                                   handler:self];
    }
    return self;
}

- (void)dealloc {
    [NCEngine removeConnectionStatusHandlerForIdentifier:NCResendManagerConnectionStatusHandlerIdentifier];
}

- (BOOL)needResend:(long)clientId {
    NSString *key = [NSString stringWithFormat:@"%ld", clientId];
    if ([self.messageCacheDict valueForKey:key]) {
        return YES;
    }
    return NO;
}

- (BOOL)isResendErrorCode:(NCChatUIErrorCode)code {
    NCConnectionStatus status = [[NCChatUI shared] getConnectionStatus];
    if (NCConnectionStatusKickedOfflineByOtherClient == status ||
        NCConnectionStatusSignOut == status ||
        NCConnectionStatusUserAbandon == status ||
        NCConnectionStatusProxyUnavailable == status){
        return NO;
    }
    if (code == NCChatUIErrorCodeChannelInvalid ||
        code == NCChatUIErrorCodeNetworkUnavailable ||
        code == NCChatUIErrorCodeMessageResponseTimeout ||
        code == NCChatUIErrorCodeFileUploadFailed) {
        return YES;
    }
    return NO;
}

- (void)addResendMessageIfNeed:(long)clientId error:(NCChatUIErrorCode)code {
    dispatch_main_async_safe((^{
        if (NCChatUIConfigCenter.message.enableMessageResend && [self isResendErrorCode:code]) {
            NSString *key = [NSString stringWithFormat:@"%ld", clientId];
            if (![self.messageCacheDict objectForKey:key]) {
                NCGetMessageByIdParams *params = [[NCGetMessageByIdParams alloc] initWithMessageClientId:clientId];
                [NCBaseChannel getMessageByIdWithParams:params completion:^(NCMessage * _Nullable message, NCError * _Nullable error) {
                    (void)error;
                    if (!message) {
                        return;
                    }
                    dispatch_main_async_safe(^{
                        if ([self.messageCacheDict objectForKey:key]) {
                            return;
                        }
                        [self.messageCacheDict setObject:message forKey:key];
                        [self.messageClientIds addObject:key];
                        [self beginResend];
                    });
                }];
            }
        }
    }));
}

- (void)removeResendMessage:(long)clientId {
    // This method normally runs on the main thread.
    NSString *key = [NSString stringWithFormat:@"%ld", clientId];
    [self.messageCacheDict removeObjectForKey:key];
    [self.messageClientIds removeObject:key];
    NCLogI(@"%s messageClientId is %ld", __FUNCTION__, clientId);
}

- (void)removeAllResendMessage {
    // This method normally runs on the main thread.
    [self.messageCacheDict removeAllObjects];
    [self.messageClientIds removeAllObjects];
    self.isProcessing = NO;
}

- (void)beginResend {
    // This method normally runs on the main thread.
    if (self.isProcessing) {
        return;
    }
    self.isProcessing = YES;
    [self sendAfterTimer];
}

//loop
- (void)sendAfterTimer {
    // This method normally runs on the main thread.
    self.resendTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(sendFirstMessage) userInfo:nil repeats:NO];
}

- (void)sendFirstMessage {
    // This method normally runs on the main thread.
    if (self.messageClientIds.count == 0) {
        self.isProcessing = NO;
        NCLogI(@"%s no message need resend", __FUNCTION__);
        return;
    }
    if ([[NCChatUI shared] getConnectionStatus] != NCConnectionStatusConnected) {
        NCLogI(@"connectionStatus is not connected");
        self.isProcessing = NO;
        return;
    }
    NSString *messageClientId = [self.messageClientIds firstObject];
    NCMessage *message = self.messageCacheDict[messageClientId];
    if (!message) {
        [self.messageClientIds removeObject:messageClientId];
        [self sendAfterTimer];
        return;
    }
    NCLogI(@"%s messageClientId is %lld, message is %@", __FUNCTION__, message.clientId, message.messageType);
    [self resendMessage:message];
}

- (void)resendMessage:(NCMessage *)message {
    // This method normally runs on the main thread.
    id messageContent = message.content;
    NCChannelIdentifier *identifier = message.channelIdentifier;
    if (identifier.channelId.length == 0 || messageContent == nil) {
        NCLogI(@"%s channelId or messageContent is nil", __FUNCTION__);
        [self removeResendMessage:(long)message.clientId];
        [self sendAfterTimer];
        return;
    }

    if (![messageContent isKindOfClass:[NCMessageContent class]]) {
        NCLogI(@"%s skip resend for non-NC message content", __FUNCTION__);
        [self removeResendMessage:(long)message.clientId];
        [self sendAfterTimer];
        return;
    }
    
    NCMessageContent *ncMessageContent = (NCMessageContent *)messageContent;
    NCChannelType channelType = identifier.channelType;
    NSString *channelId = identifier.channelId ?: @"";
    NSString *subChannelId =
        [identifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]
            ? (((NCCommunitySubChannelIdentifier *)identifier).subChannelId ?: @"")
            : @"";
    NCBaseChannel *channel = NCResendChannelFromIdentifier(identifier);
    if (!channel) {
        [self removeResendMessage:(long)message.clientId];
        [self sendAfterTimer];
        return;
    }

    if ([ncMessageContent isKindOfClass:[NCMediaMessageContent class]]) {
        
        if ([ncMessageContent isMemberOfClass:NCImageMessage.class]) {
            NCImageMessage *imageMessage = (NCImageMessage *)ncMessageContent;
            if (imageMessage.localPath.length > 0) {
                imageMessage.originalImage = [UIImage imageWithContentsOfFile:imageMessage.localPath];
            } else {
                imageMessage.originalImage = nil;
            }
        }
        
        NCChatUISendMediaMessageParams *params =
            [[NCChatUISendMediaMessageParams alloc] initWithContent:(NCMediaMessageContent *)ncMessageContent];
        params.channelType = channelType;
        params.channelId = channelId;
        params.subChannelId = subChannelId;
        params.needReceipt = NCResendShouldNeedReadReceipt(channelType);
        NCSendMediaMessageParams *sendParams =
            [[NCSendMediaMessageParams alloc] initWithContent:(NCMediaMessageContent *)ncMessageContent];
        sendParams.needReceipt = params.needReceipt;
        [channel sendMediaMessageWithParams:sendParams
                            attachedHandler:nil
                            progressHandler:^(NSInteger progress, NCMessage * _Nullable progressMessage) {
            dispatch_main_async_safe(^{
                [self postSendMessageNotificationWithMessage:progressMessage ?: message
                                          originalClientId:(long)message.clientId
                                                 sentStatus:NCMessageSentStatusSending
                                                      error:NCChatUIErrorCodeSuccess
                                                   progress:@(progress)
                                                 markResend:NO];
            });
        }
                          completionHandler:^(NCMessage * _Nullable successMessage, NCError * _Nullable error) {
            dispatch_main_async_safe(^{
                if (!successMessage || error) {
                    NCChatUIErrorCode resendErrorCode = (NCChatUIErrorCode)error.code;
                    long latestClientId = (long)successMessage.clientId;
                    if (latestClientId > 0 && latestClientId != (long)message.clientId) {
                        [self deleteLocalMessageIfNeeded:latestClientId];
                    }
                    if (![self isResendErrorCode:resendErrorCode]) {
                        [self removeResendMessage:(long)message.clientId];
                    }
                    [self postSendMessageNotificationWithMessage:message
                                              originalClientId:(long)message.clientId
                                                     sentStatus:NCMessageSentStatusFailed
                                                          error:resendErrorCode
                                                       progress:nil
                                                     markResend:YES];
                    [self sendAfterTimer];
                    return;
                }
                [self deleteLocalMessageIfNeeded:(long)message.clientId];
                [self removeResendMessage:(long)message.clientId];
                [self postSendMessageNotificationWithMessage:successMessage
                                          originalClientId:(long)message.clientId
                                                 sentStatus:NCMessageSentStatusSent
                                                      error:NCChatUIErrorCodeSuccess
                                                   progress:nil
                                                 markResend:NO];
                [self sendAfterTimer];
            });
        }
                              cancelHandler:^(NCMessage * _Nullable cancelMessage) {
            dispatch_main_async_safe(^{
                long cancelMessageId = (long)cancelMessage.clientId;
                if (cancelMessageId > 0 && cancelMessageId != (long)message.clientId) {
                    [self deleteLocalMessageIfNeeded:cancelMessageId];
                }
                [self removeResendMessage:(long)message.clientId];
                [self postSendMessageNotificationWithMessage:message
                                          originalClientId:(long)message.clientId
                                                 sentStatus:NCMessageSentStatusCanceled
                                                      error:NCChatUIErrorCodeSuccess
                                                   progress:nil
                                                 markResend:NO];
                [self sendAfterTimer];
            });
        }];
    } else {
        NCChatUISendMessageParams *params = [[NCChatUISendMessageParams alloc] initWithContent:ncMessageContent];
        params.channelType = channelType;
        params.channelId = channelId;
        params.subChannelId = subChannelId;
        params.needReceipt = NCResendShouldNeedReadReceipt(channelType);
        NCSendMessageParams *sendParams = [[NCSendMessageParams alloc] initWithContent:ncMessageContent];
        sendParams.needReceipt = params.needReceipt;
        [channel sendMessageWithParams:sendParams
                       attachedHandler:nil
                     completionHandler:^(NCMessage * _Nullable successMessage, NCError * _Nullable error) {
            dispatch_main_async_safe(^{
                if (!successMessage || error) {
                    NCChatUIErrorCode resendErrorCode = (NCChatUIErrorCode)error.code;
                    long latestClientId = (long)successMessage.clientId;
                    if (latestClientId > 0 && latestClientId != (long)message.clientId) {
                        [self deleteLocalMessageIfNeeded:latestClientId];
                    }
                    if (![self isResendErrorCode:resendErrorCode]) {
                        [self removeResendMessage:(long)message.clientId];
                    }
                    [self postSendMessageNotificationWithMessage:message
                                              originalClientId:(long)message.clientId
                                                     sentStatus:NCMessageSentStatusFailed
                                                          error:resendErrorCode
                                                       progress:nil
                                                     markResend:YES];
                    [self sendAfterTimer];
                    return;
                }
                [self deleteLocalMessageIfNeeded:(long)message.clientId];
                [self removeResendMessage:(long)message.clientId];
                [self postSendMessageNotificationWithMessage:successMessage
                                          originalClientId:(long)message.clientId
                                                 sentStatus:NCMessageSentStatusSent
                                                      error:NCChatUIErrorCodeSuccess
                                                   progress:nil
                                                 markResend:NO];
                [self sendAfterTimer];
            });
        }];
    }
}

- (void)postSendMessageNotificationWithMessage:(NCMessage *)message
                              originalClientId:(long)originalClientId
                                     sentStatus:(NCMessageSentStatus)sentStatus
                                          error:(NCChatUIErrorCode)nErrorCode
                                       progress:(NSNumber *)progress
                                     markResend:(BOOL)markResend {
    if (!message) {
        return;
    }
    long notifyMessageId = originalClientId > 0 ? originalClientId : (long)message.clientId;
    NCChannelIdentifier *identifier = message.channelIdentifier;
    NSMutableDictionary *statusDic = [@{
        @"channelType" : @(identifier.channelType),
        @"channelId" : identifier.channelId ?: @"",
        @"clientId" : @(notifyMessageId),
        @"sentStatus" : @(sentStatus),
        @"content" : message.content ?: [NSNull null],
        @"message" : message
    } mutableCopy];
    if (progress) {
        statusDic[@"progress"] = progress;
    }
    if (nErrorCode != NCChatUIErrorCodeSuccess) {
        statusDic[@"error"] = @(nErrorCode);
    }
    if (markResend) {
        statusDic[@"resend"] = @"resend";
    }
    if ([identifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]) {
        statusDic[@"subChannelId"] =
            ((NCCommunitySubChannelIdentifier *)identifier).subChannelId ?: @"";
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NCUISendingMessageNotification"
                                                        object:nil
                                                      userInfo:statusDic];
}

- (void)deleteLocalMessageIfNeeded:(long)clientId {
    if (clientId <= 0) {
        return;
    }
    [NCBaseChannel deleteLocalMessages:@[ @(clientId) ] completion:nil];
}

- (void)onConnectionStatusChangedNotification:(NSNotification *)status {
    dispatch_main_async_safe(^{
        NCLogI(@"connection status changed");
        NCConnectionStatus connectionStatus = [status.object integerValue];
        switch (connectionStatus) {
            case NCConnectionStatusConnected: {
                if ([self.currentUserId isEqualToString:[NCEngine getCurrentUserId]]){
                    if (!self.isProcessing) {
                        [self beginResend];
                    }
                }else{
                    self.currentUserId = [NCEngine getCurrentUserId];
                    [self removeAllResendMessage];
                }
            } break;
            // Since 5.3.0, sign-out, timeout, and unavailable proxy errors immediately show send failure.
            // Since 5.3.1, kicked-offline errors immediately show send failure.
            case NCConnectionStatusKickedOfflineByOtherClient:
            case NCConnectionStatusSignOut:
            case NCConnectionStatusTimeout:
            case NCConnectionStatusProxyUnavailable: {
                [self removeAllResendMessage];
            } break;
            default:
                break;
        }
    });
}

#pragma mark - NCConnectionStatusHandler

- (void)onConnectionStatusChanged:(NCConnectionStatusChangedEvent *)event {
    NSNotification *statusNotification = [NSNotification notificationWithName:NCChatUIDispatchConnectionStatusChangedNotification
                                                                       object:@(event.status)];
    [self onConnectionStatusChangedNotification:statusNotification];
}

@end
