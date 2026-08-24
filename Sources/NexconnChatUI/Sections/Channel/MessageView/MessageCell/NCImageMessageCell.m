//
//  NCImageMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCImageMessageCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCMessageCellTool.h"
#import "NCResendManager.h"

@interface NCMessageModel (NCImageMessageCell)

- (UIImage *)imageMessageThumbnailImage;

@end

@interface NCImageMessageCell ()
@end

@implementation NCImageMessageCell
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(NCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat messagecontentview_height = [self getMessageContentHeight:model];
    messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, messagecontentview_height);
}

- (void)setDataModel:(NCMessageModel *)model {
    if (self.model && self.model.clientId != model.clientId) {
        [self showProgressView];
        [self.progressView updateProgress:model.uploadProgress];
    }
    [super setDataModel:model];

    [self setAutoLayout];
    [self updateStatusContentView:self.model];
    [self updateProgressView];
}

- (void)updateStatusContentView:(NCMessageModel *)model {
    [super updateStatusContentView:model];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      weakSelf.messageActivityIndicatorView.hidden = YES;
    });
}

#pragma mark - Private Methods

+ (CGFloat)getMessageContentHeight:(NCMessageModel *)model {
    CGFloat messagecontentview_height =
        [NCMessageCellTool getThumbnailImageSize:[self getDisplayImage:model]].height;
    if (messagecontentview_height < NCChatUIConfigCenter.ui.globalMessagePortraitSize.height) {
        messagecontentview_height = NCChatUIConfigCenter.ui.globalMessagePortraitSize.height;
    }
    return messagecontentview_height;
}

+ (UIImage *)getDisplayImage:(NCMessageModel *)model {
    UIImage *thumbnailImage = [model imageMessageThumbnailImage];
    if (thumbnailImage) {
        return thumbnailImage;
    }
    if (model.messageDirection == NCMessageDirectionSend) {
        return NCDynamicImage(@"channel_msg_cell_to_thumb_broken_img");
    } else {
        return NCDynamicImage(@"channel_msg_cell_from_thumb_broken_img");
    }
}

- (void)initialize {
    [self.messageContentView addSubview:self.pictureView];
}

- (void)setAutoLayout {
    self.pictureView.image = nil;
    if ([self.model imageMessageThumbnailImage]) {
        UIImage *displayImage = [[self class] getDisplayImage:self.model];
        CGSize imageSize = [NCMessageCellTool getThumbnailImageSize:displayImage];
        self.pictureView.image = displayImage;
        self.messageContentView.contentSize = imageSize;
        self.pictureView.frame = self.messageContentView.bounds;
        self.progressView.frame = self.pictureView.bounds;
    } else {
        NCLogD(@"[NexconnChatUI]: NCMessageModel.content is NOT NCImageMessage object");
    }
}

- (void)updateProgressView {
    if (self.model.sentStatus == NCMessageSentStatusSending ||
        [[NCResendManager sharedManager] needResend:self.model.clientId]) {
        [self showProgressView];
    } else {
        [self hiddenProgressView];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    [super messageCellUpdateSendingStatusEvent:notification];
    NCMessageCellNotificationModel *notifyModel = notification.object;
    NSInteger progress = notifyModel.progress;
    if (self.model.clientId == notifyModel.clientId) {
        NCLogD(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            [self showProgressView];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            if (self.model.sentStatus == NCMessageSentStatusSending) {
                [self showProgressView];
            } else {
                [self hiddenProgressView];
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            [self hiddenProgressView];
        } else if ([notifyModel.actionName
                       isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self showProgressView];
              self.model.uploadProgress = progress;
              [self.progressView updateProgress:progress];
            });
        }
    }
}

- (void)showProgressView {
    if (self.progressView.hidden) {
        self.progressView.hidden = NO;
        [self.progressView startAnimating];
    }
}

- (void)hiddenProgressView {
    if (!self.progressView.hidden) {
        self.progressView.hidden = YES;
        [self.progressView stopAnimating];
    }
}

#pragma mark - Getter

- (NCBaseImageView *)pictureView {
    if (!_pictureView) {
        _pictureView = [[NCBaseImageView alloc] initWithFrame:CGRectZero];
        _pictureView.layer.masksToBounds = YES;
        _pictureView.layer.cornerRadius = 6;
    }
    return _pictureView;
}

- (NCImageMessageProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[NCImageMessageProgressView alloc] init];
        [self.pictureView addSubview:_progressView];
        _progressView.hidden = YES;
    }
    return _progressView;
}
@end
