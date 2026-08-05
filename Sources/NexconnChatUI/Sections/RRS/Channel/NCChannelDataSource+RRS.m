//
//  NCChannelDataSource+RRS.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelDataSource+RRS.h"
#import "NCMessageModel+RRS.h"
#import "NCChannelVCUtil.h"
#import "NCChannelViewController+RRS.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

@interface NCChannelViewController ()
@property (nonatomic, strong, readonly) NCChannelVCUtil *util;
@end
@interface NCChannelDataSource ()

@property (nonatomic, weak) NCChannelViewController *chatVC;
@end

// TODO: This still derives the NC channel and identifier from NCChannelViewController. Remove it when the page owns NC context directly.
static NCBaseChannel *NCConversationChannel(NCChannelViewController *chatVC) {
    NSString *channelId = chatVC.channelId ?: @"";
    NSString *subChannelId = chatVC.subChannelId ?: @"";
    NCChannelType channelType = chatVC.channelType;
    switch (channelType) {
        case NCChannelTypeDirect:
            return [[NCDirectChannel alloc] initWithChannelId:channelId];
        case NCChannelTypeGroup:
            return [[NCGroupChannel alloc] initWithChannelId:channelId];
        case NCChannelTypeSystem:
            return [[NCSystemChannel alloc] initWithChannelId:channelId];
        case NCChannelTypeCommunity:
            return [[NCCommunitySubChannel alloc] initWithChannelId:channelId
                                                       subChannelId:subChannelId];
        default:
            return nil;
    }
}

@implementation NCChannelDataSource (RRS)

- (void)rrs_fetchReadReceiptInfo:(NSArray <NCMessageModel *>*)models {
    if (!models.count) {
        return;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    for (NCMessageModel *model in models) {
        BOOL shouldFetch = [model rrs_shouldFetchReadReceipt];
        if (shouldFetch) {
            dic[model.messageId] = model;
        }
    }
    if([dic allKeys].count) {
        NSArray *messageUIDs = [dic allKeys];
        NCBaseChannel *channel = NCConversationChannel(self.chatVC);
        if (!channel) {
            return;
        }
        [channel getMessageReadReceiptInfoWithMessageIds:messageUIDs completion:^(NSArray<NCMessageReadReceiptInfo *> * _Nullable infoList,
                                                                                   NCError * _Nullable error) {
            if (!error) {
                for (NCMessageReadReceiptInfo *info in infoList) {
                    NCMessageModel *model = dic[info.messageId];
                    if (info.messageId.length == 0 || !model) {
                        continue;
                    }
                    model.readReceiptInfo = info;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.chatVC.util sendMessageReadReceiptNotification:model];
                    });
                }
            }
        }];
    }
}

- (void)rrs_respondReadReceipt:(NSDictionary *)dic {
    if([dic allKeys].count) {
        NSArray *messageUIDs = [dic allKeys];
        NCBaseChannel *channel = NCConversationChannel(self.chatVC);
        if (!channel) {
            return;
        }
        [channel sendReadReceiptResponseWithMessageIds:messageUIDs completion:^(NCError * _Nullable error) {
            if (!error) {
                NSArray *models = [dic allValues];
                for (NCMessageModel *model in models) {
                    model.sentReceipt = YES;
                }
            }
        }];
    }
}

@end
