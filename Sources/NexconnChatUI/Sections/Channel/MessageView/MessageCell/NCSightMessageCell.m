//
//  NCSightMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightMessageCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCMessageCellTool.h"
#import "NCResendManager.h"
#import "NCSightMessageProgressView.h"
extern NSString *const NCUIDispatchDownloadMediaNotification;

@interface NCMessageModel (NCSightMessageCell)

- (long)sightMessageDuration;
- (UIImage *)sightMessageThumbnailImage;
- (void)setSightMessageLocalPath:(NSString *)localPath;

@end

@interface NCSightMessageCell ()
@property (nonatomic, strong) UIView *playButtonView;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) NCBaseImageView *playImage;
@property (nonatomic, strong) UIView *thumbnailOverlayView;
@end

@implementation NCSightMessageCell

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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(NCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat messagecontentview_height = [self getSightImageSize:model].height;
    if (messagecontentview_height < NCChatUIConfigCenter.ui.globalMessagePortraitSize.height) {
        messagecontentview_height = NCChatUIConfigCenter.ui.globalMessagePortraitSize.height;
    }
    messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, messagecontentview_height);
}

- (void)setDataModel:(NCMessageModel *)model {
    [super setDataModel:model];
    self.thumbnailView.image = nil;
    UIImage *thumbnailImage = [self.model sightMessageThumbnailImage];
    if (thumbnailImage) {
        CGSize imageSize = [NCSightMessageCell getSightImageSize:self.model];
        self.durationLabel.text =
            [self getSightDurationLabelText:[self.model sightMessageDuration]];
        self.thumbnailView.image = thumbnailImage;

        self.messageContentView.contentSize = imageSize;
        self.thumbnailView.frame = self.messageContentView.bounds;
        self.thumbnailOverlayView.frame = self.thumbnailView.bounds;
        if (self.progressView.superview) {
            [self.progressView removeFromSuperview];
        }
        self.progressView =
            [[NCSightMessageProgressView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [self.progressView setHidden:YES];
        self.progressView.progressTintColor = NCDynamicColor(@"control_title_white_color");
        [self.thumbnailView addSubview:self.progressView];
        [self.playImage setCenter:CGPointMake(self.thumbnailView.bounds.size.width / 2,
                                              self.thumbnailView.bounds.size.height / 2)];
        self.progressView.center = self.playImage.center;
        CGRect durationLabelBgFrame = CGRectMake(0, self.thumbnailView.bounds.size.height - 21,
                                                 self.thumbnailView.bounds.size.width, 21);
        self.durationLabel.superview.frame = durationLabelBgFrame;
        self.durationLabel.frame =
            CGRectMake(0, 0, durationLabelBgFrame.size.width - 5, durationLabelBgFrame.size.height);
    } else {
        NCLogD(@"[NexconnChatUI]: NCMessageModel.content is NOT NCSightMessage object");
    }

    [self updateStatusContentView:self.model];

    [self updateSightPlayStatus];
}

- (void)updateSightPlayStatus {
    if (self.model.sentStatus == NCMessageSentStatusSending ||
        [[NCResendManager sharedManager] needResend:self.model.clientId]) {
        [self.playButtonView setHidden:YES];
        [self.progressView startIndeterminateAnimation];
        [self.progressView setHidden:NO];
    } else {
        [self.playButtonView setHidden:NO];
        [self.progressView stopIndeterminateAnimation];
        [self.progressView setHidden:YES];
    }
}

- (void)updateStatusContentView:(NCMessageModel *)model {
    [super updateStatusContentView:model];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      weakSelf.messageActivityIndicatorView.hidden = YES;
    });
}

#pragma mark - Private Methods
+ (CGSize)getSightImageSize:(NCMessageModel *)model {
    CGSize imageSize = [model sightMessageThumbnailImage].size;
    // Scale the longest edge to 160 points while preserving the aspect ratio.
    CGFloat rate = imageSize.width / imageSize.height;
    CGFloat imageWidth = 0;
    CGFloat imageHeight = 0;

    if (imageSize.width != 0 && imageSize.height != 0) {
        if (rate > 1.0f) {
            imageWidth = 160;
            imageHeight = 160 / rate;
        } else {
            imageHeight = 160;
            imageWidth = 160 * rate;
        }
    } else {
        imageWidth = imageSize.width;
        imageHeight = imageSize.height;
    }
    return CGSizeMake(imageWidth, imageHeight);
}

- (void)initialize {
    [self.messageContentView addSubview:self.thumbnailView];
    [self.thumbnailView addSubview:self.thumbnailOverlayView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadMediaStatus:)
                                                 name:NCUIDispatchDownloadMediaNotification
                                               object:nil];
}

- (NSString *)getSightDurationLabelText:(long)duration {
    NSInteger minutes = duration / 60;
    NSInteger seconds = round(duration - minutes * 60);
    if (seconds == 60) {
        minutes += 1;
        seconds = 0;
    }
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    NSDictionary *statusDic = notify.userInfo;
    if (self.model.clientId == [statusDic[@"clientId"] longValue]) {
        if ([statusDic[@"type"] isEqualToString:@"progress"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              if ([self.progressView isHidden]) {
                  [self.progressView setHidden:NO];
                  [self.progressView startIndeterminateAnimation];
              }
              [self.progressView setProgress:[statusDic[@"progress"] intValue] animated:YES];
            });
        } else if ([statusDic[@"type"] isEqualToString:@"success"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self.progressView stopIndeterminateAnimation];
              [self.progressView setHidden:YES];
              [self.model setSightMessageLocalPath:statusDic[@"mediaPath"]];
            });
        } else if ([statusDic[@"type"] isEqualToString:@"error"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              if (![self.progressView isHidden]) {
                  [self.progressView stopIndeterminateAnimation];
                  [self.progressView setHidden:YES];
              }

              UIViewController *rootVC = [NCChatUIUtility getKeyWindow].rootViewController;
              UIAlertController *alertController = [UIAlertController
                  alertControllerWithTitle:nil
                                   message:NCUILocalizedString(@"file_download_failed")
                            preferredStyle:UIAlertControllerStyleAlert];
              [alertController
                  addAction:[UIAlertAction actionWithTitle:NCUILocalizedString(@"ok")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *_Nonnull action){
                                                   }]];
              [rootVC presentViewController:alertController animated:YES completion:nil];
            });
        }
    }
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    [super messageCellUpdateSendingStatusEvent:notification];
    NCMessageCellNotificationModel *notifyModel = notification.object;
    NSInteger progress = notifyModel.progress;
    if (self.model.clientId == notifyModel.clientId) {
        NCLogD(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            [self.progressView startIndeterminateAnimation];
            [self.progressView setHidden:NO];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            [self updateSightPlayStatus];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            [self.playButtonView setHidden:NO];
            [self.progressView stopIndeterminateAnimation];
            [self.progressView setHidden:YES];
        } else if ([notifyModel.actionName
                       isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            if (self.progressView.hidden) {
                [self.playButtonView setHidden:YES];
                [self.progressView startIndeterminateAnimation];
                [self.progressView setHidden:NO];
            }
            float pro = progress / 100.0f;
            [self.progressView setProgress:pro animated:YES];
        }
    }
}

#pragma mark - Getters and Setters

- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 21)];
        [_durationLabel setTextAlignment:NSTextAlignmentRight];
        [_durationLabel setBackgroundColor:[UIColor clearColor]];
        [_durationLabel setTextColor:NCDynamicColor(@"control_title_white_color")];
        [_durationLabel setFont:[[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel]];
    }
    return _durationLabel;
}

- (NCBaseImageView *)playImage {
    if (!_playImage) {
        _playImage = [[NCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 41, 41)];
        UIImage *image = NCDynamicImage(@"channel_msg_cell_sight_icon_img");
        _playImage.image = image;
    }
    return _playImage;
}

- (UIView *)playButtonView {
    if (!_playButtonView) {
        _playButtonView = [[UIView alloc] initWithFrame:self.thumbnailView.bounds];
        [_playButtonView addSubview:self.playImage];
        [self.thumbnailView addSubview:_playButtonView];
        NCBaseImageView *backgroudView = [[NCBaseImageView alloc]
            initWithFrame:CGRectMake(0, self.thumbnailView.bounds.size.height - 21,
                                     self.thumbnailView.bounds.size.width, 21)];
        backgroudView.image = NCDynamicImage(@"channel_msg_cell_player_shadow_bottom_img");
        [_playButtonView addSubview:backgroudView];
        [backgroudView addSubview:self.durationLabel];
    }
    return _playButtonView;
}

- (NCBaseImageView *)thumbnailView {
    if (!_thumbnailView) {
        _thumbnailView = [[NCBaseImageView alloc] initWithFrame:CGRectZero];
        _thumbnailView.layer.masksToBounds = YES;
        _thumbnailView.layer.cornerRadius = 6;
    }
    return _thumbnailView;
}

- (UIView *)thumbnailOverlayView {
    if (!_thumbnailOverlayView) {
        _thumbnailOverlayView = [[UIView alloc] initWithFrame:CGRectZero];
        _thumbnailOverlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _thumbnailOverlayView.userInteractionEnabled = NO;
    }
    return _thumbnailOverlayView;
}

@end
