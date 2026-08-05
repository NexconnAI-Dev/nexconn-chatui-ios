//
//  NCHDVoiceMsgDownloadInfo.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    NCHQDownloadStatusWaiting = 0,
    NCHQDownloadStatusSuccess = 1,
    NCHQDownloadStatusDownloading = 2,
    NCHQDownloadStatusFailed = 3,
} NCHQDownloadStatus;

@interface NCHDVoiceMsgDownloadInfo : NSObject

@property (nonatomic, strong) NCMessage *hqVoiceMsg;

@property (nonatomic, assign) NCHQDownloadStatus status;

@end

NS_ASSUME_NONNULL_END
