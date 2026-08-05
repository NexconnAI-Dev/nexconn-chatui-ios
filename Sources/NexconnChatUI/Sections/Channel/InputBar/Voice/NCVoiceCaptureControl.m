//
//  NCVoiceCaptureControl.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCVoiceCaptureControl.h"
#import "NCChatUICommonDefine.h"
#import "NCVoiceRecorder.h"
#import "NCChatUIConfig.h"
#import "NCBaseImageView.h"
@interface NCVoiceCaptureControl () <NCVoiceRecorderDelegate>

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NCBaseImageView *recordStatusView;
@property (nonatomic, strong) UILabel *escapeTimeLabel;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) NCVoiceRecorder *myRecorder;
@property (nonatomic, strong) NSData *wavAudioData;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) double escapeTime;
@property (nonatomic, assign) double seconds;
@property (nonatomic, assign) BOOL isStopped;
/*!
 Current channel type.
 */
@property (nonatomic, assign) NCChannelType channelType;
@end
@implementation NCVoiceCaptureControl
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame channelType:(NCChannelType)type {
    self = [super initWithFrame:frame];
    if (self) {
        self.channelType = type;
        [self initSubviews];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
}

#pragma mark - Public Methods

- (void)startRecord {
    // Show the recording UI.
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self];

    [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.02
                                                  target:self
                                                selector:@selector(scheduleOperarion)
                                                userInfo:nil
                                                 repeats:YES];
    [self.myRecorder startRecordWithObserver:self];
    self.seconds = 0;
    [self.timer fire];
}

- (void)cancelRecord {
    [self.myRecorder cancelRecord];
    [self stopTimer];
    [self removeFromSuperview];
}

- (void)showViewWithErrorMsg:(NSString *)errorMsg {
    self.recordStatusView.image = NCDynamicImage(@"channel_mic_too_short_img");
    self.textLabel.text = errorMsg ?: NCUILocalizedString(@"message_too_short");
    [self.textLabel setBackgroundColor:[UIColor clearColor]];
    self.textLabel.textColor = NCDynamicColor(@"control_title_white_color");
    self.textLabel.frame = CGRectMake(0, 127, self.contentView.frame.size.width, 22);
}

- (void)showCancelView {
    self.recordStatusView.image = NCDynamicImage(@"channel_mic_return_img");
    self.textLabel.text = NCUILocalizedString(@"release_to_cancel_title");
    [self.textLabel setBackgroundColor:NCDynamicColor(@"hint_color")];
    self.textLabel.textColor = NCDynamicColor(@"control_title_white_color");
    self.textLabel.frame = CGRectMake((self.contentView.frame.size.width-136)/2, 126, 136, 20);

}

- (void)hideCancelView {
    self.recordStatusView.image = NCDynamicImage(@"channel_mic_volume_0_img");
    self.textLabel.text = NCUILocalizedString(@"slide_up_to_cancel_title");
    [self.textLabel setBackgroundColor:[UIColor clearColor]];
    self.textLabel.textColor = NCDynamicColor(@"control_title_white_color");
    self.textLabel.frame = CGRectMake(0, 127, self.contentView.frame.size.width, 22);
}

#pragma mark - NCVoiceRecorderDelegate
- (void)NCVoiceAudioRecorderDidFinishRecording:(BOOL)success {
    NCLogD(@"%s: %d", __FUNCTION__, success);
}

- (void)NCVoiceAudioRecorderEncodeErrorDidOccur:(NSError *)error {
    NCLogD(@"%s", __FUNCTION__);
}

#pragma mark - Private Methods
- (void)initSubviews {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cancelRecord)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.recordStatusView];
    [self.contentView addSubview:self.escapeTimeLabel];
    [self.contentView addSubview:self.textLabel];


    _myRecorder = [NCVoiceRecorder hqVoiceRecorder];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.escapeTime = NCChatUIConfigCenter.message.maxVoiceDuration;
#pragma clang diagnostic pop
    self.seconds = 0;
    self.isStopped = NO;
}

- (void)setSeconds:(double)seconds {
    _seconds = seconds;
    int leftTime = ceil(self.escapeTime - self.seconds);
    if (leftTime <= 11) {
        if (leftTime > 1) {
            [self.escapeTimeLabel setText:[NSString stringWithFormat:@"%d", leftTime - 1]];
        } else {
            self.escapeTimeLabel.text = @"!";
            self.textLabel.text = NCUILocalizedString(@"message_too_long");
        }
        self.escapeTimeLabel.hidden = NO;
        self.recordStatusView.hidden = YES;
    } else {
        self.escapeTimeLabel.hidden = YES;
    }

    if (self.escapeTime < self.seconds) {
        if ([self.delegate respondsToSelector:@selector(NCVoiceCaptureControlTimeout:)]) {
            [self.delegate NCVoiceCaptureControlTimeout:self.escapeTime];
        }
    }
    if ([self.delegate respondsToSelector:@selector(NCVoiceCaptureControlTimeUpdate:)]) {
        [self.delegate NCVoiceCaptureControlTimeUpdate:_seconds];
    }
}

- (NSData *)stopRecord {
    [self stopTimer];
    if (self.isStopped) {
        return nil;
    } else {
        __block NSData *_wavData = nil;
        __block NSTimeInterval ses = 0.0f;
        [self.myRecorder stopRecord:^(NSData *wavData, NSTimeInterval secs) {
            _wavData = wavData;
            ses = secs;
        }];
        if (self.escapeTime < self.seconds) {
            _duration = self.escapeTime;
        } else {
            _duration = ses;
        }
        _wavAudioData = _wavData;
        self.isStopped = YES;
        return _wavData;
    }
}

- (void)scheduleOperarion {
    self.seconds += 0.02;
    float volume = [_myRecorder updateMeters];
    if ([self.textLabel.text isEqualToString:NCUILocalizedString(@"release_to_cancel_title")]) {
        return;
    }
    UIImage *image = nil;
    if (volume > 0.0f && volume < 0.85f) {
        image = NCDynamicImage(@"channel_mic_volume_1_img");
    } else if (volume >= 0.85f && volume < 0.87f) {
        image = NCDynamicImage(@"channel_mic_volume_2_img");
    } else if (volume >= 0.87f && volume < 0.88f) {
        image = NCDynamicImage(@"channel_mic_volume_3_img");
    } else if (volume >= 0.88f && volume < 0.90f) {
        image = NCDynamicImage(@"channel_mic_volume_4_img");
    } else if (volume >= 0.90f && volume < 0.92f) {
        image = NCDynamicImage(@"channel_mic_volume_5_img");
    } else if (volume >= 0.92f && volume < 0.94f) {
        image = NCDynamicImage(@"channel_mic_volume_6_img");
    } else if (volume >= 0.94f && volume < 0.96f) {
        image = NCDynamicImage(@"channel_mic_volume_7_img");
    } else if (volume >= 0.96f && volume <= 1.0f) {
        image = NCDynamicImage(@"channel_mic_volume_8_img");
    }
    if (image) {
        [self.recordStatusView setImage:image];
    }
}

- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - Getter
- (UILabel *)textLabel{
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 127, self.contentView.frame.size.width, 22)];
        [_textLabel setTextAlignment:NSTextAlignmentCenter];
        [_textLabel setFont:[[NCChatUIConfig defaultConfig].font fontOfGuideLevel]];
        [_textLabel setText:NCUILocalizedString(@"slide_up_to_cancel_title")];
        _textLabel.textColor = NCDynamicColor(@"control_title_white_color");
        _textLabel.layer.cornerRadius = 2;
        _textLabel.layer.masksToBounds = YES;

    }
    return _textLabel;
}

- (UILabel *)escapeTimeLabel{
    if (!_escapeTimeLabel) {
        _escapeTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.contentView.frame.size.width-100)/2, 21.0f, 100, 90)];
        _escapeTimeLabel.tag = 444;
        _escapeTimeLabel.font = [[NCChatUIConfig defaultConfig].font fontOfSize:80];
        _escapeTimeLabel.textAlignment = NSTextAlignmentCenter;
        [_escapeTimeLabel setTextColor:NCDynamicColor(@"control_title_white_color")];
        [_escapeTimeLabel setTextAlignment:NSTextAlignmentCenter];
    }
    return _escapeTimeLabel;
}

- (NCBaseImageView *)recordStatusView{
    if (!_recordStatusView) {
        _recordStatusView = [[NCBaseImageView alloc] initWithFrame:CGRectMake(29.0f, 20.0f, 102, 102)];
        [_recordStatusView setImage:NCDynamicImage(@"channel_mic_volume_0_img")];
    }
    return _recordStatusView;
}

- (UIView *)contentView{
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 160)];
        [_contentView setCenter:CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2 - 34)];
        _contentView.backgroundColor = [NCChatUIUtility generateDynamicColor:NCMASKCOLOR(0x000000, 0.6) darkColor:NCMASKCOLOR(0x000000, 0.8)];;
        _contentView.layer.cornerRadius = 6;
        _contentView.layer.masksToBounds = YES;
    }
    return _contentView;
}
@end
