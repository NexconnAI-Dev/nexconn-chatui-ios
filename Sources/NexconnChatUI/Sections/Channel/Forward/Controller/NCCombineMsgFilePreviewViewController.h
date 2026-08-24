//
//  NCCombineMsgFilePreviewViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>

@interface NCCombineMsgFilePreviewViewController : NCBaseViewController

- (instancetype)initWithRemoteURL:(NSString *)remoteURL
                      channelType:(NCChannelType)channelType
                        channelId:(NSString *)channelId
                         fileSize:(long long)fileSize
                         fileName:(NSString *)fileName
                         fileType:(NSString *)fileType;

@end
