//
//  NCGIFMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGIFMessageCell.h"
#import "NCChatUI.h"
#import "NCChatUIUtility.h"
#import "NCGIFImage.h"
#import "NCChatUICommonDefine.h"
#import "NCGIFMessageProgressView.h"
#import "NCGIFUtility.h"
#import "NCMessageCellTool.h"
#import "NCChatUIConfig.h"
#import "NCResendManager.h"
#import "NCFileUtility.h"
#define GIFLOADIMAGEWIDTH 36.0f
#define GIFLABLEWIGHT 40.0f
#define GIFLABLEHEIGHT 10.0f

extern NSString *const NCUIDispatchDownloadMediaNotification;

@interface NCMessageModel (NCGIFMessageCell)

- (NSString *)gifMessageLocalPath;
- (NSString *)gifMessageRemoteURL;
- (NSString *)gifMessageName;
- (NSUInteger)gifMessageDataSize;
- (void)setGifMessageLocalPath:(NSString *)localPath;

@end

@interface NCGIFMessageCell ()

@property (nonatomic, strong) NCMessageModel *currentModel;

@property (nonatomic, strong) NCGIFMessageProgressView *gifDownLoadPropressView;

@property (nonatomic, strong) NCBaseButton *loadBackButton;

@property (nonatomic, strong) NCBaseImageView *needLoadImageView;

@property (nonatomic, strong) NCBaseImageView *loadingImageView;

@property (nonatomic, strong) NCBaseImageView *loadfailedImageView;

@property (nonatomic, strong) UILabel *sizeLabel;

@end

@implementation NCGIFMessageCell

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
    CGFloat __messagecontentview_height = 0.0f;
    CGSize size = [NCGIFUtility calculatecollectionViewHeight:model];
    __messagecontentview_height = size.height;
    if (__messagecontentview_height < NCChatUIConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = NCChatUIConfigCenter.ui.globalMessagePortraitSize.height;
    }
    __messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(NCMessageModel *)model {
    [self resetSubViews];
    if (!model) {
        return;
    }
    [super setDataModel:model];
    self.currentModel = model;
    [self calculateContenViewSize:nil];

    // Decide whether to download automatically based on the configured size limit.
    NSInteger maxAutoSize = NCChatUIConfigCenter.message.gifAutoDownloadSizeLimit;
    NSString *localPath = [self.model gifMessageLocalPath];
    if (!(localPath && [NCFileUtility isFileExist:localPath])) {
        localPath = [NCFileUtility fileLocalPathForRemoteURL:[self.model gifMessageRemoteURL]];
    }
    if (localPath.length > 0) {
        [self showGifImageView:localPath];
    } else {
        if ([self.model gifMessageRemoteURL].length > 0 && [self.model gifMessageDataSize] > maxAutoSize * 1024) {
            // Require a tap when the GIF exceeds the limit.
            [self showView:self.needLoadImageView];
        } else {
            // Download automatically when the GIF is within the limit.
            [self downLoadGif];
        }
    }

    [self updateStatusContentView:self.model];
    if (model.sentStatus == NCMessageSentStatusSending || [[NCResendManager sharedManager] needResend:self.model.clientId]) {
        [self showProgressView];
    } else {
        [self hiddenProgressView];
    }
}

- (void)updateStatusContentView:(NCMessageModel *)model{
    [super updateStatusContentView:model];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.messageActivityIndicatorView.hidden = YES;
    });
}

#pragma mark - Private Methods

- (void)initialize {
    [self.messageContentView addSubview:self.gifImageView];
    [self.messageContentView addSubview:self.loadBackButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadMediaStatus:)
                                                 name:NCUIDispatchDownloadMediaNotification
                                               object:nil];

}

- (void)prepareForReuse {
    [super prepareForReuse];
}

- (void)calculateContenViewSize:(id)gifMessage {
    (void)gifMessage;
    CGSize gifSize = [NCGIFUtility calculatecollectionViewHeight:self.currentModel];
    self.messageContentView.contentSize = CGSizeMake(gifSize.width, gifSize.height);
    self.gifImageView.frame = CGRectMake(0, 0, gifSize.width, gifSize.height);
    self.progressView.frame = self.gifImageView.bounds;
    self.loadBackButton.frame = self.gifImageView.frame;
}

- (void)didClickLoadBackButton:(UIButton *)button {
    if (!self.needLoadImageView.hidden) {
        [self downLoadGif];
        return;
    } else if (!self.loadfailedImageView.hidden) {
        [self downLoadGif];
        return;
    }
}

- (void)downLoadGif {
    [self showView:self.loadingImageView];
    long currentClientId = self.currentModel.clientId;
    if (currentClientId > 0) {
        [[NCChatUI shared] downloadMediaMessage:currentClientId
                                       progress:nil
                                     completion:nil
                                         cancel:nil];
        return;
    }

    NSString *mediaUrl = [self.currentModel gifMessageRemoteURL] ?: @"";
    NSString *fileName = [NCGIFUtility downloadFileNameForMediaURLString:mediaUrl defaultExtension:@"gif"];
    if (mediaUrl.length == 0 || fileName.length == 0) {
        NSDictionary *statusDic = @{
            @"clientId" : @(currentClientId),
            @"mediaUrl" : mediaUrl,
            @"type" : @"error",
            @"errorCode" : @(-1)
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:NCUIDispatchDownloadMediaNotification
                                                            object:nil
                                                          userInfo:statusDic];
        return;
    }
    [NCBaseChannel downloadMediaUrl:mediaUrl
                           fileName:fileName
                    progressHandler:^(NSInteger progress) {
        NSDictionary *statusDic = @{
            @"clientId" : @(currentClientId),
            @"mediaUrl" : mediaUrl,
            @"type" : @"progress",
            @"progress" : @(progress)
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:NCUIDispatchDownloadMediaNotification
                                                            object:nil
                                                          userInfo:statusDic];
    } completionHandler:^(NSString * _Nullable mediaPath, NCError * _Nullable error) {
        if (error || mediaPath.length == 0) {
            NSDictionary *statusDic = @{
                @"clientId" : @(currentClientId),
                @"mediaUrl" : mediaUrl,
                @"type" : @"error",
                @"errorCode" : @(error ? error.code : -1)
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:NCUIDispatchDownloadMediaNotification
                                                                object:nil
                                                              userInfo:statusDic];
            return;
        }
        // URL-based 下载底层不写 URL→本地路径映射，此处补写，供重进详情页 fileLocalPathForRemoteURL: 检测已下载状态
        // （合并转发详情页的合成消息无持久化 clientId，只能靠该映射恢复）
        [NCFileUtility setFileLocalPath:mediaPath forRemoteURL:mediaUrl];
        NSDictionary *statusDic = @{
            @"clientId" : @(currentClientId),
            @"mediaUrl" : mediaUrl,
            @"type" : @"success",
            @"mediaPath" : mediaPath
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:NCUIDispatchDownloadMediaNotification
                                                            object:nil
                                                          userInfo:statusDic];
    } cancelHandler:^{
        NSDictionary *statusDic = @{
            @"clientId" : @(currentClientId),
            @"mediaUrl" : mediaUrl,
            @"type" : @"cancel"
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:NCUIDispatchDownloadMediaNotification
                                                            object:nil
                                                          userInfo:statusDic];
    }];
}

- (void)showGifImageView:(NSString *)localPath {
    long clientId = self.model.clientId;
    NSString *mediaUrl = [self.model gifMessageRemoteURL];
    [self showGifImageView:localPath forClientId:clientId mediaUrl:mediaUrl];
}

- (void)showGifImageView:(NSString *)localPath forClientId:(long)clientId mediaUrl:(NSString *)mediaUrl {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfFile:[NCFileUtility correctedFilePath:localPath]];
        NCGIFImage *gifImage = [NCGIFImage animatedImageWithGIFData:data];
        dispatch_main_async_safe(^{
            if (![self isCurrentDownloadStatusForClientId:clientId mediaUrl:mediaUrl]) {
                return;
            }
            if (gifImage) {
                self.gifImageView.hidden = NO;
                self.loadBackButton.hidden = YES;
                self.loadingImageView.hidden = YES;
                self.gifImageView.animatedImage = gifImage;
            } else {
                NCLogD(@"[NexconnChatUI]: NCMessageModel.content is NOT NCGIFMessage object");
            }
        });
    });
}

- (BOOL)isCurrentDownloadStatusForClientId:(long)clientId mediaUrl:(NSString *)mediaUrl {
    if (clientId > 0) {
        return self.model.clientId == clientId && self.currentModel.clientId == clientId;
    }
    if (mediaUrl.length > 0) {
        NSString *currentMediaUrl = [self.model gifMessageRemoteURL] ?: @"";
        NSString *currentModelMediaUrl = [self.currentModel gifMessageRemoteURL] ?: @"";
        return [currentMediaUrl isEqualToString:mediaUrl] && [currentModelMediaUrl isEqualToString:mediaUrl];
    }
    return NO;
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
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            [self showProgressView];
            [self.progressView updateProgress:progress];
        }
    }
}

- (void)showView:(UIView *)showView {
    showView.center = self.loadBackButton.center;
    if (self.loadBackButton.hidden) {
        self.loadBackButton.hidden = NO;
    }
    self.sizeLabel.center =
        CGPointMake(self.loadBackButton.center.x, self.loadBackButton.center.y + 10 + GIFLOADIMAGEWIDTH / 2);
    NSString *size = [self getGIFSize:[self.model gifMessageDataSize]];
    if (size.length > 0) {
        self.sizeLabel.hidden = NO;
        self.sizeLabel.text = size;
    }
    switch (showView.tag) {
    case 1:
        self.needLoadImageView.hidden = NO;
        self.loadingImageView.hidden = YES;
        self.gifDownLoadPropressView.hidden = YES;
        self.messageContentView.userInteractionEnabled = YES;
        self.loadfailedImageView.hidden = YES;
        [self stopAnimation];

        break;
    case 2:
        self.needLoadImageView.hidden = YES;
        self.loadingImageView.hidden = NO;
        self.gifDownLoadPropressView.hidden = YES;
        self.loadfailedImageView.hidden = YES;
        self.messageContentView.userInteractionEnabled = NO;
        [self startAnimation];
        break;
    case 3:
        self.needLoadImageView.hidden = YES;
        self.loadingImageView.hidden = YES;
        self.gifDownLoadPropressView.hidden = NO;
        self.loadfailedImageView.hidden = YES;
        self.messageContentView.userInteractionEnabled = NO;
        [self stopAnimation];

        break;
    case 4:
        self.needLoadImageView.hidden = YES;
        self.loadingImageView.hidden = YES;
        self.gifDownLoadPropressView.hidden = YES;
        self.loadfailedImageView.hidden = NO;
        self.messageContentView.userInteractionEnabled = YES;
        [self stopAnimation];
        break;
    default:
        self.needLoadImageView.hidden = YES;
        self.loadingImageView.hidden = YES;
        self.gifDownLoadPropressView.hidden = YES;
        self.loadfailedImageView.hidden = YES;
        self.loadBackButton.hidden = YES;
        self.sizeLabel.hidden = YES;
        self.gifImageView.animatedImage = nil;
        self.messageContentView.userInteractionEnabled = YES;
        break;
    }
}

- (NSString *)getGIFSize:(CGFloat)size {
    NSString *GIFSize = nil;
    if (size / 1024 / 1024 < 1) {
        GIFSize = [NSString stringWithFormat:@"%dK", (int)size / 1024];
    } else {
        GIFSize = [NSString stringWithFormat:@"%0.2fM", size / 1024 / 1024];
    }

    return GIFSize;
}

- (void)startAnimation {
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
    rotationAnimation.duration = 1.5;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = MAXFLOAT;
    [self.loadingImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopAnimation {
    if (self.loadfailedImageView) {
        [self.loadingImageView.layer removeAnimationForKey:@"rotationAnimation"];
    }
}

- (void)resetSubViews {
    self.gifImageView.animatedImage = nil;
    [self.gifDownLoadPropressView setProgress:0];
    self.loadBackButton.hidden = YES;
    self.needLoadImageView.hidden = YES;
    self.loadingImageView.hidden = YES;
    self.gifDownLoadPropressView.hidden = YES;
    self.loadfailedImageView.hidden = YES;
    self.sizeLabel.text = nil;
    self.sizeLabel.hidden = YES;
}

- (void)showProgressView{
    if (self.progressView.hidden) {
        self.progressView.hidden = NO;
        [self.progressView startAnimating];
    }
}

- (void)hiddenProgressView{
    if (!self.progressView.hidden) {
        self.progressView.hidden = YES;
        [self.progressView stopAnimating];
    }
}

#pragma mark - NSNotification
- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    NSDictionary *statusDic = notify.userInfo;
    long clientId = [statusDic[@"clientId"] longValue];
    NSString *mediaUrl = statusDic[@"mediaUrl"];
    if ([self isCurrentDownloadStatusForClientId:clientId mediaUrl:mediaUrl]) {
        if ([statusDic[@"type"] isEqualToString:@"progress"]) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (![strongSelf isCurrentDownloadStatusForClientId:clientId mediaUrl:mediaUrl]) {
                    return;
                }
                CGFloat progress = (CGFloat)[statusDic[@"progress"] intValue];
                if (strongSelf.gifDownLoadPropressView.hidden) {
                    [strongSelf showView:strongSelf.gifDownLoadPropressView];
                }
                [strongSelf.gifDownLoadPropressView setProgress:progress];
            });
        } else if ([statusDic[@"type"] isEqualToString:@"success"]) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (![strongSelf isCurrentDownloadStatusForClientId:clientId mediaUrl:mediaUrl]) {
                    return;
                }
                [strongSelf.model setGifMessageLocalPath:statusDic[@"mediaPath"]];
                
                [strongSelf showView:strongSelf.gifImageView];
                [strongSelf showGifImageView:statusDic[@"mediaPath"] forClientId:clientId mediaUrl:mediaUrl];

            });
        } else if ([statusDic[@"type"] isEqualToString:@"error"]) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (![strongSelf isCurrentDownloadStatusForClientId:clientId mediaUrl:mediaUrl]) {
                    return;
                }
                [strongSelf showView:strongSelf.loadfailedImageView];
            });
        }
    }
}

#pragma mark - Getters and Setters

- (NCGIFImageView *)gifImageView {
    if (!_gifImageView) {
        _gifImageView = [[NCGIFImageView alloc] initWithFrame:CGRectZero];
        _gifImageView.layer.masksToBounds = YES;
        [_gifImageView setContentMode:UIViewContentModeScaleAspectFill];
        _gifImageView.tag = 5;
    }
    return _gifImageView;
}

- (NCImageMessageProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[NCImageMessageProgressView alloc] init];
        [self.gifImageView addSubview:_progressView];
        _progressView.hidden = YES;
    }
    return _progressView;
}

- (NCBaseButton *)loadBackButton {
    if (!_loadBackButton) {
        _loadBackButton = [[NCBaseButton alloc] initWithFrame:CGRectZero];
        _loadBackButton.backgroundColor = NCDynamicColor(@"text_secondary_color");
        [_loadBackButton addTarget:self
                            action:@selector(didClickLoadBackButton:)
                  forControlEvents:(UIControlEventTouchUpInside)];
        _loadBackButton.hidden = YES;
    }
    return _loadBackButton;
}

- (NCBaseImageView *)needLoadImageView {
    if (!_needLoadImageView) {
        _needLoadImageView = [[NCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, GIFLOADIMAGEWIDTH, GIFLOADIMAGEWIDTH)];
        _needLoadImageView.image = NCDynamicImage(@"channel_msg_cell_gif_needload_img");
        _needLoadImageView.hidden = YES;
        _needLoadImageView.tag = 1;
        [self.loadBackButton addSubview:_needLoadImageView];
    }
    return _needLoadImageView;
}

- (NCBaseImageView *)loadingImageView {
    if (!_loadingImageView) {
        _loadingImageView = [[NCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, GIFLOADIMAGEWIDTH, GIFLOADIMAGEWIDTH)];
        _loadingImageView.image = NCDynamicImage(@"channel_msg_cell_gif_loading_img");
        _loadingImageView.hidden = YES;
        _loadingImageView.tag = 2;
        [self.loadBackButton addSubview:_loadingImageView];
    }
    return _loadingImageView;
}

- (NCGIFMessageProgressView *)gifDownLoadPropressView {
    if (!_gifDownLoadPropressView) {
        _gifDownLoadPropressView = [[NCGIFMessageProgressView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
        _gifDownLoadPropressView.backgroundColor = [UIColor colorWithPatternImage:NCDynamicImage(@"channel_msg_cell_gif_loadprogress_img")];
        _gifDownLoadPropressView.tag = 3;
        _gifDownLoadPropressView.hidden = YES;
        [self.loadBackButton addSubview:_gifDownLoadPropressView];
    }
    return _gifDownLoadPropressView;
}

- (NCBaseImageView *)loadfailedImageView {
    if (!_loadfailedImageView) {
        _loadfailedImageView =
            [[NCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, GIFLOADIMAGEWIDTH, GIFLOADIMAGEWIDTH)];
        _loadfailedImageView.image = NCDynamicImage(@"channel_msg_cell_gif_loadfailed_img");
        _loadfailedImageView.hidden = YES;
        _loadfailedImageView.tag = 4;
        [self.loadBackButton addSubview:_loadfailedImageView];
    }
    return _loadfailedImageView;
}

- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        _sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, GIFLABLEWIGHT, GIFLABLEHEIGHT)];
        _sizeLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAssistantLevel];
        _sizeLabel.numberOfLines = 1;
        _sizeLabel.textAlignment = NSTextAlignmentCenter;
        _sizeLabel.backgroundColor = [UIColor clearColor];
        _sizeLabel.textColor = NCDynamicColor(@"control_title_white_color");
        _sizeLabel.hidden = YES;
        [self.loadBackButton addSubview:_sizeLabel];
    }
    return _sizeLabel;
}

@end
