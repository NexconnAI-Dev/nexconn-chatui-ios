//
//  NCHDVoiceMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCHDVoiceMessageCell.h"
#import "NCChatUI.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCHDVoiceMsgDownloadInfo.h"
#import "NCHDVoiceMsgDownloadManager.h"
#import "NCMessageCellTool.h"
#import "NCVoicePlayer.h"

static NSTimer *hq_previousAnimationTimer = nil;
static UIImageView *hq_previousPlayVoiceImageView = nil;
static NCMessageDirection hq_previousMessageDirection;

#define Voice_Height 40
#define voice_Unread_View_Width 8
#define Play_Voice_View_Width 16
static CGFloat const kAudioBubbleMinWidth = 70.0f;
static CGFloat const kAudioBubbleMaxWidth = 180.0f;
@interface NCMessageCell ()
- (void)messageContentViewFrameDidChanged;
@end

@interface NCMessageModel (NCHDVoiceMessageCell)

+ (NSString *)hqVoiceMessageLocalPathFromMessage:(NCMessage *)message;
- (long)hqVoiceMessageDuration;
- (NSString *)hqVoiceMessageLocalPath;
- (NSString *)hqVoiceMessageRemoteURL;
- (NSString *)hqVoiceMessageDownloadFileName;
- (NSString *)latestHQVoiceMessageLocalPath;
- (void)setHQVoiceMessageLocalPath:(NSString *)localPath;

@end

@interface NCHDVoiceMessageCell () <NCVoicePlayerObserver>
@property (nonatomic) CGSize voiceViewSize;
@property (nonatomic, strong) NSTimer *animationTimer;
@property (nonatomic) int animationIndex;
@property (nonatomic, strong) NCVoicePlayer *voicePlayer;

@end

@implementation NCHDVoiceMessageCell
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
    [self disableCurrentAnimationTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(NCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height = Voice_Height;

    if (__messagecontentview_height < NCChatUIConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = NCChatUIConfigCenter.ui.globalMessagePortraitSize.height;
    }

    __messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(NCMessageModel *)model {
    [super setDataModel:model];
    [self resetAnimationTimer];

    [self setMessageInfo];
    [self updateSubViewsLayout];
    [self updateVoiceDownloadStatusView];
}

#pragma mark - Public API
- (void)playVoice {
    [self removeUnreadTagView];
    [self disablePreviousAnimationTimer];

    if (self.model.clientId == self.voicePlayer.messageClientId) {
        if (self.voicePlayer.isPlaying) {
            [self.voicePlayer stopPlayVoice];
        } else {
            [self startPlayingVoiceData];
        }
    } else {
        [self startPlayingVoiceData];
    }
}

- (void)stopPlayingVoice {
    if (self.model.clientId == self.voicePlayer.messageClientId) {
        if (self.voicePlayer.isPlaying) {
            [self stopPlayingVoiceData];
            [self disableCurrentAnimationTimer];
        }
    }
}

#pragma mark - NCVoicePlayerObserver
- (void)PlayerDidFinishPlaying:(BOOL)isFinish {
    if (isFinish) {
        [self disableCurrentAnimationTimer];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(NSError *)error {
    [self disableCurrentAnimationTimer];
}

#pragma mark - Notification

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetActiveEventInBackgroundMode)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(resetByExtensionModelEvents)
               name:@"NCUIExtensionModelResetVoicePlayingNotification"
             object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(voiceWillPlay:)
                                                 name:kNotificationVoiceWillPlayNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(voiceDidPlay:)
                                                 name:kNotificationPlayVoice
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopPlayingVoiceDataIfNeed:)
                                                 name:kNotificationStopVoicePlayer
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadStatus:)
                                                 name:NCHQDownloadStatusChangeNotify
                                               object:nil];
}

- (void)updateDownloadStatus:(NSNotification *)noti {
    NCHDVoiceMsgDownloadInfo *info = noti.object;
    if (info.hqVoiceMsg.clientId == self.model.clientId) {
        NCHQDownloadStatus status = info.status;
        if (status == NCHQDownloadStatusDownloading || status == NCHQDownloadStatusWaiting) {
            [self.voiceUnreadTagView setHidden:YES];
            [self indicatorAnimating];
            [self hideFailedStatusView];
        } else if (status == NCHQDownloadStatusFailed) {
            [self.voiceUnreadTagView setHidden:YES];
            [self indicatorHiding];
            [self showFailedStatusView];
        } else if (status == NCHQDownloadStatusSuccess) {
            [self.model
                setHQVoiceMessageLocalPath:[NCMessageModel
                                               hqVoiceMessageLocalPathFromMessage:info.hqVoiceMsg]];
            [self indicatorHiding];
            [self hideFailedStatusView];
            if (NCMessageDirectionReceive == self.model.messageDirection &&
                !self.model.receivedStatusInfo.isListened) {
                [self.voiceUnreadTagView setHidden:NO];
            }
        }
    }
}

- (void)voiceWillPlay:(NSNotification *)notification {
    NSNumber *msgIdNum = notification.object;
    if (msgIdNum && [msgIdNum longLongValue] == self.model.clientId) {
        [self removeUnreadTagView];
    }
}

- (void)voiceDidPlay:(NSNotification *)notification {
    long clientId = [notification.object longValue];
    if (clientId == self.model.clientId) {
        [self disableCurrentAnimationTimer];
        [self enableCurrentAnimationTimer];
    }
}

#pragma mark - Private Methods

- (void)initialize {
    [self showBubbleBackgroundView:YES];
    self.messageContentView.accessibilityLabel = @"messageContentView";
    [self.messageContentView addSubview:self.playVoiceView];
    [self.messageContentView addSubview:self.voiceDurationLabel];

    [self registerNotification];
}

- (void)resetAnimationTimer {
    if (self.voicePlayer.messageClientId == self.model.clientId) {
        if ((self.voicePlayer.isPlaying)) {
            [self disableCurrentAnimationTimer];
            [self enableCurrentAnimationTimer];
        }
    } else {
        [self disableCurrentAnimationTimer];
    }
}

- (void)setMessageInfo {
    if ([self.model hqVoiceMessageDuration] > 0) {
        self.voiceDurationLabel.text =
            [NSString stringWithFormat:@"%ld''", [self.model hqVoiceMessageDuration]];
    } else {
        NCLogD(@"[NexconnChatUI]: NCMessageModel.content is NOT NCHDVoiceMessage object");
    }
}

- (CGFloat)getBubbleWidth:(long)duration {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGFloat audioBubbleWidth =
        kAudioBubbleMinWidth + (kAudioBubbleMaxWidth - kAudioBubbleMinWidth) * duration /
                                   NCChatUIConfigCenter.message.maxVoiceDuration;
#pragma clang diagnostic pop
    audioBubbleWidth =
        audioBubbleWidth > kAudioBubbleMaxWidth ? kAudioBubbleMaxWidth : audioBubbleWidth;
    return audioBubbleWidth;
}

- (void)updateSubViewsLayout {
    CGFloat audioBubbleWidth = [self getBubbleWidth:[self.model hqVoiceMessageDuration]];
    CGFloat voiceHeight = NCChatUIConfigCenter.ui.globalMessagePortraitSize.height;
    self.messageContentView.contentSize = CGSizeMake(audioBubbleWidth, voiceHeight);
    if ([NCChatUIUtility isRTL]) {
        if (self.model.messageDirection == NCMessageDirectionSend) {
            self.playVoiceView.image = NCDynamicImage(@"channel_msg_cell_receive_voice_3_img");
            [self.voiceDurationLabel setTextColor:NCDynamicColor(@"text_primary_color")];
            self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
            self.playVoiceView.frame = CGRectMake(12, (voiceHeight - Play_Voice_View_Width) / 2,
                                                  Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(
                CGRectGetMaxX(self.playVoiceView.frame) + 8, 0,
                audioBubbleWidth - (CGRectGetMaxX(self.playVoiceView.frame) + 8), voiceHeight);
        } else {
            self.voiceDurationLabel.textAlignment = NSTextAlignmentRight;
            self.playVoiceView.frame =
                CGRectMake(self.messageContentView.frame.size.width - 12 - Play_Voice_View_Width,
                           (voiceHeight - Play_Voice_View_Width) / 2, Play_Voice_View_Width,
                           Play_Voice_View_Width);
            self.voiceDurationLabel.frame =
                CGRectMake(12, 0, CGRectGetMinX(self.playVoiceView.frame) - 20, voiceHeight);
            [self.voiceDurationLabel setTextColor:NCDynamicColor(@"text_primary_color")];
            self.playVoiceView.image = NCDynamicImage(@"channel_msg_cell_send_voice_3_img");
        }
    } else {

        if (self.model.messageDirection == NCMessageDirectionSend) {
            self.voiceDurationLabel.textAlignment = NSTextAlignmentRight;
            self.playVoiceView.frame =
                CGRectMake(self.messageContentView.frame.size.width - 12 - Play_Voice_View_Width,
                           (voiceHeight - Play_Voice_View_Width) / 2, Play_Voice_View_Width,
                           Play_Voice_View_Width);
            self.voiceDurationLabel.frame =
                CGRectMake(12, 0, CGRectGetMinX(self.playVoiceView.frame) - 20, voiceHeight);
            [self.voiceDurationLabel setTextColor:NCDynamicColor(@"text_primary_color")];
            self.playVoiceView.image = NCDynamicImage(@"channel_msg_cell_send_voice_3_img");
        } else {
            self.playVoiceView.image = NCDynamicImage(@"channel_msg_cell_receive_voice_3_img");
            [self.voiceDurationLabel setTextColor:NCDynamicColor(@"text_primary_color")];
            self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
            self.playVoiceView.frame = CGRectMake(12, (voiceHeight - Play_Voice_View_Width) / 2,
                                                  Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(
                CGRectGetMaxX(self.playVoiceView.frame) + 8, 0,
                audioBubbleWidth - (CGRectGetMaxX(self.playVoiceView.frame) + 8), voiceHeight);
        }
    }

    [self addVoiceUnreadTagView];
}

- (void)updateVoiceDownloadStatusView {
    if (self.model.messageDirection == NCMessageDirectionSend &&
        self.model.sentStatus != NCMessageSentStatusSent) {
        return;
    }
    // 聊天页面和合并转发页面均复用该 cell，合并转发内的消息 clientId <= 0
    if (self.model.clientId <= 0) {
        return;
    }
    if ([self.model hqVoiceMessageLocalPath].length <= 0) {
        NCGetMessageByIdParams *params =
            [[NCGetMessageByIdParams alloc] initWithMessageClientId:self.model.clientId];
        [NCBaseChannel
            getMessageByIdWithParams:params
                          completion:^(NCMessage *_Nullable message, NCError *_Nullable error) {
                            (void)error;
                            if (message) {
                                [[NCHDVoiceMsgDownloadManager defaultManager]
                                    pushVoiceMsgs:@[ message ]
                                         priority:YES];
                            }
                          }];
        if ([[NCChatUI shared] getCurrentNetworkStatus] == NCChatUINetworkStatusNotReachable) {
            [self indicatorHiding];
            [self showFailedStatusView];
        } else {
            [self indicatorAnimating];
        }
    } else {
        [self indicatorHiding];
        [self hideFailedStatusView];
    }
}

// todo cyenux
- (void)resetByExtensionModelEvents {
    [self stopPlayingVoiceData];
    [self disableCurrentAnimationTimer];
}

- (void)addVoiceUnreadTagView {
    [self.voiceUnreadTagView removeFromSuperview];
    self.voiceUnreadTagView.image = nil;
    [self.voiceUnreadTagView setHidden:YES];
    CGSize size = self.messageContentView.contentSize;
    CGFloat voiceHeight = size.height;
    if (NCMessageDirectionReceive == self.model.messageDirection) {
        CGFloat x = CGRectGetMaxX(self.messageContentView.frame) + 8;
        if ([NCChatUIUtility isRTL]) {
            x = CGRectGetMinX(self.messageContentView.frame) - 8 - voice_Unread_View_Width;
        }
        if (NO == self.model.receivedStatusInfo.isListened) {
            self.voiceUnreadTagView = [[NCBaseImageView alloc]
                initWithFrame:CGRectMake(x,
                                         self.messageContentView.frame.origin.y +
                                             (voiceHeight - voice_Unread_View_Width) / 2,
                                         voice_Unread_View_Width, voice_Unread_View_Width)];
            self.voiceUnreadTagView.accessibilityLabel = @"voiceUnreadTagView";
            if ([self.model hqVoiceMessageLocalPath].length > 0) {
                [self.voiceUnreadTagView setHidden:NO];
            } else {
                [self.voiceUnreadTagView setHidden:YES];
            }
            [self.baseContentView addSubview:self.voiceUnreadTagView];
            self.voiceUnreadTagView.image = NCDynamicImage(@"channel_msg_cell_voice_unread_img");
        }
    }
}

- (void)removeUnreadTagView {
    if (self.voiceUnreadTagView) {
        self.voiceUnreadTagView.hidden = YES;
        [self.voiceUnreadTagView removeFromSuperview];
        self.voiceUnreadTagView = nil;
    }
}

#pragma mark - Overwrite
- (void)messageContentViewFrameDidChanged {
    [super messageContentViewFrameDidChanged];
    if (NCMessageDirectionReceive == self.model.messageDirection) {
        CGSize size = self.messageContentView.contentSize;
        CGFloat voiceHeight = size.height;
        if (NCMessageDirectionReceive == self.model.messageDirection) {
            CGFloat x = CGRectGetMaxX(self.messageContentView.frame) + 8;
            if ([NCChatUIUtility isRTL]) {
                x = CGRectGetMinX(self.messageContentView.frame) - 8 - voice_Unread_View_Width;
            }
            if (NO == self.model.receivedStatusInfo.isListened) {
                self.voiceUnreadTagView.frame =
                    CGRectMake(x,
                               self.messageContentView.frame.origin.y +
                                   (voiceHeight - voice_Unread_View_Width) / 2,
                               voice_Unread_View_Width, voice_Unread_View_Width);
            }
        }
    }
}

#pragma mark - stop and disable timer during background mode.
- (void)resetActiveEventInBackgroundMode {
    [self stopPlayingVoiceData];
    [self disableCurrentAnimationTimer];
}

- (void)stopPlayingVoiceDataIfNeed:(NSNotification *)notification {
    long clientId = [notification.object longValue];
    if (clientId == self.model.clientId) {
        [self disableCurrentAnimationTimer];
    }
}

- (NSString *)getCorrectedPath:(NSString *)localPath {
    if (localPath.length > 0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
            return localPath;
        } else {
            NSUInteger location = [localPath rangeOfString:@"Library/Caches/NCChatUI"].location;
            if (location != NSNotFound) {
                NSString *relativePath = [localPath substringFromIndex:location];
                NSString *path = NSHomeDirectory();
                path = [path stringByAppendingPathComponent:relativePath];
                return path;
            } else {
                return localPath;
            }
        }
    } else {
        return nil;
    }
}

- (void)startPlayingVoiceData {
    NSString *localPath = [self getCorrectedPath:[self.model latestHQVoiceMessageLocalPath]];
    if (localPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:localPath]) {

        /**
         *  if the previous voice message is playing, then
         *  stop it and reset the prevoius animation timer indicator
         */
        //        [self stopPlayingVoiceData];

        //        BOOL bPlay = [self.voicePlayer playVoice:[@(self.model.clientId) stringValue]
        //                                       voiceData:_voiceMessage.wavAudioData
        //                                        observer:self];
        NSError *error;
        NSData *wavAudioData = [[NSData alloc] initWithContentsOfFile:localPath
                                                              options:NSDataReadingMappedAlways
                                                                error:&error];
        //        NSData *wavAudioData = [NSData dataWithContentsOfFile:_voiceMessage.localPath];
        BOOL bPlay = [self.voicePlayer playVoice:self.model.channelType
                                       channelId:self.model.channelId
                                 messageClientId:self.model.clientId
                                       voiceData:wavAudioData
                                        observer:self];
        // if failed to play the voice message, reset all indicator.
        if (!bPlay) {
            [self stopPlayingVoiceData];
        } else {
            [self enableCurrentAnimationTimer];
        }
    } else {
        if (!self.model.receivedStatusInfo) {
            self.model.receivedStatusInfo = [[NCMessageReceivedStatusInfo alloc] init];
        }
        self.statusContentView.hidden = NO;
        [self indicatorAnimating];
        void (^completion)(NSString *_Nullable, NCError *_Nullable) =
            ^(NSString *_Nullable mediaPath, NCError *_Nullable error) {
              if (error || mediaPath.length == 0) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                    [self indicatorHiding];
                    [self showFailedStatusView];
                  });
                  return;
              }
              dispatch_async(dispatch_get_main_queue(), ^{
                [self.model setHQVoiceMessageLocalPath:mediaPath];
                [self indicatorHiding];
                [self hideFailedStatusView];
                if (NCMessageDirectionReceive == self.model.messageDirection &&
                    !self.model.receivedStatusInfo.isListened) {
                    [self.voiceUnreadTagView setHidden:NO];
                }
                [self startPlayingVoiceData];
              });
            };
        void (^cancel)(void) = ^{
          [self indicatorHiding];
        };
        if (self.model.clientId > 0) {
            [[NCChatUI shared] downloadMediaMessage:self.model.clientId
                                           progress:^(int progress) {

                                           }
                                         completion:completion
                                             cancel:cancel];
        } else if ([self.model hqVoiceMessageRemoteURL].length > 0 &&
                   [self.model hqVoiceMessageDownloadFileName].length > 0) {
            [[NCChatUI shared] downloadMediaFile:[self.model hqVoiceMessageDownloadFileName]
                                        mediaUrl:[self.model hqVoiceMessageRemoteURL]
                                        progress:^(int progress) {

                                        }
                                      completion:completion
                                          cancel:cancel];
        } else {
            [self indicatorHiding];
            [self showFailedStatusView];
        }
    }
}

- (void)showFailedStatusView {
    // Sender-side voice messages already have a local audio file and need no download handling.
    //    if (self.model.messageDirection == MessageDirection_RECEIVE) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.messageFailedStatusView) {
          self.statusContentView.hidden = NO;
          self.messageFailedStatusView.hidden = NO;
      }
    });
    //    }
}

- (void)hideFailedStatusView {
    // Sender-side voice messages already have a local audio file and need no download handling.
    //    if (self.model.messageDirection == MessageDirection_RECEIVE) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.messageFailedStatusView) {
          self.messageFailedStatusView.hidden = YES;
      }
    });
    //    }
}

- (void)indicatorAnimating {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.messageActivityIndicatorView &&
          NCMessageDirectionReceive == self.model.messageDirection) {
          self.statusContentView.hidden = NO;
          self.messageActivityIndicatorView.hidden = NO;
          [self.messageActivityIndicatorView startAnimating];
      }
    });
}

- (void)indicatorHiding {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.messageActivityIndicatorView) {
          self.messageActivityIndicatorView.hidden = YES;
          [self.messageActivityIndicatorView stopAnimating];
      }
    });
}

- (void)stopPlayingVoiceData {
    if (self.voicePlayer.isPlaying) {
        [self.voicePlayer stopPlayVoice];
    }
}

- (void)enableCurrentAnimationTimer {
    self.animationTimer =
        [NSTimer scheduledTimerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(scheduleAnimationOperation)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.animationTimer forMode:NSRunLoopCommonModes];
    [self.animationTimer fire];

    hq_previousAnimationTimer = self.animationTimer;
    hq_previousPlayVoiceImageView = self.playVoiceView;
    hq_previousMessageDirection = self.model.messageDirection;
}

/**
 *  Implement the animation operation
 */
- (void)scheduleAnimationOperation {
    NCLogD(@"%s", __FUNCTION__);

    self.animationIndex++;
    NSString *playingIndicatorIndex;
    NSString *playingIndicatorIndexKey;
    if (NCMessageDirectionSend == self.model.messageDirection) {
        playingIndicatorIndex =
            [NSString stringWithFormat:@"to_voice_%d", (self.animationIndex % 4)];
        playingIndicatorIndexKey = [NSString
            stringWithFormat:@"channel_msg_cell_send_voice_%d_img", (self.animationIndex % 4)];
    } else {
        playingIndicatorIndex =
            [NSString stringWithFormat:@"from_voice_%d", (self.animationIndex % 4)];
        playingIndicatorIndexKey = [NSString
            stringWithFormat:@"channel_msg_cell_receive_voice_%d_img", (self.animationIndex % 4)];
    }
    NCLogD(@"playingIndicatorIndex > %@", playingIndicatorIndex);
    UIImage *image = NCDynamicImage(playingIndicatorIndexKey);
    if ([NCChatUIUtility isRTL]) {
        image = [image imageFlippedForRightToLeftLayoutDirection];
    }
    self.playVoiceView.image = image;
}

- (void)disableCurrentAnimationTimer {
    if (self.animationTimer && [self.animationTimer isValid]) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        self.animationIndex = 0;
    }
    UIImage *image;
    if (NCMessageDirectionSend == self.model.messageDirection) {
        image = NCDynamicImage(@"channel_msg_cell_send_voice_3_img");
    } else {
        image = NCDynamicImage(@"channel_msg_cell_receive_voice_3_img");
    }
    if ([NCChatUIUtility isRTL]) {
        self.playVoiceView.image = [image imageFlippedForRightToLeftLayoutDirection];
    } else {
        self.playVoiceView.image = image;
    }
}

- (void)disablePreviousAnimationTimer {
    if (hq_previousAnimationTimer && [hq_previousAnimationTimer isValid]) {
        [hq_previousAnimationTimer invalidate];
        hq_previousAnimationTimer = nil;

        /**
         *  reset the previous playVoiceView indicator image
         */
        if (hq_previousPlayVoiceImageView) {
            if (NCMessageDirectionSend == self.model.messageDirection) {
                hq_previousPlayVoiceImageView.image =
                    NCDynamicImage(@"channel_msg_cell_send_voice_3_img");
            } else {
                hq_previousPlayVoiceImageView.image =
                    NCDynamicImage(@"channel_msg_cell_receive_voice_3_img");
            }
            hq_previousPlayVoiceImageView = nil;
            hq_previousMessageDirection = 0;
        }
    }
}

#pragma mark - Getter

- (NCVoicePlayer *)voicePlayer {
    if (!_voicePlayer) {
        _voicePlayer = [NCVoicePlayer defaultPlayer];
    }
    return _voicePlayer;
}

- (NCBaseImageView *)playVoiceView {
    if (!_playVoiceView) {
        _playVoiceView = [[NCBaseImageView alloc] initWithFrame:CGRectZero];
    }
    return _playVoiceView;
}

- (UILabel *)voiceDurationLabel {
    if (!_voiceDurationLabel) {
        _voiceDurationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
        _voiceDurationLabel.font = [[NCChatUIConfig defaultConfig].font fontOfGuideLevel];
    }
    return _voiceDurationLabel;
}
@end
