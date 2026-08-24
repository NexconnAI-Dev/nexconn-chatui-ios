//
//  NCHDVoiceMsgDownloadManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCHDVoiceMsgDownloadManager.h"
#import "NCHDVoiceMsgDownloadInfo.h"
#import "NexconnChatUI.h"

@interface NCHDVoiceMsgDownloadManager () <NCChatUINetworkStatusDelegate>

/* UID: all NCHDVoiceMsgDownloadInfo*/

@property (nonatomic, strong) NSMutableDictionary *downloadInfos;

// NCMessage
@property (nonatomic, strong) NSMutableArray<NCMessage *> *downloadMsgs;

// NCMessages
@property (nonatomic, strong) NSMutableArray<NCMessage *> *priorityMsgs;

@property (nonatomic, strong) NSMutableArray<NCMessage *> *failedMsgs;

@property (nonatomic, assign) NCChatUINetworkStatus status;

@end

@implementation NCHDVoiceMsgDownloadManager
#pragma mark - Public Methods
+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static NCHDVoiceMsgDownloadManager *manager;
    dispatch_once(&onceToken, ^{
      manager = [NCHDVoiceMsgDownloadManager new];
      manager.downloadInfos = [NSMutableDictionary new];
      manager.downloadMsgs = [NSMutableArray new];
      manager.priorityMsgs = [NSMutableArray new];
      manager.failedMsgs = [NSMutableArray new];
      [[NCChatUI shared] addNetworkStatusDelegate:manager];
      manager.status = [[NCChatUI shared] getCurrentNetworkStatus];
    });
    return manager;
}

- (void)pushVoiceMsgs:(NSArray<NCMessage *> *)voiceMsgs priority:(BOOL)priority {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self pushItemToDataSource:voiceMsgs priority:priority];
      if (self.downloadInfos.allKeys.count == 1) {
          [self startDownload];
      }
    });
}

#pragma mark - Private Methods
- (NSString *)voiceDownloadMessageKey:(NCMessage *)message {
    if (message.clientId > 0) {
        return [NSString stringWithFormat:@"%lld", message.clientId];
    }
    if (message.messageId.length > 0) {
        return message.messageId;
    }
    return [NSString stringWithFormat:@"memory-%p", message];
}

- (void)pushItemToDataSource:(NSArray<NCMessage *> *)voiceMsgs priority:(BOOL)priority {
    for (int i = 0; i < voiceMsgs.count; i++) {
        NCMessage *voiceMsg = voiceMsgs[i];
        NSString *messageKey = [self voiceDownloadMessageKey:voiceMsg];
        if ([self.downloadInfos objectForKey:messageKey]) {
            continue;
        }
        NCHDVoiceMsgDownloadInfo *info = [NCHDVoiceMsgDownloadInfo new];
        info.hqVoiceMsg = voiceMsg;
        info.status = NCHQDownloadStatusWaiting;
        if ([voiceMsg.content isKindOfClass:[NCHDVoiceMessage class]]) {
            NCHDVoiceMessage *hqMsg = (NCHDVoiceMessage *)voiceMsg.content;
            if (hqMsg.remoteUrl.length <= 0) {
                info.status = NCHQDownloadStatusFailed;
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:NCHQDownloadStatusChangeNotify
                                  object:info];
                continue;
            }
        }
        [self.downloadInfos setObject:info forKey:messageKey];
        if (priority) {
            [self.priorityMsgs addObject:voiceMsg];
        } else {
            [self.downloadMsgs addObject:voiceMsg];
        }
        if (self.priorityMsgs.count + self.downloadMsgs.count > 100) {
            if (self.downloadMsgs.count > 0) {
                [self.downloadMsgs removeObjectAtIndex:0];
            } else {
                [self.priorityMsgs removeObjectAtIndex:0];
            }
        }
    }
}

- (void)startDownload:(int)times {
    __block NCMessage *downloadMsg = nil;
    NSUInteger priority = 0;
    if (self.priorityMsgs.count > 0) {
        downloadMsg = self.priorityMsgs.lastObject;
        priority = 1;
    } else if (self.downloadMsgs.count > 0) {
        priority = 2;
        downloadMsg = self.downloadMsgs.firstObject;
    } else {
        priority = 3;
        downloadMsg = self.failedMsgs.firstObject;
    }
    if (downloadMsg) {
        if ([[NCChatUI shared] getCurrentNetworkStatus] != NCChatUINetworkStatusNotReachable) {
            NSString *messageKey = [self voiceDownloadMessageKey:downloadMsg];
            __block NCHDVoiceMsgDownloadInfo *info = [self.downloadInfos objectForKey:messageKey];
            info.status = NCHQDownloadStatusDownloading;
            [[NSNotificationCenter defaultCenter]
                postNotificationName:NCHQDownloadStatusChangeNotify
                              object:info];
            [[NCChatUI shared] downloadMediaMessage:(long)downloadMsg.clientId
                progress:^(int progress) {

                }
                completion:^(NSString *_Nullable mediaPath, NCError *_Nullable error) {
                  if (error || mediaPath.length == 0) {
                      dispatch_async(dispatch_get_main_queue(), ^{
                        info.status = NCHQDownloadStatusFailed;
                        [[NSNotificationCenter defaultCenter]
                            postNotificationName:NCHQDownloadStatusChangeNotify
                                          object:info];
                        if (priority == 1) {
                            [self.priorityMsgs removeObject:downloadMsg];
                        } else if (priority == 2) {
                            [self.downloadMsgs removeObject:downloadMsg];
                        } else {
                            [self.failedMsgs removeObject:downloadMsg];
                        }
                        [self.failedMsgs addObject:downloadMsg];

                        if (times >= 0) {
                            [self startDownload:times - 1];
                        } else {
                            [self removeDownloadInfo:downloadMsg priority:priority];
                        }
                      });
                      return;
                  }
                  dispatch_async(dispatch_get_main_queue(), ^{
                    info.status = NCHQDownloadStatusSuccess;
                    ((NCHDVoiceMessage *)info.hqVoiceMsg.content).localPath = mediaPath;
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:NCHQDownloadStatusChangeNotify
                                      object:info];
                    [self downloadEnd:downloadMsg priority:priority];
                  });
                }
                cancel:^{
                  dispatch_async(dispatch_get_main_queue(), ^{
                    info.status = NCHQDownloadStatusFailed;
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:NCHQDownloadStatusChangeNotify
                                      object:info];
                    [self removeDownloadInfo:downloadMsg priority:priority];
                  });
                }];
        } else {
            NSString *messageKey = [self voiceDownloadMessageKey:downloadMsg];
            __block NCHDVoiceMsgDownloadInfo *info = [self.downloadInfos objectForKey:messageKey];
            info.status = NCHQDownloadStatusFailed;
            [[NSNotificationCenter defaultCenter]
                postNotificationName:NCHQDownloadStatusChangeNotify
                              object:info];
        }
    }
}

- (void)startDownload {
    [self startDownload:2];
}

- (void)downloadEnd:(NCMessage *)downloadMsg priority:(NSInteger)priority {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (priority == 1) {
          [self.priorityMsgs removeObject:downloadMsg];
      } else if (priority == 2) {
          [self.downloadMsgs removeObject:downloadMsg];
      } else {
          [self.failedMsgs removeObject:downloadMsg];
      }
      [self.downloadInfos removeObjectForKey:[self voiceDownloadMessageKey:downloadMsg]];
      [self startDownload];
    });
}

- (void)removeDownloadInfo:(NCMessage *)downloadMsg priority:(NSInteger)priority {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (priority == 1) {
          [self.priorityMsgs removeObject:downloadMsg];
      } else if (priority == 2) {
          [self.downloadMsgs removeObject:downloadMsg];
      } else {
          [self.failedMsgs removeObject:downloadMsg];
      }
      [self.downloadInfos removeObjectForKey:[self voiceDownloadMessageKey:downloadMsg]];
      [self startDownload];
    });
}

- (void)onNCChatUINetworkStatusChanged:(NCChatUINetworkStatus)status {
    self.status = status;
    if (status != NCChatUINetworkStatusNotReachable) {
        [self startDownload];
    }
}

@end
