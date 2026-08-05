//
//  NCResendManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NCChatUIErrorCode);

NS_ASSUME_NONNULL_BEGIN

/// Resend message manager.
@interface NCResendManager : NSObject

/**
 Resend message manager singleton.

 - Returns: Singleton.
 */
+ (instancetype)sharedManager;

/**
 Whether the message needs to be resent.

 - Parameter clientId: Message clientId.
*/
- (BOOL)needResend:(long)clientId;

/**
 Adds the message to the resend message pool.

 - Parameter clientId: Message clientId.
 */
- (void)addResendMessageIfNeed:(long)clientId error:(NCChatUIErrorCode)code;

/**
 Removes the message from the resend message pool.
 
 - Parameter clientId: Message clientId.
 */
- (void)removeResendMessage:(long)clientId;

@end

NS_ASSUME_NONNULL_END
