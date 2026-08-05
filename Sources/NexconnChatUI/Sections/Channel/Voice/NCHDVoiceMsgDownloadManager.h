//
//  NCHDVoiceMsgDownloadManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *NCHQDownloadStatusChangeNotify = @"NCHQDownloadStatusChangeNotify";

@interface NCHDVoiceMsgDownloadManager : NSObject

+ (instancetype)defaultManager;

- (void)pushVoiceMsgs:(NSArray<NCMessage *> *)voiceMsgs priority:(BOOL)priority;

@end

NS_ASSUME_NONNULL_END
