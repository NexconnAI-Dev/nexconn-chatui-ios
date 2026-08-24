//
//  NCUserOnlineStatusUtil.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUserOnlineStatusUtil.h"
#import "NCChatUIConfig.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

@implementation NCUserOnlineStatusUtil

+ (BOOL)shouldDisplayOnlineStatus {
    NCAppSettings *appSettings = [NCEngine getAppSettings];
    if (NCChatUIConfigCenter.ui.enableUserOnlineStatus &&
        (appSettings.isOnlineStatusSubscribeEnable ||
         appSettings.isFriendOnlineStatusSubscribeEnable)) {
        return YES;
    }
    return NO;
}

@end
