//
//  NCSightViewController.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightViewController.h"
#import "NCChatUILog.h"
#import "NCSightActionButton.h"
#import "NCSightCapturer.h"
#import "NCSightPlayerController.h"
#import "NCSightPreviewView.h"
#import "NCSightRecorder.h"
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreMotion/CoreMotion.h>
#import <Photos/Photos.h>
#import "NCSightAdaptiveHeader.h"
#import "NCSightActivityState.h"
#import "NCAlertView.h"
#import "NCToastView.h"
#import "NCSightPlayerOverlay.h"
#define ActionBtnSize 120
#define BottomSpace 10
#define OKBtnSize 74
#define AnimateDuration 0.2
#define CommonBtnSize 44
#define Marging 8
#define YOffset ISX ? 28 : 8

AVCaptureVideoOrientation orientationBaseOnAcceleration(CMAcceleration acceleration) {
    AVCaptureVideoOrientation result;
    if (acceleration.x >= 0.75) { /// UIDeviceOrientationLandscapeRight
        result = AVCaptureVideoOrientationLandscapeLeft;
    } else if (acceleration.x <= -0.75) { /// UIDeviceOrientationLandscapeLeft
        result = AVCaptureVideoOrientationLandscapeRight;
    } else if (acceleration.y <= -0.75) { /// UIDeviceOrientationPortrait
        result = AVCaptureVideoOrientationPortrait;
    } else if (acceleration.y >= 0.75) { /// UIDeviceOrientationPortraitUpsideDown
        result = AVCaptureVideoOrientationPortraitUpsideDown;
    } else {
        result = AVCaptureVideoOrientationPortrait;
    }
    return result;
}

@interface NCSightViewController () <NCSightRecorderDelegate, NCSightCapturerOutputDelegate,
                                     NCSightPlayerControllerDelegate, NCSightPreviewViewDelegate>
@property (nonatomic, strong) NCSightPreviewView *sightView;
@property (nonatomic, strong) NCSightCapturer *capturer;
@property (nonatomic, strong) NCBaseButton *switchCameraBtn;
@property (nonatomic, strong) NCBaseButton *dismissBtn;
@property (nonatomic, strong) NCBaseImageView *stillImageView;
@property (nonatomic, strong) NCBaseButton *playBtn;
@property (nonatomic, strong) NCSightActionButton *actionButton;
@property (nonatomic, strong) NCBaseButton *cancelBtn;
@property (nonatomic, strong) NCBaseButton *okBtn;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, strong) NCSightRecorder *recorder;
@property (nonatomic, strong) NCSightPlayerController *playerController;
@property (nonatomic, strong) NSURL *outputUrl;
@property (nonatomic, strong) UIImage *sightThumbnail;
@property (nonatomic, strong) UILabel *tipsLable;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, assign) NSTimeInterval beginTime;
@property (nonatomic, assign) NSTimeInterval endTime;
@property (nonatomic, assign) NCSightViewControllerCameraCaptureMode captureMode;
@property (nonatomic, strong) CMMotionManager *motionManager;
@end

@interface NCSightCapturer (CaptureSetup)
- (BOOL)isReadyForRecording;
@end

@implementation NCSightViewController {
    BOOL _statusBarHidden;
}

- (void)dealloc {
    [self.actionButton quit];
    
    [NCSightActivityState sharedState].cameraHolding = NO;
    [self.motionManager stopAccelerometerUpdates];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionInterruptionEndedNotification
                                                  object:nil];
}
#pragma mark - Properties
- (NCSightPreviewView *)sightView {
    if (!_sightView) {
        _sightView = [[NCSightPreviewView alloc] initWithFrame:CGRectZero];
        _sightView.delegate = self;
    }
    return _sightView;
}

- (NCSightCapturer *)capturer {
    if (!_capturer) {
        _capturer = [[NCSightCapturer alloc] initWithVideoPreviewPlayer:self.sightView.previewLayer];
        _capturer.delegate = self;
    }
    return _capturer;
}

- (NCBaseImageView *)stillImageView {
    if (!_stillImageView) {
        _stillImageView = [[NCBaseImageView alloc] initWithFrame:CGRectZero];
        // TODO_yangyudong
        if ([[UIDevice currentDevice].model containsString:@"iPad"]) {
            _stillImageView.contentMode = UIViewContentModeScaleAspectFill;
        } else {
            _stillImageView.contentMode = UIViewContentModeScaleAspectFit;
        }
        _stillImageView.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
    }
    return _stillImageView;
}

- (NCBaseButton *)switchCameraBtn {
    if (!_switchCameraBtn) {
        _switchCameraBtn = [[NCBaseButton alloc] initWithFrame:CGRectMake(0, 0, CommonBtnSize, CommonBtnSize)];
        [_switchCameraBtn setImage:NCDynamicImage(@"sight_camera_switch_img") forState:UIControlStateNormal];
        [_switchCameraBtn setTitleColor:NCDynamicColor(@"control_title_white_color") forState:UIControlStateNormal];
        _switchCameraBtn.backgroundColor = [UIColor clearColor];
        [_switchCameraBtn addTarget:self
                             action:@selector(switchCameraAction:)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraBtn;
}

- (NCBaseButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [[NCBaseButton alloc] initWithFrame:CGRectMake(0, 0, OKBtnSize, OKBtnSize)];
        [_playBtn setImage:NCDynamicImage(@"video_player_play_btn_img") forState:UIControlStateNormal];
        [_playBtn setImage:NCDynamicImage(@"video_player_pause_btn_img") forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
        _playBtn.enabled = NO;
    }
    return _playBtn;
}

- (NCSightActionButton *)actionButton {
    if (!_actionButton) {
        _actionButton = [[NCSightActionButton alloc] initWithFrame:CGRectMake(0, 0, ActionBtnSize, ActionBtnSize)];
        _actionButton.userInteractionEnabled = NO;
    }
    return _actionButton;
}

- (NCBaseButton *)dismissBtn {
    if (!_dismissBtn) {
        _dismissBtn = [[NCBaseButton alloc] initWithFrame:CGRectMake(0, 0, OKBtnSize, OKBtnSize)];
        [_dismissBtn setImage:NCDynamicImage(@"video_player_top_close_button_img")
                     forState:UIControlStateNormal];
        _dismissBtn.backgroundColor = [UIColor clearColor];
        [_dismissBtn addTarget:self action:@selector(dismissAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissBtn;
}

- (NCBaseButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [[NCBaseButton alloc] initWithFrame:CGRectMake(0, 0, OKBtnSize, OKBtnSize)];
        [_cancelBtn setImage:NCDynamicImage(@"video_player_cancel_btn_img") forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
        _cancelBtn.enabled = NO;
    }
    return _cancelBtn;
}

- (NCBaseButton *)okBtn {
    if (!_okBtn) {
        _okBtn = [[NCBaseButton alloc] initWithFrame:CGRectMake(0, 0, OKBtnSize, OKBtnSize)];
        [_okBtn setImage:NCDynamicImage(@"video_player_done_btn_img") forState:UIControlStateNormal];
        [_okBtn addTarget:self action:@selector(okAction:) forControlEvents:UIControlEventTouchUpInside];
        _okBtn.enabled = NO;
    }
    return _okBtn;
}

- (NCSightRecorder *)recorder {
    if (!_recorder) {
        _recorder = [[NCSightRecorder alloc] initWithVideoSettings:self.capturer.recommendedVideoCompressionSettings
                                                     audioSettings:self.capturer.recommendedAudioCompressionSettings
                                                     dispatchQueue:self.capturer.sessionQueue];
        _recorder.delegate = self;
    }
    return _recorder;
}

- (UILabel *)tipsLable {
    if (!_tipsLable) {
        _tipsLable = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 21)];
        _tipsLable.font = [UIFont systemFontOfSize:14.0f];
        _tipsLable.textAlignment = NSTextAlignmentCenter;
        NSString *text = NCUILocalizedString(@"touch_to_take_a_picture_and_press_andhold_the_recording_video");
        CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName : _tipsLable.font}];
        _tipsLable.frame = CGRectMake(0, 0, textSize.width, textSize.height);
        _tipsLable.text = text;
        _tipsLable.textColor = NCDynamicColor(@"control_title_white_color");
    }
    return _tipsLable;
}

- (NCSightPlayerController *)playerController {
    if (!_playerController) {
        _playerController = [[NCSightPlayerController alloc] init];
        _playerController.overlayHidden = YES;
        _playerController.delegate = self;
        _playerController.isLoopPlayback = YES;
        [_playerController.overlay.centerPlayBtn removeFromSuperview];
    }
    return _playerController;
}

- (CTCallCenter *)callCenter {
    if (!_callCenter) {
        _callCenter = [[CTCallCenter alloc] init];
    }
    return _callCenter;
}

- (CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

#pragma mark - Init
- (instancetype)initWithCaptureMode:(NCSightViewControllerCameraCaptureMode)mode {
    if (self = [super init]) {
        self.captureMode = mode;
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(appWillEnterBackground)
                              name:UIApplicationDidEnterBackgroundNotification
                            object:nil];
        [defaultCenter addObserver:self
                                selector:@selector(sessionInterruptionEnded:)
                                    name:AVCaptureSessionInterruptionEndedNotification
                                  object:nil];


    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        self.captureMode = NCSightViewControllerCameraCaptureModeSight;
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(appWillEnterBackground)
                              name:UIApplicationDidEnterBackgroundNotification
                            object:nil];
        [defaultCenter addObserver:self
                                selector:@selector(sessionInterruptionEnded:)
                                    name:AVCaptureSessionInterruptionEndedNotification
                                  object:nil];


    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [NCSightActivityState sharedState].cameraHolding = YES;
    [self registerNotification];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.sightView];
    [self strechToSuperview:self.sightView];
    self.sightView.hidden = YES;
    CGSize screenSize = self.view.bounds.size;
    self.switchCameraBtn.frame =
        CGRectMake(screenSize.width - CommonBtnSize - Marging, YOffset, CommonBtnSize, CommonBtnSize);
    [self.view addSubview:self.switchCameraBtn];

    [self.view addSubview:self.playerController.view];
    [self strechToSuperview:self.playerController.view];
    self.playerController.view.hidden = YES;

    [self.view addSubview:self.stillImageView];
    [self strechToSuperview:self.stillImageView];
    self.stillImageView.hidden = YES;

    __weak typeof(self) weakSelf = self;
    [self.actionButton setAction:^(NCSightActionState state) {
        [weakSelf handleActionState:state];
    }];

    if (NCSightViewControllerCameraCaptureModePhoto == self.captureMode) {
        self.actionButton.supportLongPress = NO;
    }

    [self.view addSubview:self.dismissBtn];
    [self.view addSubview:self.cancelBtn];
    [self.view addSubview:self.okBtn];
    [self.view addSubview:self.playBtn];

    [self.view addSubview:self.actionButton];
    [self.view addSubview:self.tipsLable];
    [self hideSightCaptureControls];

    self.actionButton.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
    self.actionButton.accessibilityLabel = @"actionButton";
    
    self.cancelBtn.center = self.actionButton.center;
    self.cancelBtn.accessibilityLabel = @"cancelBtn";

    self.okBtn.center = self.actionButton.center;
    self.okBtn.accessibilityLabel = @"okBtn";

    self.playBtn.center = self.actionButton.center;
    self.playBtn.accessibilityLabel = @"playBtn";

    self.dismissBtn.frame = CGRectMake(Marging, YOffset, CommonBtnSize, CommonBtnSize);
    self.dismissBtn.accessibilityLabel = @"dismissBtn";

    self.tipsLable.center = CGPointMake(screenSize.width / 2, self.actionButton.frame.origin.y - 16);
    if (NCSightViewControllerCameraCaptureModeSight == self.captureMode) {
        [self performSelector:@selector(setStatusBarHidden:) withObject:@(YES) afterDelay:0.5];
    }

    [self prepareSightCaptureIfNeeded];

    /// Dismiss recording when an incoming call arrives.
    [self.callCenter setCallEventHandler:^(CTCall *call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (call.callState == CTCallStateIncoming) {
                [weakSelf dismissViewControllerAnimated:NO completion:nil];
            }
        });
    }];

    [self.motionManager startAccelerometerUpdates];
    [self setVideoOrientation];
}

- (void)prepareSightCaptureIfNeeded {
#if TARGET_OS_SIMULATOR
    [self showSightCaptureControls];
#else
    __weak typeof(self) weakSelf = self;
    [self requestCameraAccessIfNeededWithCompletion:^(BOOL granted) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (!granted) {
            [strongSelf showCaptureAccessDeniedWithMessage:NCUILocalizedString(@"camera_access_right")];
            return;
        }
        [strongSelf requestMicrophoneAccessIfNeededWithCompletion:^(BOOL granted) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if (!granted) {
                [strongSelf showCaptureAccessDeniedWithMessage:NCUILocalizedString(@"speaker_access_right")];
                return;
            }
            [strongSelf startSightCaptureIfPossible];
        }];
    }];
#endif
}

- (void)requestCameraAccessIfNeededWithCompletion:(void (^)(BOOL granted))completion {
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (AVAuthorizationStatusAuthorized == authorizationStatus) {
        completion(YES);
        return;
    }
    if (AVAuthorizationStatusNotDetermined == authorizationStatus) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         completion(granted);
                                     });
                                 }];
        return;
    }
    completion(NO);
}

- (void)requestMicrophoneAccessIfNeededWithCompletion:(void (^)(BOOL granted))completion {
    if (NCSightViewControllerCameraCaptureModeSight != self.captureMode) {
        completion(YES);
        return;
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if (![audioSession respondsToSelector:@selector(recordPermission)]) {
        completion(YES);
        return;
    }
    AVAudioSessionRecordPermission recordPermission = audioSession.recordPermission;
    if (AVAudioSessionRecordPermissionGranted == recordPermission) {
        completion(YES);
        return;
    }
    if (AVAudioSessionRecordPermissionUndetermined == recordPermission &&
        [audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession requestRecordPermission:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(granted);
            });
        }];
        return;
    }
    completion(NO);
}

- (void)startSightCaptureIfPossible {
    if (![self hasAvailableCaptureDevices]) {
        [self showCaptureUnavailable];
        return;
    }
    if (NCSightViewControllerCameraCaptureModeSight == self.captureMode && self.callCenter.currentCalls.count > 0) {
        [self showCaptureUnavailable];
        return;
    }
    NCSightCapturer *capturer = self.capturer;
    if (![capturer isReadyForRecording]) {
        [self showCaptureUnavailable];
        return;
    }
    self.sightView.hidden = NO;
    [self showSightCaptureControls];
    [capturer startRunning];
    if (![capturer cameraSupportsTapToFocus]) {
        [self.sightView showFocusBoxAnimationAtPoint:CGPointMake(0.5, 0.5)];
    }
}

- (BOOL)hasAvailableCaptureDevices {
    if (![AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]) {
        return NO;
    }
    if (NCSightViewControllerCameraCaptureModeSight == self.captureMode &&
        ![AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio]) {
        return NO;
    }
    return YES;
}

- (void)showCaptureAccessDeniedWithMessage:(NSString *)message {
    self.actionButton.userInteractionEnabled = NO;
    self.switchCameraBtn.enabled = NO;
    [NCAlertView showAlertController:NCUILocalizedString(@"access_right_title")
                             message:message
                         cancelTitle:NCUILocalizedString(@"ok")
                    inViewController:self];
}

- (void)showCaptureUnavailable {
    self.actionButton.userInteractionEnabled = NO;
    self.switchCameraBtn.enabled = NO;
    [NCToastView showToast:NCUILocalizedString(@"sight_capture_failed") rootView:self.view];
}

- (void)hideSightCaptureControls {
    self.switchCameraBtn.hidden = YES;
    self.dismissBtn.hidden = YES;
    self.actionButton.hidden = YES;
    self.cancelBtn.hidden = YES;
    self.okBtn.hidden = YES;
    self.playBtn.hidden = YES;
    self.tipsLable.hidden = YES;
}

- (void)showSightCaptureControls {
    self.switchCameraBtn.hidden = NO;
    self.dismissBtn.hidden = NO;
    self.actionButton.hidden = NO;
    self.actionButton.userInteractionEnabled = YES;
    self.cancelBtn.hidden = NO;
    self.okBtn.hidden = NO;
    self.playBtn.hidden = NO;
    self.tipsLable.hidden = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setStatusBarHidden:@(YES)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self hideTipsLabel];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setStatusBarHidden:@(NO)];
}

- (void)setStatusBarHidden:(NSNumber *)hidden {
    _statusBarHidden = [hidden boolValue];
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
}

#pragma mark - override

- (BOOL)prefersStatusBarHidden {
    return _statusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark - Helpers
- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeDeviceOrientationNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)didChangeDeviceOrientationNotification:(NSNotification *)notification {
    [self updateSubViewsAutolayout];
    [self setVideoOrientation];
}

- (void)updateSubViewsAutolayout {
    CGSize screenSize = self.view.bounds.size;
    self.switchCameraBtn.frame =
        CGRectMake(screenSize.width - CommonBtnSize - Marging, YOffset, CommonBtnSize, CommonBtnSize);
    self.actionButton.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
    if (self.actionButton.hidden) {
        self.cancelBtn.center = CGPointMake(65.5, screenSize.height - ActionBtnSize - BottomSpace);
        self.okBtn.center = CGPointMake(screenSize.width - 65.5, screenSize.height - ActionBtnSize - BottomSpace);
    } else {
        self.cancelBtn.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
        self.okBtn.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
    }
    self.playBtn.center = self.actionButton.center;
    self.tipsLable.center = CGPointMake(screenSize.width / 2, self.actionButton.frame.origin.y - 16);
}

- (void)setVideoOrientation {
    if ([[UIDevice currentDevice].model containsString:@"iPad"]) {
        UIInterfaceOrientation interfaceOrientation = [NCChatUIUtility getInterfaceOrientationForView:self.view];
        AVCaptureVideoOrientation orientation = (AVCaptureVideoOrientation)interfaceOrientation;
        if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            orientation = AVCaptureVideoOrientationLandscapeLeft;
        } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            orientation = AVCaptureVideoOrientationLandscapeRight;
        }
        self.sightView.previewLayer.connection.videoOrientation = orientation;
    }
}

- (void)strechToSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *formats = @[ @"H:|[view]|", @"V:|[view]|" ];
    for (NSString *each in formats) {
        NSArray *constraints =
            [NSLayoutConstraint constraintsWithVisualFormat:each options:0 metrics:nil views:@{
                @"view" : view
            }];
        [self.view addConstraints:constraints];
    }
}

- (void)showStillImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.stillImageView.image = image;
        self.stillImageView.hidden = NO;
    });
}

- (void)handleActionState:(NCSightActionState)states {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authorizationStatus == AVAuthorizationStatusRestricted || authorizationStatus == AVAuthorizationStatusDenied) {
        self.actionButton.userInteractionEnabled = NO;
        return;
    }
    switch (states) {
    case NCSightActionStateBegin:
        self.dismissBtn.hidden = YES;
        self.playBtn.hidden = YES;
        [self startRecording];
        break;
    case NCSightActionStateClick:
        self.dismissBtn.hidden = YES;
        self.playBtn.hidden = YES;
#if !(TARGET_OS_SIMULATOR)
        [self takeAPhoto];
#else
        [self showStillImage:nil];
#endif
        break;
    case NCSightActionStateDidCancel:
    case NCSightActionStateEnd:
        self.actionButton.hidden = YES;
        [self stopRecording];
        break;
    case NCSightActionStateWillCancel:
        break;
    case NCSightActionStateMoving:
        break;
    default:
        break;
    }
}

- (void)takeAPhoto {
#if !(TARGET_OS_SIMULATOR)
    if (![self.capturer isReadyForRecording]) {
        [self showCaptureUnavailable];
        return;
    }
#endif
    __weak typeof(self) weakSelf = self;
    CMAcceleration acceleration = self.motionManager.accelerometerData.acceleration;
    AVCaptureVideoOrientation orientation = orientationBaseOnAcceleration(acceleration);
    [self.capturer captureStillImage:orientation
                          completion:^(UIImage *image) {
                              [weakSelf showOkCancelBtnWithAnimation:NO];
                              [weakSelf showStillImage:image];
                          }];
}

- (void)startRecording {
    if (!self.isRecording) {
#if !(TARGET_OS_SIMULATOR)
        if (![self.capturer isReadyForRecording]) {
            [self showCaptureUnavailable];
            return;
        }
#endif
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(updateTimeLabel)
                                                    userInfo:nil
                                                     repeats:YES];
        self.isRecording = YES;
#if !(TARGET_OS_SIMULATOR)
        CMAcceleration acceleration = self.motionManager.accelerometerData.acceleration;
        AVCaptureVideoOrientation orientation = orientationBaseOnAcceleration(acceleration);
        [self.recorder prepareToRecord:orientation];
#endif
        self.tipsLable.hidden = NO;
        self.beginTime = [[NSDate date] timeIntervalSince1970];
        [self updateTimeLabel];
    }
}

- (void)stopRecording {
    if (self.isRecording) {
        self.isRecording = NO;
#if !(TARGET_OS_SIMULATOR)
        [self.recorder finishRecording];
#else
        [self sightRecorder:nil didWriteMovieAtURL:nil];
        self.endTime = [[NSDate date] timeIntervalSince1970];
        [self updateTimeLabel];
        [self hideTipsLabel];
#endif
        [self.timer invalidate];
    }
}

- (void)showOkCancelBtnWithAnimation:(BOOL)showPlayBtn {
    self.actionButton.hidden = YES;
    [UIView animateWithDuration:AnimateDuration
                     animations:^{
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        if ([NCChatUIUtility isRTL]) {
            self.okBtn.center = CGPointMake(65.5, screenSize.height - ActionBtnSize - BottomSpace);
            self.cancelBtn.center = CGPointMake(screenSize.width - 65.5, screenSize.height - ActionBtnSize - BottomSpace);
        } else {
            self.cancelBtn.center = CGPointMake(65.5, screenSize.height - ActionBtnSize - BottomSpace);
            self.okBtn.center = CGPointMake(screenSize.width - 65.5, screenSize.height - ActionBtnSize - BottomSpace);
        }
    }
        completion:^(BOOL finished) {
            self.playBtn.hidden = !showPlayBtn;
            self.cancelBtn.hidden = NO;
            self.okBtn.hidden = NO;
            self.playBtn.enabled = YES;
            self.okBtn.enabled = YES;
            self.cancelBtn.enabled = YES;
        }];
}

- (void)sightFailed {
    self.actionButton.hidden = YES;
    self.okBtn.hidden = YES;
    self.playBtn.hidden = YES;
    [UIView animateWithDuration:AnimateDuration
        animations:^{
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            self.cancelBtn.center = CGPointMake(65.5, screenSize.height - ActionBtnSize - BottomSpace);
            self.okBtn.center = CGPointMake(screenSize.width - 65.5, screenSize.height - ActionBtnSize - BottomSpace);
        }
        completion:^(BOOL finished) {
            // Recording failed; leave only the cancel button visible.
            self.cancelBtn.hidden = NO;
            self.cancelBtn.enabled = YES;
        }];
    [self resetCapture];
    [NCToastView showToast:NCUILocalizedString(@"sight_capture_failed") rootView:self.view];
}

- (void)hideTipsLabel {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!weakSelf.isRecording) {
            weakSelf.tipsLable.text = @"";
            weakSelf.tipsLable.backgroundColor = [UIColor clearColor];
        }
    });
}

- (void)showTipsLabel {
    self.tipsLable.hidden = NO;
    self.tipsLable.text = NCUILocalizedString(@"sight_capture_failed");
    self.actionButton.userInteractionEnabled = NO;
    self.okBtn.enabled = NO;
}

- (void)updateTimeLabel {
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    [self updateTimeLabelWithEndTime:current];
}

- (void)updateTimeLabelWithEndTime:(NSTimeInterval)endTime {
    NSTimeInterval current = endTime;
    long seconds = round(current - self.beginTime);
    seconds = seconds > self.actionButton.canRecordMaxDuration ? self.actionButton.canRecordMaxDuration : seconds;
    NSString *tipsText = 0 == seconds ? @"" : [NSString stringWithFormat:@"%ld\"", (long)seconds];
    self.tipsLable.text = tipsText;
}

- (void)resetCapture {
#if !(TARGET_OS_SIMULATOR)
    if (self.capturer) {
        [self.capturer stopRunning];
        self.capturer = nil;
        [self.capturer startRunning];
    }
#endif
}

#pragma mark - NCSightViewControllerDelegate
- (void)cancelVideoPreview {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Target action
- (void)switchCameraAction:(UIButton *)sender {
#if !(TARGET_OS_SIMULATOR)
    [self.capturer switchCamera];
#endif
}

- (void)dismissAction:(UIButton *)sender {
#if !(TARGET_OS_SIMULATOR)
    [self.capturer stopRunning];
#endif
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelAction:(UIButton *)sender {
    //[self.playerController reset];
    self.tipsLable.hidden = NO;
    [self hideTipsLabel];
    self.cancelBtn.hidden = YES;
    self.okBtn.hidden = YES;
    [UIView animateWithDuration:AnimateDuration
        animations:^{
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            self.cancelBtn.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
            self.okBtn.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
        }
        completion:^(BOOL finished) {
            self.playBtn.hidden = NO;
            self.actionButton.hidden = NO;
            self.dismissBtn.hidden = NO;
            self.stillImageView.hidden = YES;
            self.playBtn.selected = NO;
#if !(TARGET_OS_SIMULATOR)
            [self.playerController resetSightPlayer];
            [self.capturer resetAudioSession];
            [self.capturer resetSessionInput];
#endif
            self.playerController.view.hidden = YES;
        }];
    
}

- (void)okAction:(UIButton *)sender {
    if (!self.stillImageView.hidden) {
        [self.capturer stopRunning];
        if ([self.delegate respondsToSelector:@selector(sightViewController:didFinishCapturingStillImage:)]) {
            self.stillImageView.hidden = YES;
            [self.delegate sightViewController:self didFinishCapturingStillImage:self.stillImageView.image];
        }
    } else {
        [self.capturer stopRunning];
        [self.playerController resetSightPlayer];
        [self.playerController.view removeFromSuperview];
        if ([self.delegate respondsToSelector:@selector(sightViewController:didWriteSightAtURL:thumbnail:duration:)]) {

            long seconds = round(self.endTime - self.beginTime);
            seconds =
                seconds > self.actionButton.canRecordMaxDuration ? self.actionButton.canRecordMaxDuration : seconds;
            [self.delegate sightViewController:self
                            didWriteSightAtURL:self.outputUrl
                                     thumbnail:self.sightThumbnail
                                      duration:seconds];
            // Save the short video to the photo library.
            if (self.outputUrl) {
                PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
                [photoLibrary performChanges:^{
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self.outputUrl];
                }
                    completionHandler:^(BOOL success, NSError *_Nullable error) {
                        if (success) {
                            NCLogI(@"NexconnChatUI small video saved to album");
                        } else {
                            NCLogE(@"NexconnChatUI failed to save small video to album");
                        }
                    }];
            }
        }
    }
}

- (void)playAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.playerController play];
    } else {
        [self.playerController pause];
    }
}

#pragma mark - NCSightRecorderDelegate
- (void)sightRecorder:(NCSightRecorder *)recorder didWriteMovieAtURL:(NSURL *)outputURL {
    // 录制失败或异常路径可能回调空 URL / 无效文件（如模拟器 stopRecording 传 nil）。
    // 此时不能继续用无效 URL 创建 AVURLAsset 或进入发送流程，走失败提示并重置状态。
    if (outputURL == nil || outputURL.path.length == 0 ||
        ![[NSFileManager defaultManager] fileExistsAtPath:outputURL.path]) {
        [self sightFailed];
        return;
    }
    NSDictionary *dic = @{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)};
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:outputURL options:dic];
    CMTime audioDuration = audioAsset.duration;
    Float64 audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    
    // Read the recorded asset duration for an accurate final value.
    self.endTime = self.beginTime + audioDurationSeconds;
    [self updateTimeLabelWithEndTime:self.endTime];
    [self hideTipsLabel];

    long duration = round(self.endTime - self.beginTime);
    if (0 == duration) {
        self.playBtn.hidden = YES;
        [self takeAPhoto];
        return;
    }
    [self showOkCancelBtnWithAnimation:YES];
#if TARGET_OS_SIMULATOR
    return;
#else
    self.outputUrl = outputURL;
    self.playerController.sightURL = self.outputUrl;
    self.sightThumbnail = [self.playerController firstFrameImage];
    if (!self.sightThumbnail) {
        self.playBtn.hidden = YES;
        [self showTipsLabel];
        return;
    }
    [self.playerController setFirstFrameThumbnail:self.sightThumbnail];
    //[self.playerController play];
    self.playerController.view.hidden = NO;
#endif
}

- (void)sightRecorder:(NCSightRecorder *)recorder
     didFailWithError:(NSError *)error
               status:(NSInteger)status {
    self.endTime = [[NSDate date] timeIntervalSince1970];
    [self updateTimeLabel];
    [self hideTipsLabel];

    long duration = round(self.endTime - self.beginTime);
    if (0 == duration) {
        self.playBtn.hidden = YES;
        [self takeAPhoto];
    }else {
        // Show the failure state when recording reached at least one second.
        [self sightFailed];
    }
    if ([self.delegate respondsToSelector:@selector(sightViewController:didWriteFailedWith:status:)]) {
        [self.delegate sightViewController:self
                        didWriteFailedWith:error
                                    status:status];
    }
}

#pragma mark - NCSightCapturerDelegate
- (void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self.recorder processSampleBuffer:sampleBuffer];
}

- (void)focusDidfinish:(CGPoint)point {
    CGPoint interestPoint = [self.sightView.previewLayer pointForCaptureDevicePointOfInterest:point];
    [self.sightView showFocusBoxAnimationAtPoint:interestPoint];
    self.actionButton.userInteractionEnabled = YES;
}

#pragma mark - NCSightPlayerControllerDelegate
- (void)playToEnd {
    self.playBtn.selected = NO;
}

#pragma mark - NCSightPreviewViewDelegate
- (void)tappedToFocusAtPoint:(CGPoint)point {
    [self.capturer focusAtPoint:point];
}

#pragma mark - Notification Selector
- (void)appWillEnterBackground {
    [self.playerController pause];
    self.playBtn.selected = NO;
}

- (void)sessionInterruptionEnded:(NSNotification*)notification
{
#if !(TARGET_OS_SIMULATOR)
    [self.capturer resetAudioSession];
    [self.capturer resetSessionInput];
#endif
}
@end
