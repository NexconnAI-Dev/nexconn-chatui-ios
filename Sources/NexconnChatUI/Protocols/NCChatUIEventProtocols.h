//
//  NCChatUIEventProtocols.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NEXCONNCHATUI_NCCHATUIEVENTPROTOCOLS_H
#define NEXCONNCHATUI_NCCHATUIEVENTPROTOCOLS_H

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

@class NCMessage;

NS_ASSUME_NONNULL_BEGIN

/// ChatUI network status.
typedef NS_ENUM(NSUInteger, NCChatUINetworkStatus) {
    /// Network is not reachable.
    NCChatUINetworkStatusNotReachable = 0,
    /// Currently on WiFi network.
    NCChatUINetworkStatusReachableViaWiFi = 1,
    /// Currently on cellular network.
    NCChatUINetworkStatusReachableViaWWAN = 2,
};

/// Connection status delegate for ChatUI.
///
/// Set the connection status delegate to monitor the SDK connection state.
///
/// @warning If you use ChatUI, you can set and implement this delegate to monitor connection
/// status. If you use IMLib directly, use the NCConnectionStatusChangeDelegate in NCIMClient
/// instead.
@protocol NCChatUIConnectionStatusDelegate <NSObject>

/// Called when the ChatUI connection status changes.
///
/// @param status  The connection status between the SDK and the server.
///
/// After you set the ChatUI connection status delegate, this method is called whenever the
/// connection status changes.
- (void)onNCChatUIConnectionStatusChanged:(NCConnectionStatus)status;

@end

/// ChatUI network status change delegate.
@protocol NCChatUINetworkStatusDelegate <NSObject>

/// Called when the network status changes.
///
/// @param status The current network status.
- (void)onNCChatUINetworkStatusChanged:(NCChatUINetworkStatus)status;

@end

/// ChatUI message policy delegate.
@protocol NCChatUIMessagePolicyDelegate <NSObject>
@optional
- (BOOL)shouldInterceptMessage:(NCMessage *)message;
- (BOOL)shouldSuppressAlertSoundForMessage:(NCMessage *)message;
- (BOOL)shouldSuppressLocalNotificationForMessage:(NCMessage *)message
                                       senderName:(NSString *)senderName;
@end

/// ChatUI message event observer.
@protocol NCChatUIMessageEventObserver <NSObject>
@optional
- (void)onReceivedMessage:(NCMessage *)message left:(int)left offline:(BOOL)offline;
- (void)onDeletedMessagesForAll:(NSArray<NCMessage *> *)messages;
@end

NS_ASSUME_NONNULL_END

#endif /* NEXCONNCHATUI_NCCHATUIEVENTPROTOCOLS_H */
