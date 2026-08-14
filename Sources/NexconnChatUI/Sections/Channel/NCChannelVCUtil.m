//
//  NCChannelVCUtil.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelVCUtil.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCChatUICommonDefine.h"
#import "NCMessageBaseCell.h"
#import "NCChannelViewController.h"
#import "NCOldMessageNotificationMessage.h"
#import "NCMessageCell.h"
#import "NCChatUI.h"
#import "NCChatUILog.h"
#import "NCMediaManager.h"
#import "NCChatUIUtility.h"
#import "NCGIFImage.h"
#import <AVFoundation/AVFoundation.h>
#import "NCHDVoiceMessageCell.h"
#import "NCChatUIConfig.h"
#import "NCChannelDataSource.h"
#import "NCChannelViewController+internal.h"
#import "NSMutableDictionary+NCOperation.h"
#import "NCRRSUtil.h"
#import "NCChatUIErrorCode.h"
#import "NCFileUtility.h"

// 时间标签区块的实际高度：TIME_LABEL_TOP(8) + TIME_LABEL_HEIGHT(16) + TIME_LABEL_AND_BASE_CONTENT_VIEW_SPACE(12) = 36，
// 需与 referenceExtraHeight / NCMessageBaseCell 的布局保持一致，否则加载更多时的滚动补偿高度会偏差。
NSInteger const NCMessageCellDisplayTimeHeightForCommon = 36;
NSInteger const NCMessageCellDisplayTimeHeightForHQVoice = 36;
static NSString *const NCChatUIChannelDraftSaveWillBeginNotificationName =
    @"NCChatUIChannelDraftSaveWillBeginNotification";

@interface NCChannelViewController ()
@property (nonatomic, strong, readonly) NCChannelDataSource *dataSource;

// Private methods
- (void)onlySendMessage:(NCMessageContent *)messageContent pushContent:(NSString *)pushContent;
@end

@interface NCChannelVCUtil ()
@property (nonatomic, weak) NCChannelViewController *chatVC;
/*!
 Message object names eligible for read receipts. The list uses NCMessageType.text and falls back to @"RC:TxtMsg" when needed.

 @discussion enabledReadReceiptMessage: checks whether a model's objectName appears in this list.
 */
@property (nonatomic, copy) NSArray<NSString *> *enabledReadReceiptMessageTypeList;
@end

static BOOL NCPopulateChannelContext(NCChannelViewController *chatVC,
                                       NCChannelType *channelType,
                                       NSString *__strong *channelId,
                                       NSString *__strong *subChannelId) {
    if (!chatVC) {
        return NO;
    }
    switch (chatVC.channelType) {
        case NCChannelTypeDirect:
            *channelType = NCChannelTypeDirect;
            break;
        case NCChannelTypeGroup:
            *channelType = NCChannelTypeGroup;
            break;
        case NCChannelTypeSystem:
            *channelType = NCChannelTypeSystem;
            break;
        default:
            return NO;
    }
    *channelId = chatVC.channelId ?: @"";
    *subChannelId = chatVC.subChannelId ?: @"";
    return (*channelId).length > 0;
}

static NCPushConfig * _Nullable RCNCPushConfigWithPushContent(NSString * _Nullable pushContent) {
    if (pushContent.length == 0) {
        return nil;
    }
    NCPushConfig *pushConfig = [NCPushConfig new];
    pushConfig.pushContent = pushContent;
    return pushConfig;
}

@implementation NCChannelVCUtil
- (instancetype)init:(NCChannelViewController *)chatVC {
    self = [super init];
    if(self) {
        self.chatVC = chatVC;
        self.enabledReadReceiptMessageTypeList = @[ NCMessageType.text ?: @"RC:TxtMsg" ];
    }
    return self;
}

- (void)sendMessageStatusNotification:(NSString *)actionNametatus clientId:(long)clientId progress:(NSInteger)progress {
    NCMessageCellNotificationModel *notifyModel = [[NCMessageCellNotificationModel alloc] init];
    notifyModel.actionName = actionNametatus;
    notifyModel.clientId = clientId;
    notifyModel.progress = progress;
    dispatch_main_async_safe(^{
       [[NSNotificationCenter defaultCenter]
           postNotificationName:KNotificationMessageBaseCellUpdateSendingStatus
                         object:notifyModel];
    });
}

- (void)sendMessageReadReceiptNotification:(NCMessageModel *)model {
    NCMessageCellNotificationModel *notifyModel = [[NCMessageCellNotificationModel alloc] init];
    notifyModel.actionName = CONVERSATION_CELL_STATUS_SEND_READ_RECEIPT_INFO;
    notifyModel.clientId = model.clientId;
    notifyModel.readReceiptInfo = model.readReceiptInfo;
    dispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:KNotificationMessageBaseCellUpdateSendingStatus object:notifyModel];
    });
}
- (NCInformationNotificationMessage *)getInfoNotificationMessageByErrorCode:(NCChatUIErrorCode)nErrorCode {
    NCInformationNotificationMessage *informationNotifiMsg = nil;
    if (NCChatUIErrorCodeNotInGroup == nErrorCode) {
        informationNotifiMsg = [NCInformationNotificationMessage
            notificationWithMessage:NCUILocalizedString(@"not_in_group")
                              extra:nil];
    } else if (NCChatUIErrorCodeRejectedByBlacklist == nErrorCode) {
        informationNotifiMsg = [NCInformationNotificationMessage
            notificationWithMessage:NCUILocalizedString(@"message_rejected")
                              extra:nil];
    } else if (NCChatUIErrorCodeForbiddenInGroup == nErrorCode) {
        informationNotifiMsg = [NCInformationNotificationMessage
            notificationWithMessage:NCUILocalizedString(@"forbidden_in_group")
                              extra:nil];
    }
    return informationNotifiMsg;
}

+ (CGFloat)incrementOfTimeLabelBy:(NCMessageModel *)model {
    if ([model.content isKindOfClass:[NCHDVoiceMessage class]]) {
        return NCMessageCellDisplayTimeHeightForHQVoice;
    } else {
        return NCMessageCellDisplayTimeHeightForCommon;
    }
}

- (void)figureOutAllConversationDataRepository {
    [self figureOutConversationDataRepositoryFromIndex:0
                                               toIndex:self.chatVC.channelDataRepository.count - 1];
}

- (void)figureOutConversationDataRepositoryFromIndex:(NSInteger)startIndex
                                             toIndex:(NSInteger)endIndex {
    NSInteger repositoryCount = self.chatVC.channelDataRepository.count;
    if (repositoryCount <= 0 || startIndex > endIndex) {
        return;
    }
    NSInteger lowerIndex = MAX(0, startIndex);
    NSInteger upperIndex = MIN(repositoryCount - 1, endIndex + 1);
    if (lowerIndex > upperIndex) {
        return;
    }
    for (NSInteger i = lowerIndex; i <= upperIndex; i++) {
        NCMessageModel *model = [self.chatVC.channelDataRepository objectAtIndex:i];
        [self updateTimeDisplayForModel:model atIndex:i];
    }
}

- (void)figureOutLatestModel:(NCMessageModel *)model {
    if ([model.objectName isEqualToString:NCOldMessageNotificationMessageTypeIdentifier]) {
        model.isDisplayMessageTime = NO;
        return;
    }
    NSMutableArray *messageArr = [NSMutableArray new];
    if(self.chatVC.channelDataRepository.count > 0) {
        [messageArr addObjectsFromArray:self.chatVC.channelDataRepository];
    }
    if (self.chatVC.dataSource.cachedReloadMessages.count > 0) {
        [messageArr addObjectsFromArray:self.chatVC.dataSource.cachedReloadMessages];
    }
    if (messageArr.count > 0) {

        NCMessageModel *pre_model = messageArr.lastObject;
        if ([pre_model.objectName isEqualToString:NCOldMessageNotificationMessageTypeIdentifier]) {
            model.isDisplayMessageTime = YES;
            return;
        }
        long long previous_time = pre_model.sentTime;

        long long current_time = model.sentTime;

        long long interval =
            current_time - previous_time > 0 ? current_time - previous_time : previous_time - current_time;
        if (interval / 1000 <= 3 * 60) {
            model.isDisplayMessageTime = NO;
        } else {
            model.isDisplayMessageTime = YES;
        }
    } else {
        model.isDisplayMessageTime = YES;
    }
}

- (void)updateTimeDisplayForModel:(NCMessageModel *)model atIndex:(NSInteger)index {
    if ([model.objectName isEqualToString:NCOldMessageNotificationMessageTypeIdentifier]) {
        [self updateModel:model displayMessageTime:NO];
        return;
    }
    if (index == 0) {
        [self updateModel:model displayMessageTime:YES];
        return;
    }
    NCMessageModel *preModel = [self.chatVC.channelDataRepository objectAtIndex:index - 1];
    long long interval = llabs(model.sentTime - preModel.sentTime);
    [self updateModel:model displayMessageTime:(interval / 1000 > 3 * 60)];
}

- (void)updateModel:(NCMessageModel *)model displayMessageTime:(BOOL)displayMessageTime {
    if (model.isDisplayMessageTime == displayMessageTime) {
        return;
    }
    CGSize cellSize = model.cellSize;
    CGFloat increment = [[self class] incrementOfTimeLabelBy:model];
    model.isDisplayMessageTime = displayMessageTime;
    if (cellSize.height <= 0) {
        return;
    }
    cellSize.height += displayMessageTime ? increment : -increment;
    model.cellSize = cellSize;
}

- (void)saveDraftIfNeed {
    NSString *channelId = self.chatVC.channelId?:@"";
    NSString *subChannelId = self.chatVC.subChannelId?:@"";
    NSString *draft = self.chatVC.chatSessionInputBarControl.draft?:@"";
    NCBaseChannel *channel = self.chatVC.currentChannel;
    NCChannelType channelType = self.chatVC.channelType;
    if (!channel) {
        return;
    }
    NSDictionary *userInfo = @{
        @"channelType": @(channelType),
        @"channelId": channelId,
        @"subChannelId": subChannelId,
        @"draft": draft,
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:NCChatUIChannelDraftSaveWillBeginNotificationName
                                                        object:nil
                                                      userInfo:userInfo];
    void (^postDraftSaveResult)(BOOL, NSError *) = ^(BOOL updated, NSError *error) {
        NSMutableDictionary *resultUserInfo = [userInfo mutableCopy];
        resultUserInfo[@"updated"] = @(updated);
        if (error) {
            resultUserInfo[@"error"] = error;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NCChatUIChannelDraftSaveResultNotification
                                                            object:nil
                                                          userInfo:resultUserInfo];
    };
    [channel reloadWithCompletion:^(NCBaseChannel * _Nullable latestChannel, NSError * _Nullable error) {
        if (error) {
            NCLogW(@"reload channel draft failed, channelType:%@ channelId:%@ subChannelId:%@ error:%@",
                   @(channelType), channelId, subChannelId, @(error.code));
        }
        NSString *draftInDB = latestChannel.draft ?: @"";
        NCBaseChannel *activeChannel = latestChannel ?: channel;
        if ([draft length] > 0) {
            if(![draft isEqualToString:draftInDB]) {
                [activeChannel saveDraft:draft completion:^(BOOL isSaved, NCError * _Nullable saveError) {
                    if (!isSaved || saveError) {
                        NCLogW(@"save channel draft failed, channelType:%@ channelId:%@ subChannelId:%@ isSaved:%@ error:%@",
                               @(channelType), channelId, subChannelId, @(isSaved), @(saveError.code));
                        postDraftSaveResult(NO, saveError);
                        return;
                    }
                    postDraftSaveResult(YES, nil);
                }];
            } else {
                postDraftSaveResult(NO, nil);
            }
        } else if (draftInDB.length > 0){
            [activeChannel clearDraftWithCompletion:^(BOOL isCleared, NCError * _Nullable clearError) {
                if (!isCleared || clearError) {
                    NCLogW(@"clear channel draft failed, channelType:%@ channelId:%@ subChannelId:%@ isCleared:%@ error:%@",
                           @(channelType), channelId, subChannelId, @(isCleared), @(clearError.code));
                    postDraftSaveResult(NO, clearError);
                    return;
                }
                postDraftSaveResult(YES, nil);
            }];
        } else {
            postDraftSaveResult(NO, error);
        }
    }];
}


- (CGFloat)referenceExtraHeight:(Class)cellClass messageModel:(NCMessageModel *)model {
    CGFloat extraHeight = BASE_CONTENT_VIEW_BOTTOM;
    if ([cellClass isSubclassOfClass:NCMessageBaseCell.class]) {
        if (model.isDisplayMessageTime) {
            extraHeight += TIME_LABEL_TOP + TIME_LABEL_HEIGHT + TIME_LABEL_AND_BASE_CONTENT_VIEW_SPACE;
        }
    }
    if ([cellClass isSubclassOfClass:NCMessageCell.class]) {
        // name label height
        if (model.isDisplayNickname && model.messageDirection == NCMessageDirectionReceive) {
            extraHeight += NameHeight + NameAndContentSpace;
        }
    }
    return extraHeight;
}

- (NSIndexPath *)findDataIndexFromMessageList:(NCMessageModel *)model {
    NSIndexPath *indexPath;
    for (int i = 0; i < self.chatVC.channelDataRepository.count; i++) {
        NCMessageModel *msg = (self.chatVC.channelDataRepository)[i];
        if (msg.clientId == model.clientId && ![msg.objectName isEqualToString:NCOldMessageNotificationMessageTypeIdentifier]) {
            indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            break;
        }
    }
    return indexPath;
}

- (NCMessageModel *)modelByMessageID:(NSInteger)messageID {
    for (int i = 0; i < self.chatVC.channelDataRepository.count; i++) {
        NCMessageModel *msg = (self.chatVC.channelDataRepository)[i];
        if (msg.clientId == messageID && ![msg.objectName isEqualToString:NCOldMessageNotificationMessageTypeIdentifier]) {
            return msg;
        }
    }
    return nil;
}

- (NCMessageModel *)modelByMessageUId:(NSString *)messageId {
    for (int i = 0; i < self.chatVC.channelDataRepository.count; i++) {
        NCMessageModel *msg = (self.chatVC.channelDataRepository)[i];
        if ([msg.messageId isEqualToString:messageId] && ![msg.objectName isEqualToString:NCOldMessageNotificationMessageTypeIdentifier]) {
            return msg;
        }
    }
    return nil;
}

- (BOOL)canDeleteMessageForAllOfModel:(NCMessageModel *)model {
    long long cTime = [[NSDate date] timeIntervalSince1970] * 1000;
    long long ServerTime = cTime - [NCEngine getServerTimeDelta];
    long long interval = ServerTime - model.sentTime > 0 ? ServerTime - model.sentTime : model.sentTime - ServerTime;
    NCChannelType channelType = (NCChannelType)model.channelType;
    return (interval <= NCChatUIConfigCenter.message.maxRecallDuration * 1000 && model.messageDirection == NCMessageDirectionSend &&
            NCChatUIConfigCenter.message.enableMessageRecall && model.sentStatus != NCMessageSentStatusSending &&
            model.sentStatus != NCMessageSentStatusFailed && model.sentStatus != NCMessageSentStatusCanceled &&
            (channelType == NCChannelTypeDirect || channelType == NCChannelTypeGroup));
}


- (BOOL)canReferenceMessage:(NCMessageModel *)message {
    BOOL inputHidden = self.chatVC.chatSessionInputBarControl.hidden;
    if (self.chatVC.editInputBarControl.isVisible) {
        inputHidden = self.chatVC.editInputBarControl.hidden;
    }
    
    if (!NCChatUIConfigCenter.message.enableMessageReference || !self.chatVC.chatSessionInputBarControl || inputHidden) {
        return NO;
    }
    
    // System channels do not support message references.
    if (self.chatVC.channelType == NCChannelTypeSystem) {
        return NO;
    }

    // Messages that have not been sent successfully cannot be referenced.
    if ((message.sentStatus != NCMessageSentStatusSending && message.sentStatus != NCMessageSentStatusFailed &&
         message.sentStatus != NCMessageSentStatusCanceled) &&
        ([message.content isKindOfClass:NCTextMessage.class] || [message.content isKindOfClass:NCFileMessage.class] ||
         [message.content isKindOfClass:NCImageMessage.class] ||
         [message.content isKindOfClass:NCReferenceMessage.class])) {
        return YES;
    }
    return NO;
}
- (void)doSendMessage:(NCMessageContent *)messageContent pushContent:(NSString *)pushContent {
    [self doOnlySendMessage:messageContent pushContent:pushContent];
}

// Send through the channel-specific path.
- (void)doOnlySendMessage:(NCMessageContent *)messageContent pushContent:(NSString *)pushContent {
    NCChannelType channelType = NCChannelTypeDirect;
    NSString *channelId = @"";
    NSString *subChannelId = @"";
    if (!NCPopulateChannelContext(self.chatVC, &channelType, &channelId, &subChannelId)) {
        return;
    }

    if ([messageContent isKindOfClass:[NCMediaMessageContent class]]) {
        NCChatUISendMediaMessageParams *params = [[NCChatUISendMediaMessageParams alloc] initWithContent:(NCMediaMessageContent *)messageContent];
        params.channelType = channelType;
        params.channelId = channelId;
        params.subChannelId = subChannelId;
        params.needReceipt = [NCChatUIUtility shouldNeedReadReceiptForChannelType:channelType];
        params.pushConfig = RCNCPushConfigWithPushContent(pushContent);
        [[NCChatUI shared] sendMediaMessageWithParams:params
                                             progress:nil
                                           completion:nil
                                               cancel:nil];
    } else {
        NCChatUISendMessageParams *params = [[NCChatUISendMessageParams alloc] initWithContent:messageContent];
        params.channelType = channelType;
        params.channelId = channelId;
        params.subChannelId = subChannelId;
        params.needReceipt = [NCChatUIUtility shouldNeedReadReceiptForChannelType:channelType];
        params.pushConfig = RCNCPushConfigWithPushContent(pushContent);
        [[NCChatUI shared] sendMessageWithParams:params
                                      completion:^(NCMessage * _Nullable message, NCError * _Nullable error) {
            (void)message;
            NCLogD(@"error: %@", @(error.code));
        }];
    }
}

- (void)doSendSelectedMediaMessage:(NSArray *)selectedImages fullImageRequired:(BOOL)full {
    // Process selected media off the main thread.
    NCChannelViewController *chatVC = self.chatVC;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < selectedImages.count; i++) {
            @autoreleasepool {
                id item = [selectedImages objectAtIndex:i];
                if ([item isKindOfClass:NSData.class]) {
                    NSData *imageData = (NSData *)item;
                    UIImage *image = [UIImage imageWithData:imageData];
                    image = [NCChatUIUtility fixOrientation:image];
                    // Downsize large images before constructing the outgoing message.
                    [[NCMediaManager sharedManager] downsizeImage:image
                        completionBlock:^(UIImage *outimage, BOOL doNothing) {
                            NCImageMessage *imagemsg;
                            if (doNothing || !outimage) {
                                imagemsg = [[NCImageMessage alloc] initWithImage:image];
                                imagemsg.original = full;
                            } else if (outimage) {
                                NSData *newImageData = UIImageJPEGRepresentation(outimage, 1);
                                imagemsg = [[NCImageMessage alloc] initWithImageData:newImageData];
                                imagemsg.original = full;
                            }
                            [chatVC onlySendMessage:imagemsg pushContent:nil];
                        }
                        progressBlock:^(UIImage *outimage, BOOL doNothing){

                        }];
                } else if ([item isKindOfClass:NSDictionary.class]) {
                    NSDictionary *assertInfo = item;
                    if ([assertInfo objectForKey:@"avAsset"]) {
                        AVAsset *model = assertInfo[@"avAsset"];
                        UIImage *image = assertInfo[@"thumbnail"];
                        NSString *localPath = assertInfo[@"localPath"];
                        // 这里不能同步切主线程，否则 updateEventQueue 会被主线程长时间占用时反向卡住。
                        dispatch_main_async_safe(^{
                            NSUInteger duration = round(CMTimeGetSeconds(model.duration));
                            NCShortVideoMessage *sightMsg =
                                [[NCShortVideoMessage alloc] initWithLocalPath:localPath
                                                                      thumbnail:image
                                                                       duration:(int)duration];
                            [chatVC onlySendMessage:sightMsg pushContent:nil];
                        });
                    } else {
                        NSData *gifImageData = (NSData *)[assertInfo objectForKey:@"imageData"];
                        NCGIFImage *gifImage = [NCGIFImage animatedImageWithGIFData:gifImageData];
                        if (gifImage) {
                            NCGIFMessage *gifMsg = [[NCGIFMessage alloc] initWithGIFImageData:gifImageData
                                                                                          width:(int)gifImage.size.width
                                                                                         height:(int)gifImage.size.height];
                            [chatVC onlySendMessage:gifMsg pushContent:nil];
                        }
                    }
                }
                [NSThread sleepForTimeInterval:0.5];
            }
        }
    });
}

- (NSString *)getHQVoiceMessageCachePath {
    long long currentTime = [[NSDate date] timeIntervalSince1970] * 1000;
    NSString *path = [NCFileUtility imageCacheRootDirectory];
    NSString *currentUserId = [NCEngine getCurrentUserId] ?: @"";
    path = [path
        stringByAppendingFormat:@"/%@/NCHQVoiceCache", currentUserId];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    NSString *fileName = [NSString stringWithFormat:@"/Voice_%@.aac", @(currentTime)];
    path = [path stringByAppendingPathComponent:fileName];
    return path;
}
- (void)stopVoiceMessageIfNeed:(NCMessageModel *)model {
    NSIndexPath *indexPath = [self findDataIndexFromMessageList:model];
    if (!indexPath) {
        return;
    }
    // Only HD voice messages use this playback path.
    if([model.content isMemberOfClass:[NCHDVoiceMessage class]]) {
        NCHDVoiceMessageCell *cell = (NCHDVoiceMessageCell *)[self.chatVC.messageCollectionView cellForItemAtIndexPath:indexPath];
        if ([cell respondsToSelector:@selector(stopPlayingVoice)]) {
            [cell stopPlayingVoice];
        }
    }
}

- (BOOL)isAutoResponseRobot{
    return NO;
}

- (void)adaptUnreadButtonSize:(UILabel *)sender {
    UIButton * senderButton;
    NSString *imageNameKey = nil;
    if (sender.tag == 1001) {
        imageNameKey = @"channel_unread_button_arrow_img";
        senderButton = self.chatVC.unReadButton;
    }else {
        senderButton = self.chatVC.unReadMentionedButton;
        imageNameKey = @"channel_mention_button_arrow_img";
    }
    CGRect temBut = senderButton.frame;

    CGRect rect = [sender.text boundingRectWithSize:CGSizeMake(2000, senderButton.frame.size.height)
                                            options:(NSStringDrawingUsesLineFragmentOrigin)
                                         attributes:@{
                                             NSFontAttributeName : [[NCChatUIConfig defaultConfig].font fontOfFourthLevel]
                                         }
                                            context:nil];
    CGFloat arrowLeft = 19;
    CGFloat arrowWidth = 10;
    CGFloat arrowAndTextSpace = 5;
    CGFloat textRight = 4;
    temBut.size.width = arrowLeft + arrowWidth + arrowAndTextSpace + rect.size.width + textRight;
    temBut.origin.x = self.chatVC.view.frame.size.width - temBut.size.width;
    senderButton.frame = temBut;
    sender.frame = CGRectMake(temBut.size.width - textRight - rect.size.width, 0, rect.size.width, temBut.size.height);
    UIImage *image = [senderButton currentBackgroundImage]; 
    if ([NCChatUIUtility isRTL]) {
        temBut.origin.x = 0;
        senderButton.frame = temBut;
        sender.frame = CGRectMake(4, 0, rect.size.width, temBut.size.height);
        image = [image imageFlippedForRightToLeftLayoutDirection];
    } else {
        temBut.origin.x = self.chatVC.view.frame.size.width - temBut.size.width;
        senderButton.frame = temBut;
        sender.frame = CGRectMake(temBut.size.width - 4 - rect.size.width, 0, rect.size.width, temBut.size.height);
    }
    // Apply resizable cap insets to dynamic images.
    if (image.imageAsset) {
        // Resolve the image for the current traits before applying cap insets.
        UIImage *currentTraitImage = [image.imageAsset imageWithTraitCollection:self.chatVC.traitCollection];
        image = [self applyResizableCapInsets:currentTraitImage];
    } else {
        // Static images can use cap insets directly.
        image = [self applyResizableCapInsets:image];
    }
    
    [senderButton setBackgroundImage:image forState:UIControlStateNormal];
    CGRect imageViewFrame = CGRectMake(arrowLeft,(temBut.size.height- 9)/2, arrowWidth, 9);
    if ([NCChatUIUtility isRTL]) {
        imageViewFrame = CGRectMake(temBut.size.width - arrowLeft - arrowWidth, (temBut.size.height- 9)/2, arrowWidth, 9);
    }

    UIView *view = [senderButton viewWithTag:1010];
    if (view) {
        view.frame = imageViewFrame;
        CGPoint center = view.center;
        center.y = sender.center.y;
        view.center = center;
    }else{
        NCBaseImageView *imageView = [[NCBaseImageView alloc] initWithFrame:imageViewFrame];
        CGPoint center = imageView.center;
        center.y = sender.center.y;
        imageView.center = center;
        imageView.image = NCDynamicImage(imageNameKey);
        imageView.tag = 1010;
        [senderButton addSubview:imageView];
    }
}

- (UIImage *)applyResizableCapInsets:(UIImage *)image {
    if (!image) return nil;
    CGFloat halfWidth = image.size.width * 0.5;
    CGFloat halfHeight = image.size.height * 0.5;
    UIEdgeInsets capInsets = UIEdgeInsetsMake(halfHeight, halfWidth, halfHeight, halfWidth);
    
    return [image resizableImageWithCapInsets:capInsets];
}

#pragma mark - Read Receipts and Read Status Sync
- (void)syncReadStatus {
    [self syncReadStatusWithDelay:NO];
}

- (void)syncReadStatusWithDelay:(BOOL)delay {
    if (!NCChatUIConfigCenter.message.enableSyncReadStatus)
        return;
    if ([self isAutoResponseRobot]) {
        return;
    }
    
    void (^syncBlock)(void) = ^{
        [self startSyncConversationReadStatusWithDelay:delay];
    };
    if (![self.chatVC shouldMarkMessagesAsRead]) {
        return;
    }
        
    NCChannelType channelType = self.chatVC.channelType;
    BOOL isDirectChannel = channelType == NCChannelTypeDirect;
    BOOL readReceiptEnabledForCurrentType =
        [NCChatUIConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(channelType)];
    BOOL shouldSyncReadStatus = (isDirectChannel && !readReceiptEnabledForCurrentType) ||
        channelType == NCChannelTypeGroup ||
        channelType == NCChannelTypeSystem;
    // Direct channels with receipts still clear unread state to emit multi-device unread sync.
    if (isDirectChannel && readReceiptEnabledForCurrentType) {
        syncBlock();
    }
    
    // Other supported channel types clear unread state through the same sync path.
    if (shouldSyncReadStatus) {
        syncBlock();
    }
}

- (void)startSyncConversationReadStatusWithDelay:(BOOL)delay {
    void (^clearUnreadBlock)(void) = ^{
        if (![self.chatVC shouldMarkMessagesAsRead]) {
            return;
        }
        NCBaseChannel *channel = self.chatVC.currentChannel;
        if (!channel) {
            return;
        }
        [channel clearUnreadCountWithCompletion:nil];
    };
    if (delay) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            clearUnreadBlock();
        });
    } else {
        clearUnreadBlock();
    }
}

- (BOOL)enabledReadReceiptMessage:(NCMessageModel *)model {
    if ([self.enabledReadReceiptMessageTypeList containsObject:model.objectName]) {
        return YES;
    }
    return NO;
}

- (NCMessageModel *)messageModelByUId:(NSString *)messageId {
    for (int i = 0; i < self.chatVC.channelDataRepository.count; i++) {
        NCMessageModel *msg = (self.chatVC.channelDataRepository)[i];
        if (msg.messageId == messageId && ![msg.objectName isEqualToString:NCOldMessageNotificationMessageTypeIdentifier]) {
            return msg;
        }
    }
    return nil;
}

#pragma mark - Edit State Management

- (NCEditInputBarConfig *)getCacheEditConfig {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *stateData = [userDefaults objectForKey:[self editingStateDataKey]];
    if (stateData && stateData.count > 0) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:stateData options:kNilOptions error:nil];
        NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NCEditInputBarConfig *editConfig = [[NCEditInputBarConfig alloc] initWithData:jsonStr];
        return editConfig;
    }
    return nil;
}

- (void)clearEditingState {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:[self editingStateDataKey]];
    [userDefaults synchronize];
}

- (NSString *)editingStateDataKey {
    return [NSString stringWithFormat:@"nc_editing_state_%@_%@_%@",
            @(self.chatVC.channelType), self.chatVC.channelId, self.chatVC.subChannelId];
}

@end
