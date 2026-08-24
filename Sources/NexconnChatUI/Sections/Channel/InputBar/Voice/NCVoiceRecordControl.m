//
//  NCVoiceRecordControl.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCVoiceRecordControl.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <UIKit/UIKit.h>

#import "NCAlertView.h"
#import "NCChatUICommonDefine.h"
#import "NCVoiceCaptureControl.h"
#import "NCVoicePlayer.h"

@interface NCVoiceRecordControl () <NCVoiceCaptureControlDelegate>
@property (nonatomic, assign) NCChannelType channelType;
@property (nonatomic, strong) NCVoiceCaptureControl *voiceCaptureControl;
@property (nonatomic, assign) BOOL isAudioRecoderTimeOut;
@end

@implementation NCVoiceRecordControl
- (instancetype)initWithConversationType:(NCChannelType)channelType {
    self = [super init];
    if (self) {
        self.channelType = channelType;
        self.isAudioRecoderTimeOut = NO;
        [self registerNotification];
    }
    return self;
}

// Starts recording a voice message.
- (void)onBeginRecordEvent {
    CTCallCenter *center = [[CTCallCenter alloc] init];
    if (center.currentCalls.count > 0) {
        NSString *alertMessage = NCUILocalizedString(@"audio_holding_warning");
        [NCAlertView showAlertController:alertMessage message:nil hiddenAfterDelay:1];
        return;
    }
    if (self.voiceCaptureControl) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(recordWillBegin)]) {
        if (![self.delegate recordWillBegin]) {
            return;
        }
    }

    if ([NCChatUIUtility isAudioHolding]) {
        NSString *alertMessage = NCUILocalizedString(@"audio_holding_warning");
        [NCAlertView showAlertController:alertMessage message:nil hiddenAfterDelay:1];
        return;
    }

    [self checkRecordPermission:^{
      self.voiceCaptureControl = [[NCVoiceCaptureControl alloc]
          initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width,
                                   [UIScreen mainScreen].bounds.size.height)
            channelType:self.channelType];
      self.voiceCaptureControl.delegate = self;
      if ([NCVoicePlayer defaultPlayer].isPlaying) {
          [[NCVoicePlayer defaultPlayer] resetPlayer];
      }
      [self.voiceCaptureControl startRecord];
      if ([self.delegate respondsToSelector:@selector(voiceRecordControlDidBegin:)]) {
          [self.delegate voiceRecordControlDidBegin:self];
      }
    }];
}

// Finishes recording a voice message.
- (void)onEndRecordEvent {
    if (!self.voiceCaptureControl) {
        return;
    }

    NSData *recordData = [self.voiceCaptureControl stopRecord];
    if (recordData.length == 0) {
        // Recording failed.
        [self.voiceCaptureControl showViewWithErrorMsg:NCUILocalizedString(@"record_voice_failed")];
        [self performSelector:@selector(destroyVoiceCaptureControl) withObject:nil afterDelay:1.0f];
        if ([self.delegate respondsToSelector:@selector(voiceRecordControlDidCancel:)]) {
            [self.delegate voiceRecordControlDidCancel:self];
        }
        return;
    }

    if (self.voiceCaptureControl.duration > 1.0f) {
        if ([self.delegate
                respondsToSelector:@selector(voiceRecordControl:didEnd:duration:error:)]) {
            [self.delegate voiceRecordControl:self
                                       didEnd:recordData
                                     duration:self.voiceCaptureControl.duration
                                        error:nil];
        }
        [self destroyVoiceCaptureControl];
    } else {
        // message too short
        if (!self.isAudioRecoderTimeOut) {
            self.isAudioRecoderTimeOut = NO;
            [self.voiceCaptureControl
                showViewWithErrorMsg:NCUILocalizedString(@"message_too_short")];
            [self performSelector:@selector(destroyVoiceCaptureControl)
                       withObject:nil
                       afterDelay:1.0f];
            if ([self.delegate respondsToSelector:@selector(voiceRecordControlDidCancel:)]) {
                [self.delegate voiceRecordControlDidCancel:self];
            }
        }
    }
}

// Updates the prompt when the touch moves outside the control.
- (void)dragExitRecordEvent {
    [self.voiceCaptureControl showCancelView];
}

- (void)dragEnterRecordEvent {
    [self.voiceCaptureControl hideCancelView];
}

- (void)onCancelRecordEvent {
    if (self.voiceCaptureControl) {
        if ([self.delegate respondsToSelector:@selector(voiceRecordControlDidCancel:)]) {
            [self.delegate voiceRecordControlDidCancel:self];
        }
        [self.voiceCaptureControl cancelRecord];
        [self destroyVoiceCaptureControl];
    }
}

#pragma mark - NCVoiceCaptureControlDelegate
- (void)NCVoiceCaptureControlTimeout:(double)duration {
    self.isAudioRecoderTimeOut = YES;
    [self onEndRecordEvent];
}

- (void)NCVoiceCaptureControlTimeUpdate:(double)duration {
}

#pragma mark - Notification
- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionInterrupted:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
}

- (void)audioSessionInterrupted:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType interruptionType =
        [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    switch (interruptionType) {
    case AVAudioSessionInterruptionTypeBegan: {
        [self onEndRecordEvent];
    } break;
    default:
        break;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private
- (void)destroyVoiceCaptureControl {
    [self.voiceCaptureControl stopTimer];
    [self.voiceCaptureControl removeFromSuperview];
    self.voiceCaptureControl = nil;
    self.isAudioRecoderTimeOut = NO;
}

- (void)checkRecordPermission:(void (^)(void))successBlock {
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(recordPermission)]) {
            if ([AVAudioSession sharedInstance].recordPermission ==
                AVAudioSessionRecordPermissionGranted) {
                successBlock();
            } else if ([AVAudioSession sharedInstance].recordPermission ==
                       AVAudioSessionRecordPermissionDenied) {
                [self alertRecordPermissionDenied];
            } else if ([AVAudioSession sharedInstance].recordPermission ==
                       AVAudioSessionRecordPermissionUndetermined) {
                // Bug 7071637281 修复：首次请求权限时，只请求权限不自动开始录制
                // 用户需要在授权后重新点击录音按钮
                [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                    if (!granted) {
                        [self alertRecordPermissionDenied];
                    }
                    // 注意：不调用 successBlock，用户需要重新点击按钮
                  });
                }];
            }
        }
    } else {
        successBlock();
    }
}

- (void)alertRecordPermissionDenied {
    [NCAlertView showAlertController:NCUILocalizedString(@"access_right_title")
                             message:NCUILocalizedString(@"speaker_access_right")
                         cancelTitle:NCUILocalizedString(@"ok")];
}
@end
