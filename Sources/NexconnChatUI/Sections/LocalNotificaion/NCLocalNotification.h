//
//  NCLocalNotification.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCMessage;

@interface NCLocalNotification : NSObject

/**
 *  Singleton.
 *
 *  - Returns: Instance.
 */
+ (NCLocalNotification *)defaultCenter;

/// Posts an iOS 10-compatible local notification. On iOS 10 and later, local notifications can be
/// grouped and replaced.
- (void)postLocalNotificationWithMessage:(NCMessage *)message userInfo:(NSDictionary *)userInfo;

/// Used for encrypted channels.
- (void)postLocalNotification:(NSString *)formatMessage userInfo:(NSDictionary *)userInfo;

@end
