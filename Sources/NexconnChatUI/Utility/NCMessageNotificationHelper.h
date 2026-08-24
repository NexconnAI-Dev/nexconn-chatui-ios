//
//  NCMessageNotificationHelper.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCMessage;

NS_ASSUME_NONNULL_BEGIN

@interface NCMessageNotificationHelper : NSObject

/// Checks whether the message can trigger a notification.
/// - Parameter message: Message.
/// - Parameter completion: Callback.
+ (void)checkNotifyAbilityWith:(NCMessage *)message completion:(void (^)(BOOL show))completion;
@end

NS_ASSUME_NONNULL_END
