//
//  NCChannelViewController+RRS.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelViewController+RRS.h"
#import "NCChannelVCUtil.h"
#import "NCMessageModel+RRS.h"

@interface NCChannelViewController ()
@property (nonatomic, strong) NCChannelVCUtil *util;

@end

@implementation NCChannelViewController (RRS)

- (void)rrs_observeReadReceipt {
    NSString *identifier = [NSString stringWithFormat:@"NCChannelVC-RRS-%p", self];
    [NCEngine addMessageHandlerWithIdentifier:identifier handler:self];
}

- (void)rrs_didReceiveMessageReadReceiptResponses:(NSArray<NCMessageReadReceiptResponse *> *)responses {
    for (NCMessageReadReceiptResponse *response in responses) {
        if ([response.channelIdentifier.channelId isEqualToString:self.channelId] &&
            self.channelType == response.channelIdentifier.channelType) {
            for (int i = 0; i < self.channelDataRepository.count; i++) {
                NCMessageModel *model = self.channelDataRepository[i];
                if ([model.messageId isEqualToString:response.messageId]) {
                    NCMessageReadReceiptInfo *info = [[NCMessageReadReceiptInfo alloc] init];
                    info.channelIdentifier = response.channelIdentifier;
                    info.messageId = response.messageId;
                    info.readCount = response.readCount;
                    info.unreadCount = response.unreadCount;
                    info.totalCount = response.totalCount;
                    model.readReceiptInfo = info;
                    // Match the detail page's asynchronous refresh notification to preserve event ordering.
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.util sendMessageReadReceiptNotification:model];
                    });
                }
            }
        }
    }
}
@end
