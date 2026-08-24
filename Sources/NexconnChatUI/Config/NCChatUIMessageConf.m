//
//  NCChatUIMessageConf.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIMessageConf.h"
#import "NCChatUICommonDefine.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

static const NSUInteger NCChatUIDefaultGIFLimitSize = 2048;
static const NSTimeInterval NCChatUIDefaultUploadVideoDurationLimit = 300;

@implementation NCChatUIMessageConf
- (instancetype)init {
    self = [super init];
    if (self) {
        self.disableMessageNotificaiton = NO;
        self.disableMessageAlertSound =
            [[NSUserDefaults standardUserDefaults] boolForKey:@"ncMessageBeep"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.maxVoiceDuration = 60;
#pragma clang diagnostic pop
        self.enableMessageRecall = YES;
        self.enableMessageMentioned = YES;
        self.maxRecallDuration = 120;
        self.enabledReadReceiptConversationTypeList =
            @[ @(NCChannelTypeDirect), @(NCChannelTypeGroup) ];
        self.enableTypingStatus = YES;
        self.enableSyncReadStatus = YES;
        self.showUnkownMessage = YES;
        self.gifAutoDownloadSizeLimit = 1024;
        self.enableSendCombineMessage = NO;
        self.reeditDuration = 300;
        self.enableMessageReference = YES;
        self.sightRecordMaxDuration = 10;
        self.enableMessageResend = YES;
        self.enableEditMessage = NO;
        self.enableMessageAttachUserInfo = NO;
        self.automaticDownloadHQVoiceMsgEnable = YES;
    }
    return self;
}

- (void)setDisableMessageAlertSound:(BOOL)disableMessageAlertSound {
    [[NSUserDefaults standardUserDefaults] setBool:disableMessageAlertSound
                                            forKey:@"ncMessageBeep"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _disableMessageAlertSound = disableMessageAlertSound;
}

- (NSUInteger)gifLimitSize {
    NSUInteger limitSize = [NCEngine getAppSettings].gifLimitSize;
    return limitSize > 0 ? limitSize : NCChatUIDefaultGIFLimitSize;
}

- (NSTimeInterval)uploadVideoDurationLimit {
    NSTimeInterval durationLimit = [NCEngine getAppSettings].maxVideoDurationSeconds;
    return durationLimit > 0 ? durationLimit : NCChatUIDefaultUploadVideoDurationLimit;
}

- (UIColor *)editedTextColor {
    if (!_editedTextColor) {
        _editedTextColor = NCDynamicColor(@"text_secondary_color");
    }
    return _editedTextColor;
}

@end
