//
//  NCChatUISendProtocols.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NEXCONNCHATUI_NCCHATUISENDPROTOCOLS_H
#define NEXCONNCHATUI_NCCHATUISENDPROTOCOLS_H

#import <Foundation/Foundation.h>
#import <NexconnChatUI/NCChatUISendParams.h>

@class NCMessage;

NS_ASSUME_NONNULL_BEGIN

/// ChatUI message send interceptor.
/// Set the interceptor to intercept message sending and receive send results.
/// For example, when forwarding combined messages or uploading attachments to an App file server, use this interceptor.
///
/// @warning If you use ChatUI, you can set and implement this protocol.
///
/// Choose one of the two approaches based on your use case. For uploading media attachments to an App file server, this approach is recommended.
@protocol NCChatUIMessageInterceptor <NSObject>

@optional

/// Intercept callback before sending a normal message.
///
/// @param params The parameters for the normal message about to be sent.
/// @return YES if the message is intercepted (SDK will not process it further); NO to let the SDK proceed.
/// This method is called when a normal message is about to be sent. You can filter or modify the message parameters.
/// If you only need to modify the content, update it and return NO so the SDK continues sending.
- (BOOL)interceptWillSendMessageWithParams:(NCChatUISendMessageParams *)params;

/// Intercept callback before sending a media message.
///
/// @param params The parameters for the media message about to be sent.
/// @return YES if the message is intercepted (SDK will not process it further); NO to let the SDK proceed.
/// This method is called when a media message is about to be sent. You can filter or modify the message parameters.
- (BOOL)interceptWillSendMediaMessageWithParams:(NCChatUISendMediaMessageParams *)params;

/// Intercept callback after a message is sent.
///
/// @param message The message that was sent.
/// This method is called after a message has been sent. You can check message.sentStatus to determine success or failure.
- (void)interceptDidSendMessage:(NCMessage *)message;

@end

NS_ASSUME_NONNULL_END

#endif /* NEXCONNCHATUI_NCCHATUISENDPROTOCOLS_H */
