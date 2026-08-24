//
//  NCMessageModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageModel.h"
#import "NCChatUIUtility.h"
#import "NCCombineMessageUtility.h"

@interface NCMessageModel ()

@property (nonatomic, strong) id cellViewModel;

@end

@implementation NCMessageModel

+ (instancetype)modelWithNCMessage:(NCMessage *)message {
    return [[NCMessageModel alloc] initWithNCMessage:message];
}

- (instancetype)initWithNCMessage:(NCMessage *)message {
    self = [super init];
    if (self) {
        self.channelType = message.channelIdentifier.channelType;
        self.channelId = message.channelIdentifier.channelId;
        self.clientId = (long)message.clientId;
        self.messageDirection = message.direction;
        self.senderUserId = message.senderUserId;
        self.receivedStatusInfo = message.receivedStatusInfo;
        self.sentStatus = message.sentStatus;
        self.sentTime = message.sentTime;
        self.objectName = message.messageType;
        self.content = message.content;
        self.isPersisted = message.isPersisted;
        self.isDisplayMessageTime = NO;
        self.userInfo = nil;
        self.receivedTime = message.sentTime;
        self.cellSize = CGSizeMake(0, 0);
        self.messageId = message.messageId;
        self.expansionDic = message.metadata;
        self.hasChanged = message.hasChanged;
        self.updateInfo = message.updateInfo;
        self.needReceipt = message.needReceipt;
        self.sentReceipt = message.sentReceipt;
    }
    return self;
}

// 时间标签的显示与否会改变 cell 高度（显示时内容整体下移一个时间标签区块的高度）。
// 一旦该状态变化，缓存的 cellSize 便与实际布局不再对应，必须作废以触发重新计算，
// 否则会出现气泡上下重叠（cell 画了时间标签但高度未包含它，内容溢出压到下一条）。
- (void)setIsDisplayMessageTime:(BOOL)isDisplayMessageTime {
    if (_isDisplayMessageTime != isDisplayMessageTime) {
        _isDisplayMessageTime = isDisplayMessageTime;
        _cellSize = CGSizeZero;
    }
}

- (NSString *)textMessageContent {
    if (![self.content isKindOfClass:[NCTextMessage class]]) {
        return nil;
    }
    return ((NCTextMessage *)self.content).text;
}

- (NSString *)fileMessageName {
    if (![self.content isKindOfClass:[NCFileMessage class]]) {
        return nil;
    }
    return ((NCFileMessage *)self.content).name;
}

- (NSInteger)fileMessageSize {
    if (![self.content isKindOfClass:[NCFileMessage class]]) {
        return 0;
    }
    return ((NCFileMessage *)self.content).size;
}

- (NSString *)fileMessageType {
    if (![self.content isKindOfClass:[NCFileMessage class]]) {
        return nil;
    }
    return ((NCFileMessage *)self.content).fileType;
}

- (void)setFileMessageLocalPath:(NSString *)localPath {
    if (![self.content isKindOfClass:[NCFileMessage class]]) {
        return;
    }
    ((NCFileMessage *)self.content).localPath = localPath;
}

- (long)voiceMessageDuration {
    if (![self.content isKindOfClass:[NCHDVoiceMessage class]]) {
        return 0;
    }
    return ((NCHDVoiceMessage *)self.content).duration;
}

- (NSData *)voiceMessageAudioData {
    if (![self.content isKindOfClass:[NCHDVoiceMessage class]]) {
        return nil;
    }
    NSString *localPath = ((NCHDVoiceMessage *)self.content).localPath;
    if (localPath.length == 0) {
        return nil;
    }
    return [NSData dataWithContentsOfFile:localPath];
}

- (NSString *)richContentMessageTitle {
    return nil;
}

- (NSString *)richContentMessageDigest {
    return nil;
}

- (NSString *)richContentMessageImageURL {
    return nil;
}

- (NSString *)richContentMessageURL {
    return nil;
}

- (long)sightMessageDuration {
    if (![self.content isKindOfClass:[NCShortVideoMessage class]]) {
        return 0;
    }
    return ((NCShortVideoMessage *)self.content).duration;
}

- (UIImage *)sightMessageThumbnailImage {
    if (![self.content isKindOfClass:[NCShortVideoMessage class]]) {
        return nil;
    }
    return ((NCShortVideoMessage *)self.content).thumbnailImage;
}

- (void)setSightMessageLocalPath:(NSString *)localPath {
    if (![self.content isKindOfClass:[NCShortVideoMessage class]]) {
        return;
    }
    ((NCShortVideoMessage *)self.content).localPath = localPath;
}

+ (NSString *)hqVoiceMessageLocalPathFromMessage:(NCMessage *)message {
    if (![message.content isKindOfClass:[NCHDVoiceMessage class]]) {
        return nil;
    }
    return ((NCHDVoiceMessage *)message.content).localPath;
}

- (long)hqVoiceMessageDuration {
    if (![self.content isKindOfClass:[NCHDVoiceMessage class]]) {
        return 0;
    }
    return ((NCHDVoiceMessage *)self.content).duration;
}

- (NSString *)hqVoiceMessageLocalPath {
    if (![self.content isKindOfClass:[NCHDVoiceMessage class]]) {
        return nil;
    }
    return ((NCHDVoiceMessage *)self.content).localPath;
}

- (NSString *)latestHQVoiceMessageLocalPath {
    NCMessageContent *content = self.content;
    if (![content isKindOfClass:[NCHDVoiceMessage class]]) {
        return nil;
    }
    return ((NCHDVoiceMessage *)content).localPath;
}

- (NSString *)hqVoiceMessageRemoteURL {
    if (![self.content isKindOfClass:[NCHDVoiceMessage class]]) {
        return nil;
    }
    return ((NCHDVoiceMessage *)self.content).remoteUrl;
}

- (NSString *)hqVoiceMessageDownloadFileName {
    if (![self.content isKindOfClass:[NCHDVoiceMessage class]]) {
        return nil;
    }
    NCHDVoiceMessage *voiceMessage = (NCHDVoiceMessage *)self.content;
    if (voiceMessage.name.length > 0) {
        return voiceMessage.name;
    }
    NSString *lastPathComponent =
        [[NSURL URLWithString:voiceMessage.remoteUrl ?: @""] lastPathComponent];
    if (lastPathComponent.length > 0) {
        return lastPathComponent;
    }
    if (self.messageId.length > 0) {
        return [NSString stringWithFormat:@"%@.aac", self.messageId];
    }
    if (self.sentTime > 0) {
        return [NSString stringWithFormat:@"voice_%lld.aac", self.sentTime];
    }
    return @"voice.aac";
}

- (void)setHQVoiceMessageLocalPath:(NSString *)localPath {
    if (![self.content isKindOfClass:[NCHDVoiceMessage class]]) {
        return;
    }
    ((NCHDVoiceMessage *)self.content).localPath = localPath;
}

- (UIImage *)imageMessageThumbnailImage {
    if (![self.content isKindOfClass:[NCImageMessage class]]) {
        return nil;
    }
    return ((NCImageMessage *)self.content).thumbnailImage;
}

- (NSString *)gifMessageLocalPath {
    if (![self.content isKindOfClass:[NCGIFMessage class]]) {
        return nil;
    }
    return ((NCGIFMessage *)self.content).localPath;
}

- (NSString *)gifMessageRemoteURL {
    if (![self.content isKindOfClass:[NCGIFMessage class]]) {
        return nil;
    }
    return ((NCGIFMessage *)self.content).remoteUrl;
}

- (NSString *)gifMessageName {
    if (![self.content isKindOfClass:[NCGIFMessage class]]) {
        return nil;
    }
    return ((NCGIFMessage *)self.content).name;
}

- (NSUInteger)gifMessageDataSize {
    if (![self.content isKindOfClass:[NCGIFMessage class]]) {
        return 0;
    }
    return ((NCGIFMessage *)self.content).dataSize;
}

- (void)setGifMessageLocalPath:(NSString *)localPath {
    if (![self.content isKindOfClass:[NCGIFMessage class]]) {
        return;
    }
    ((NCGIFMessage *)self.content).localPath = localPath;
}

- (NSString *)combineMessageSummaryTitle {
    if (![self.content isKindOfClass:[NCCombineMessage class]]) {
        return nil;
    }
    return [NCCombineMessageUtility getCombineMessageSummaryTitle:self.content];
}

- (NSString *)combineMessageSummaryContent {
    if (![self.content isKindOfClass:[NCCombineMessage class]]) {
        return nil;
    }
    return [NCCombineMessageUtility getCombineMessageSummaryContent:self.content];
}

- (NSString *)referenceMessageContent {
    if (![self.content isKindOfClass:[NCReferenceMessage class]]) {
        return nil;
    }
    return ((NCReferenceMessage *)self.content).content;
}

- (BOOL)referenceMessageCanOpenReferencedContent {
    if (![self.content isKindOfClass:[NCReferenceMessage class]]) {
        return NO;
    }
    NCMessageContent *referMsg = ((NCReferenceMessage *)self.content).referMsg;
    return [referMsg isKindOfClass:[NCFileMessage class]] ||
           [referMsg isKindOfClass:[NCImageMessage class]] ||
           [referMsg isKindOfClass:[NCTextMessage class]] ||
           [referMsg isKindOfClass:[NCReferenceMessage class]] ||
           [referMsg isKindOfClass:[NCStreamMessage class]];
}

- (BOOL)referenceMessageIsDeletedOrRecalled {
    if (![self.content isKindOfClass:[NCReferenceMessage class]]) {
        return NO;
    }
    NCReferenceMessageStatus status = ((NCReferenceMessage *)self.content).referMsgStatus;
    return status == NCReferenceMessageStatusRecalled || status == NCReferenceMessageStatusDeleted;
}

- (UIImage *)referenceMessageReferencedThumbnailImage {
    if (![self.content isKindOfClass:[NCReferenceMessage class]]) {
        return nil;
    }
    NCMessageContent *referMsg = ((NCReferenceMessage *)self.content).referMsg;
    if (![referMsg isKindOfClass:[NCImageMessage class]]) {
        return nil;
    }
    return ((NCImageMessage *)referMsg).thumbnailImage;
}

- (NSString *)formattedTipMessageText {
    return [NCChatUIUtility formatMessage:self.content
                                channelId:self.channelId
                              channelType:self.channelType
                             isAllMessage:YES];
}

- (NSMutableSet *)tipMessageRelatedUserIdList {
    return nil;
}

- (BOOL)tipMessageIsRecallNotification {
    return NO;
}

- (long long)recallMessageActionTime {
    return 0;
}

- (BOOL)isEqual:(id)object {
    if (!object || ![object isKindOfClass:[NCMessageModel class]]) {
        return NO;
    }
    if (object == self) {
        return YES;
    }

    NCMessageModel *model = (NCMessageModel *)object;
    if ([model.channelId isEqualToString:self.channelId] && model.channelType == self.channelType &&
        model.clientId == self.clientId) {
        return YES;
    }
    return NO;
}

#pragma mark - setter & getter

- (NCMessageReceivedStatusInfo *)receivedStatusInfo {
    if (!_receivedStatusInfo) {
        _receivedStatusInfo = [[NCMessageReceivedStatusInfo alloc] init];
    }
    return _receivedStatusInfo;
}

@end
