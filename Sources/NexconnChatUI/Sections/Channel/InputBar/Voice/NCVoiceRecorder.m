//
//  NCVoiceRecorder.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCVoiceRecorder.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import <AVFoundation/AVFoundation.h>

static NCVoiceRecorder *ncVoiceRecorderHandler = nil;
static NCVoiceRecorder *ncHQVoiceRecorderHandler = nil;

@interface NCVoiceRecorder () <AVAudioRecorderDelegate>

@property (nonatomic, strong) NSDictionary *recordSettings;
@property (nonatomic, strong) NSURL *recordTempFileURL;
@property (nonatomic) BOOL isRecording;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, weak) id<NCVoiceRecorderDelegate> voiceRecorderDelegate;
@end

@implementation NCVoiceRecorder
#pragma mark - Public Methods
+ (NCVoiceRecorder *)defaultVoiceRecorder {
    @synchronized(self) {
        if (nil == ncVoiceRecorderHandler) {
            ncVoiceRecorderHandler = [[[self class] alloc] init];
            ncVoiceRecorderHandler.recordSettings = @{
                AVFormatIDKey : @(kAudioFormatLinearPCM),
                AVSampleRateKey : @(8000.00f),
                AVNumberOfChannelsKey : @1,
                AVLinearPCMIsNonInterleaved : @NO,
                AVLinearPCMIsFloatKey : @NO,
                AVLinearPCMIsBigEndianKey : @NO
            };

            ncVoiceRecorderHandler.recordTempFileURL =
                [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                           stringByAppendingPathComponent:@"tempAC.wav"]];
            NCLogD(@"[NCChatUIExtension]: Using File called: %@",
                   ncVoiceRecorderHandler.recordTempFileURL);
        }
        return ncVoiceRecorderHandler;
    }
}

+ (NCVoiceRecorder *)hqVoiceRecorder {
    @synchronized(self) {
        if (nil == ncHQVoiceRecorderHandler) {
            ncHQVoiceRecorderHandler = [[[self class] alloc] init];
            ncHQVoiceRecorderHandler.recordSettings = @{
                AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                AVNumberOfChannelsKey : @1,
                AVEncoderBitRateKey : @(32000),
                AVSampleRateKey : @(16000)
            };
            ncHQVoiceRecorderHandler.recordTempFileURL =
                [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                           stringByAppendingPathComponent:@"HQTempAC.aac"]];
            NCLogD(@"[NCChatUIExtension]: Using File called: %@",
                   ncHQVoiceRecorderHandler.recordTempFileURL);
        }
        return ncHQVoiceRecorderHandler;
    }
}

- (BOOL)startRecordWithObserver:(id<NCVoiceRecorderDelegate>)observer {
    self.voiceRecorderDelegate = observer;

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                        error:nil];
    [audioSession setActive:YES error:nil];

    NSError *error = nil;

    if (nil == self.recorder) {
        self.recorder = [[AVAudioRecorder alloc] initWithURL:self.recordTempFileURL
                                                    settings:self.recordSettings
                                                       error:&error];
        self.recorder.delegate = self;
        self.recorder.meteringEnabled = YES;
    }

    BOOL isRecord = NO;
    isRecord = [self.recorder prepareToRecord];
    NCLogD(@"[NCChatUIExtension]: prepareToRecord is %@", isRecord ? @"success" : @"failed");

    isRecord = [self.recorder record];
    NCLogD(@"[NCChatUIExtension]: record is %@", isRecord ? @"success" : @"failed");
    self.isRecording = self.recorder.isRecording;
    return isRecord;
}

- (BOOL)cancelRecord {
    self.voiceRecorderDelegate = nil;
    if (nil != self.recorder && [self.recorder isRecording] &&
        [[NSFileManager defaultManager] fileExistsAtPath:self.recorder.url.path]) {
        [self.recorder stop];
        [self.recorder deleteRecording];
        self.recorder = nil;
        self.isRecording = self.recorder.isRecording;
        if (!NCChatUIConfigCenter.message.isExclusiveSoundPlayer) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [[AVAudioSession sharedInstance]
                  setActive:NO
                withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                      error:nil];
        } else {
            AVAudioSession *audioSession = [AVAudioSession sharedInstance];
            [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
            [audioSession setActive:YES error:nil];
        }
        return YES;
    }
    if (!NCChatUIConfigCenter.message.isExclusiveSoundPlayer) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance]
              setActive:NO
            withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                  error:nil];
    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    }
    return NO;
}
- (void)stopRecord:(void (^)(NSData *, NSTimeInterval))compeletion {
    if (!self.recorder.url) {
        if (compeletion) {
            compeletion(nil, 0);
        }
        return;
    }
    if (!self.recorder.isRecording) {
        if (compeletion) {
            compeletion(nil, 0);
        }
        return;
    }
    NSURL *url = [[NSURL alloc] initWithString:self.recorder.url.absoluteString];
    NSTimeInterval audioLength = self.recorder.currentTime;
    [self.recorder stop];
    NSData *currentRecordData = [NSData dataWithContentsOfURL:url];
    self.isRecording = self.recorder.isRecording;
    self.recorder = nil;
    // Release AVAudioSession so other audio can play non-exclusively.
    if (!NCChatUIConfigCenter.message.isExclusiveSoundPlayer) {
        [[AVAudioSession sharedInstance]
              setActive:NO
            withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                  error:nil];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];

    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    }
    if (compeletion) {
        compeletion(currentRecordData, audioLength);
    }
}
- (CGFloat)updateMeters {
    if (nil != self.recorder) {
        [self.recorder updateMeters];
    }

    float peakPower = [self.recorder averagePowerForChannel:0];
    CGFloat power = (1.0 / 160.0) * (peakPower + 160.0);
    return power;
}
#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if ([self.voiceRecorderDelegate
            respondsToSelector:@selector(NCVoiceAudioRecorderDidFinishRecording:)]) {
        [self.voiceRecorderDelegate NCVoiceAudioRecorderDidFinishRecording:flag];
    }
    self.voiceRecorderDelegate = nil;
    self.isRecording = self.recorder.isRecording;
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    if ([self.voiceRecorderDelegate
            respondsToSelector:@selector(NCVoiceAudioRecorderEncodeErrorDidOccur:)]) {
        [self.voiceRecorderDelegate NCVoiceAudioRecorderEncodeErrorDidOccur:error];
    }

    self.voiceRecorderDelegate = nil;
    self.isRecording = self.recorder.isRecording;
}
@end
