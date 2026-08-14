//
//  NCSightPlayerController.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightPlayerController.h"
#import "NCSightPlayerView.h"
#import "NCSightProgressView.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCChatUICommonDefine.h"
#import "NCSightAdaptiveHeader.h"
#import "NCSightActivityState.h"
#import "NCFileUtility.h"

// AVPlayerItem's status property
#define STATUS_KEYPATH @"status"
#define RATE_KEYPATH @"rate"
/// Playback progress refresh interval
#define REFRESH_INTERVAL 0.01f
@interface NCSightPlayerController () <NCSightTransportDelegate>

@property (strong, nonatomic) AVAsset *asset;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) NCSightPlayerView *playerView;
@property (strong, nonatomic) UILabel *errorTipsLabel;
@property (strong, nonatomic) NCSightProgressView *progressView;

@property (weak, nonatomic) id<NCSightPlayerTransport, NCSightPlayerOverlay> transport;

@property (strong, nonatomic) id timeObserver;
@property (strong, nonatomic) id itemEndObserver;
@property (assign, nonatomic) float lastPlaybackRate;

@property (assign, nonatomic) BOOL isPlaying;

@property (assign, nonatomic) BOOL canceling;

@property (copy, nonatomic) void (^completion)(void);
@property (copy, nonatomic) void (^error)(NSError *error);
@property (copy, nonatomic, nullable) NSString *preferredDownloadFileName;

@property (assign, nonatomic) BOOL isAddStatusObserver;

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, copy) NSString *localPath;
@property (nonatomic, strong) UIImage *thumbnailImage;
@property (assign, nonatomic) BOOL downloadSucceeded;
@end

@implementation NCSightPlayerController

#pragma mark - Init
- (instancetype)initWithURL:(NSURL *)assetURL autoPlay:(BOOL)isauto;
{
    if (self = [super init]) {
        [NCSightActivityState sharedState].playerHolding = YES;
        self.transport.delegate = self;
        self.autoPlay = isauto;
        self.sightURL = assetURL;
        [self registerNotificationCenter];

    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [NCSightActivityState sharedState].playerHolding = YES;
        self.transport.delegate = self;
        [self registerNotificationCenter];
    }
    return self;
}

#pragma mark - Deinit

- (void)dealloc {
    [NCSightActivityState sharedState].playerHolding = NO;
    if (self.isAddStatusObserver) {
        [self.playerItem removeObserver:self forKeyPath:STATUS_KEYPATH];
    }
    [self.player removeObserver:self forKeyPath:RATE_KEYPATH];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_itemEndObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_itemEndObserver
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:_playerItem];
    }
    if (_timeObserver && _player) {
        [_player removeTimeObserver:_timeObserver];
    }
}

#pragma mark - Api

- (void)setSightURL:(NSURL *)assetURL {
    _sightURL = assetURL;
    if (self.overlayHidden) {
        [self.transport hideCenterPlayBtn];
        [self.transport setControlBarHidden:YES];
    }
    _asset = nil;
    _playerItem = nil;
    [self resetPlayer];
    _timeObserver = nil;
}

- (void)setOverlayHidden:(BOOL)overlayHidden {
    _overlayHidden = overlayHidden;
    if (self.overlayHidden) {
        [self.transport hideCenterPlayBtn];
        [self.transport setControlBarHidden:YES];
    }
}

- (UIView *)view {
    return self.playerView;
}

- (id<NCSightPlayerOverlay>)overlay {
    return self.playerView.transport;
}

- (nullable UIImage *)firstFrameImage {
    NSString *videoPath = self.sightURL.path;
    if (videoPath.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        return [self fallbackSightThumbnailImage];
    }

    NSString *imagePath = [[videoPath stringByDeletingPathExtension] stringByAppendingString:@".png"];
    NSRange range = [imagePath rangeOfString:NSTemporaryDirectory()];
    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath] && range.location == NSNotFound) {
        return [UIImage imageWithContentsOfFile:imagePath] ?: [self fallbackSightThumbnailImage];
    }

    // AVAsset* assert = [AVAsset assetWithURL:self.assetURL];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:self.asset];
    generator.appliesPreferredTrackTransform = YES;

    CMTime time = CMTimeMakeWithSeconds(0.0, 600);

    NSError *error = nil;

    CMTime actualTime;

    CGImageRef image = [generator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    if (error || image == NULL) {
        if (image != NULL) {
            CGImageRelease(image);
        }
        return [self fallbackSightThumbnailImage];
    }

    UIImage *shotImage = [[UIImage alloc] initWithCGImage:image];
    if (shotImage && range.location == NSNotFound) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imageData = UIImagePNGRepresentation(shotImage);
            if (imageData) {
                [imageData writeToFile:imagePath atomically:YES];
            }
        });
    }

    CGImageRelease(image);
    return shotImage ?: [self fallbackSightThumbnailImage];
}

- (void)setFirstFrameThumbnail:(nullable UIImage *)image {
    self.thumbnailImage = image;
    [self.transport setThumbnailImage:image];
}

- (void)resetSightPlayer {
    [self resetSightPlayer:YES];
}

- (void)resetSightPlayer:(BOOL)inactivateAudioSession {
    self.canceling = YES;
    [self.transport.centerPlayBtn setImage:NCDynamicImage(@"video_preview_play_btn_normal_img") forState:UIControlStateNormal];
    [self.errorTipsLabel removeFromSuperview];
    if (!self.isPlaying) {
        return;
    }
    [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    self.player.rate = 0;
    self.isPlaying = NO;
    [self.transport setControlBarHidden:YES];
    [self.transport playbackComplete];
    if (inactivateAudioSession) {
        [self setAudioSessionUnActive];
    }
}

- (void)resetPlayer{
    [_player removeObserver:self forKeyPath:RATE_KEYPATH];
    _player = nil;
}

#pragma mark - helper
- (UIImage *)fallbackSightThumbnailImage {
    return self.thumbnailImage ?: NCDynamicImage(@"channel_msg_cell_sight_icon_img");
}

- (void)showDowndLoadFailedControl {
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self.transport stopIndicatorViewAnimating];
        [self.transport.centerPlayBtn setImage:NCDynamicImage(@"video_player_sight_download_failed_img")
                                      forState:UIControlStateNormal];
        self.transport.centerPlayBtn.hidden = NO;
        self.transport.centerPlayBtn.selected = NO;
        CGPoint playBtnCenter = self.transport.centerPlayBtn.center;
        self.errorTipsLabel.center =
            CGPointMake(playBtnCenter.x, CGRectGetMaxY(self.transport.centerPlayBtn.frame) + 16);
        [self.view addSubview:self.errorTipsLabel];
    });
}

- (void)setAudioSessionUnActive {
    [[AVAudioSession sharedInstance] setActive:NO
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:nil];
}
#pragma mark - Properties

- (UILabel *)errorTipsLabel {
    if (!_errorTipsLabel) {
        _errorTipsLabel = [[UILabel alloc] init];
        _errorTipsLabel.font = [UIFont systemFontOfSize:14];
        _errorTipsLabel.textColor = NCDynamicColor(@"control_title_white_color");
        _errorTipsLabel.backgroundColor =
            [UIColor colorWithPatternImage:NCDynamicImage(@"video_player_sight_label_shadow_img")];
        NSString *text = NCUILocalizedString(@"download_failed_click_to_download");
        CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName : _errorTipsLabel.font}];
        _errorTipsLabel.textAlignment = NSTextAlignmentCenter;
        _errorTipsLabel.text = text;
        _errorTipsLabel.frame = CGRectMake(0, 0, textSize.width, textSize.height);
    }
    return _errorTipsLabel;
}

- (NCSightProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[NCSightProgressView alloc] initWithFrame:CGRectMake(0, 0, 63, 63)];
        CGRect bounds = [UIScreen mainScreen].bounds;
        _progressView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    }
    return _progressView;
}
- (void)setLoadingCenter:(CGPoint)center {
    self.progressView.center = center;
}
- (AVAsset *)asset {
    if (!_asset) {
        _asset = [AVAsset assetWithURL:self.sightURL];
    }
    return _asset;
}

- (AVPlayerItem *)playerItem {
    if (!_playerItem) {

        NSArray *keys =
            @[ @"tracks", @"duration", @"commonMetadata", @"availableMediaCharacteristicsWithMediaSelectionOptions" ];
        _playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset automaticallyLoadedAssetKeys:keys];
    }
    return _playerItem;
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [AVPlayer playerWithPlayerItem:self.playerItem];
        [_player addObserver:self
                  forKeyPath:RATE_KEYPATH
                     options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                     context:nil];
    }
    return _player;
}

- (NCSightPlayerView *)playerView {
    if (!_playerView) {
        _playerView = [[NCSightPlayerView alloc] init];
    }
    return _playerView;
}

- (id<NCSightPlayerTransport, NCSightPlayerOverlay>)transport {
    return self.playerView.transport;
}

- (void)prepareWithBlock:(void (^)(void))completion error:(void (^)(NSError *error))error {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.completion = completion;
    self.error = error;
    if (!self.isAddStatusObserver) {
        [self.playerItem addObserver:self
                          forKeyPath:STATUS_KEYPATH
                             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                             context:nil];
        self.isAddStatusObserver = YES;
    }
    

    [self.playerView setPlayer:self.player];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:RATE_KEYPATH] && [keyPath isEqualToString:STATUS_KEYPATH]) {
        return;
    }
    
    long oldValue = [[change objectForKey:NSKeyValueChangeOldKey] longValue];
    long newValue = [[change objectForKey:NSKeyValueChangeNewKey] longValue];
    if (oldValue == newValue) {
        return;
    }
    
    if ([keyPath isEqualToString:RATE_KEYPATH]){
        [self playerDidChangeRate];
        return;
    }
    
    if ([keyPath isEqualToString:STATUS_KEYPATH]) {
        [self playerItemDidChangeStatus];
        return;
    }
}

- (void)playerDidChangeRate{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isPlaying) {
            return;
        }
        // A zero rate while playback is still marked active indicates an external interruption.
        if (self.player.rate == 0) {
            [self.player pause];
            [self makePlayButtonAppear];
            [self setAudioSessionUnActive];
        } else {
            self.transport.centerPlayBtn.hidden = YES;
            self.transport.playBtn.selected = YES;
        }
    });
}

- (void)playerItemDidChangeStatus{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isAddStatusObserver) {
            [self.playerItem removeObserver:self forKeyPath:STATUS_KEYPATH];
            self.isAddStatusObserver = NO;
        }
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {

            // Set up time observers.
            [self addPlayerItemTimeObserver];
            [self addItemEndObserverForPlayerItem];

            CMTime duration = self.playerItem.duration;

            // Synchronize the time display
            [self.transport setCurrentTime:CMTimeGetSeconds(kCMTimeZero) duration:CMTimeGetSeconds(duration)];

            __weak typeof(self) weakSelf = self;
            [self.player seekToTime:kCMTimeZero
                    toleranceBefore:kCMTimeZero
                     toleranceAfter:kCMTimeZero
                  completionHandler:^(BOOL finished) {
                      [weakSelf.transport readyToPlay];
                      [weakSelf.transport willPlay];
                      if (weakSelf.completion) {
                          weakSelf.completion();
                      }
                  }];

            [self loadMediaOptions];

        } else {
            NCLogE(@"Failed to load video %@", self.playerItem.error);
            if (self.error) {
                self.error(self.player.error);
            }
        }
    });
}

- (void)loadMediaOptions {
    NSString *mc = AVMediaCharacteristicLegible;
    AVMediaSelectionGroup *group = [self.asset mediaSelectionGroupForMediaCharacteristic:mc];
    if (group) {
        NSMutableArray *subtitles = [NSMutableArray array];
        for (AVMediaSelectionOption *option in group.options) {
            [subtitles addObject:option.displayName];
        }
    }
}

- (void)subtitleSelected:(NSString *)subtitle {
    NSString *mc = AVMediaCharacteristicLegible;
    AVMediaSelectionGroup *group = [self.asset mediaSelectionGroupForMediaCharacteristic:mc];
    BOOL selected = NO;
    for (AVMediaSelectionOption *option in group.options) {
        if ([option.displayName isEqualToString:subtitle]) {
            [self.playerItem selectMediaOption:option inMediaSelectionGroup:group];
            selected = YES;
        }
    }
    if (!selected) {
        [self.playerItem selectMediaOption:nil inMediaSelectionGroup:group];
    }
}

#pragma mark - Time Observers

- (void)addPlayerItemTimeObserver {

    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        _timeObserver = nil;
    }
    // Create 0.5 second refresh interval - REFRESH_INTERVAL == 0.5
    CMTime interval = CMTimeMakeWithSeconds(REFRESH_INTERVAL, NSEC_PER_SEC);

    // Main dispatch queue
    dispatch_queue_t queue = dispatch_get_main_queue();

    // Create callback block for time observer
    __weak NCSightPlayerController *weakSelf = self;
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    void (^callback)(CMTime time) = ^(CMTime time) {
        NSTimeInterval currentTime = CMTimeGetSeconds(time);
        [weakSelf.transport setCurrentTime:currentTime duration:duration];
    };

    // Add observer and store pointer for future use
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:callback];
}

- (void)addItemEndObserverForPlayerItem {

    NSString *name = AVPlayerItemDidPlayToEndTimeNotification;

    NSOperationQueue *queue = [NSOperationQueue mainQueue];

    __weak NCSightPlayerController *weakSelf = self;
    void (^callback)(NSNotification *note) = ^(NSNotification *notification) {
        if (weakSelf.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            [weakSelf.player seekToTime:kCMTimeZero
                        toleranceBefore:kCMTimeZero
                         toleranceAfter:kCMTimeZero
                      completionHandler:^(BOOL finished) {
                          if (weakSelf.isLoopPlayback) {
                              weakSelf.isPlaying = YES;
                              [weakSelf.player play];
                          } else {
                              [weakSelf.transport playbackComplete];
                              if ([weakSelf.delegate respondsToSelector:@selector(playToEnd)]) {
                                  [weakSelf.delegate playToEnd];
                              }
                              [weakSelf setAudioSessionUnActive];
                          }
                      }];
        }

    };

    self.itemEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:name
                                                                             object:self.playerItem
                                                                              queue:queue
                                                                         usingBlock:callback];
}

#pragma mark - NCSightTransportDelegate

- (void)play {
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    /// Hide the center play button for playback that was not triggered by a direct button tap.
    self.transport.centerPlayBtn.hidden = YES;
    [self.errorTipsLabel removeFromSuperview];
    [self.progressView removeFromSuperview];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.sightURL.path]) {
        NSString *remoteURL = self.sightURL.absoluteString;
        NSString *fileName = [NCFileUtility recheckedFileName:self.preferredDownloadFileName];
        if (fileName.pathExtension.length == 0) {
            NSString *fileKey = [NCFileUtility fileKeyForURL:remoteURL];
            fileName = fileKey.length > 0 ? [NSString stringWithFormat:@"Sight_%@.mp4", fileKey] : nil;
        }
        if (remoteURL.length == 0 || fileName.length == 0) {
            [self showDowndLoadFailedControl];
            return;
        }

        [self.view addSubview:self.progressView];
        [self.progressView startIndeterminateAnimation];
        self.downloadSucceeded = NO;
        __weak typeof(self) weakSelf = self;
        [NCBaseChannel downloadMediaUrl:remoteURL
                               fileName:fileName
                        progressHandler:^(NSInteger progress) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf.progressView setProgress:progress / 100.0f animated:YES];
            });
        }
                      completionHandler:^(NSString *_Nullable mediaPath, NCError *_Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if (error || mediaPath.length == 0) {
                [strongSelf p_handleSightDownloadError:error];
                return;
            }
            [strongSelf p_handleDownloadedSightAtPath:mediaPath];
        }
                          cancelHandler:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf p_handleSightDownloadError:nil];
        }];

    } else {
        if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            [self.transport readyToPlay];
            [self.transport willPlay];
            self.isPlaying = YES;
            [self.player play];
        } else {
            __weak typeof(self) weakSelf = self;
            [self prepareWithBlock:^{
                [weakSelf.transport willPlay];
                weakSelf.isPlaying = YES;
                [weakSelf.player play];
            }
                error:^(NSError *error){

                }];
        }
    }
}

- (void)p_handleDownloadedSightAtPath:(NSString *)mediaPath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:mediaPath]) {
        [self p_handleSightDownloadError:nil];
        return;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf.progressView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.5];
        strongSelf.sightURL = [[NSURL alloc] initFileURLWithPath:mediaPath];
        if (!strongSelf.isAutoPlay || strongSelf.canceling) {
            if (strongSelf.canceling) {
                strongSelf.canceling = NO;
            }
            strongSelf.transport.centerPlayBtn.hidden = NO;
            strongSelf.transport.centerPlayBtn.selected = NO;
            [strongSelf.transport setControlBarHidden:YES];
            return;
        }
        if ([NCChatUIUtility isApplicationInBackground]) {
            [strongSelf makePlayButtonAppear];
            return;
        }
        [strongSelf prepareWithBlock:^{
            strongSelf.isPlaying = YES;
            [strongSelf.player play];
        }
            error:^(NSError *error) {
            }];
    });
}

- (void)p_handleSightDownloadError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView stopIndeterminateAnimation];
        [self.progressView removeFromSuperview];
        [self showDowndLoadFailedControl];
        if (error && self.error) {
            self.error(error);
        }
    });
}

- (void)pause {
    if (!self.isPlaying) {
        return;
    }
    self.lastPlaybackRate = self.player.rate;
    [self.player pause];
    self.isPlaying = NO;
    [self setAudioSessionUnActive];
}

- (void)stop {
    [self.player setRate:0.0f];
    self.isPlaying = NO;
    [self.transport playbackComplete];
    [self setAudioSessionUnActive];
}

- (void)jumpedToTime:(NSTimeInterval)time {
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero];
}

- (void)scrubbingDidStart {
    self.lastPlaybackRate = self.player.rate;
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        _timeObserver = nil;
    }
}

- (void)scrubbedToTime:(NSTimeInterval)time {
    if (!self.isAddStatusObserver) {
        [self prepareWithBlock:self.completion error:self.error];
    }
    [self.playerItem cancelPendingSeeks];
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero];
}

- (void)scrubbingDidEnd {
    [self addPlayerItemTimeObserver];
    if (self.lastPlaybackRate > 0.0f) {
        self.isPlaying = YES;
    }
}

- (void)cancel {
    [NCSightActivityState sharedState].playerHolding = NO;
    [_player setRate:0.0f];
    if ([self.delegate respondsToSelector:@selector(closeSightPlayer)]) {
        [self.delegate closeSightPlayer];
    }
    self.canceling = YES;
    [self setAudioSessionUnActive];
}

- (BOOL)prefersControlBardHidden {
    if (self.isOverlayHidden) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)prefersBottomBarHidden {
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.sightURL.path]) {
        return NO;
    }
    return YES;
}

#pragma mark - Notification Selector
- (void)registerNotificationCenter {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(appWillEnterBackground)
                          name:UIApplicationDidEnterBackgroundNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(deviceOrientationDidChange:)
                          name:UIApplicationDidChangeStatusBarFrameNotification
                        object:nil];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation interfaceOrientation = [UIDevice currentDevice].orientation;
    if (interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight || interfaceOrientation == UIDeviceOrientationPortrait){
        CGRect bounds = [UIScreen mainScreen].bounds;
        self.progressView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
        self.errorTipsLabel.center =
            CGPointMake(self.progressView.center.x, self.progressView.center.y + 47);
    }
}

- (void)appWillEnterBackground {
    if (self.isPlaying) {
        [self.player pause];
        [self makePlayButtonAppear];
        [self setAudioSessionUnActive];
    }
}
// Restores the play controls.
- (void)makePlayButtonAppear {
    self.isPlaying = NO;
    self.transport.centerPlayBtn.hidden = NO;
    self.transport.centerPlayBtn.selected = NO;
    self.transport.playBtn.selected = NO;
}
@end
