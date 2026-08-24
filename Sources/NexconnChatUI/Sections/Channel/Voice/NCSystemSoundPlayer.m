//
//  NCSystemSoundPlayer.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSystemSoundPlayer.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCExtensionKit.h"
#import "NCVoicePlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

#define kPlayDuration 0.9

static NCSystemSoundPlayer *ncSystemSoundPlayerHandler = nil;

@interface NCSystemSoundPlayer ()

@property (nonatomic, assign) SystemSoundID soundId;
@property (nonatomic, copy) NSString *soundFilePath;

@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, assign) NCChannelType channelType;
@property (atomic) BOOL isPlaying;
@property (nonatomic, copy) NCSystemSoundPlayerCompletion completion;
@end

static void playSoundEnd(SystemSoundID mySSID, void *myself) {
    AudioServicesRemoveSystemSoundCompletion(mySSID);
    AudioServicesDisposeSystemSoundID(mySSID);

    //    CFRelease(myself);
    [NCSystemSoundPlayer defaultPlayer].isPlaying = NO;
}

@implementation NCSystemSoundPlayer
#pragma mark - Public Methods
+ (NCSystemSoundPlayer *)defaultPlayer {

    @synchronized(self) {
        if (nil == ncSystemSoundPlayerHandler) {
            ncSystemSoundPlayerHandler = [[[self class] alloc] init];
            ncSystemSoundPlayerHandler.isPlaying = NO;
        }
    }

    return ncSystemSoundPlayerHandler;
}

- (void)setIgnoreChannelType:(NCChannelType)channelType channelId:(NSString *)channelId {
    self.channelType = channelType;
    self.channelId = channelId;
}

- (void)resetIgnoreConversation {
    self.channelId = nil;
}

- (void)setSystemSoundPath:(NSString *)path {
    if (nil == path) {
        return;
    }

    _soundFilePath = path;
}

- (void)playSoundByMessage:(NCMessage *)message
             completeBlock:(NCSystemSoundPlayerCompletion)completion {
    if (message.channelIdentifier.channelType == self.channelType &&
        [message.channelIdentifier.channelId isEqualToString:self.channelId]) {
        completion(NO);
    } else {
        self.completion = completion;
        [self needPlaySoundByMessage:message];
    }
}

- (void)needPlaySoundByMessage:(NCMessage *)message {
    if ([NCChatUIUtility isApplicationInBackground]) {
        return;
    }
    // Suppress incoming-message sounds during voice playback or recording.
    if ([NCVoicePlayer defaultPlayer].isPlaying ||
        [NCVoiceRecorder defaultVoiceRecorder].isRecording ||
        [NCVoiceRecorder hqVoiceRecorder].isRecording) {
        self.completion(NO);
        return;
    }

    // Suppress incoming-message sounds while short-video playback or capture owns camera or audio
    // resources.
    if ([NCChatUIUtility isCameraHolding] || [NCChatUIUtility isAudioHolding]) {
        self.completion(NO);
        return;
    }

    if (self.isPlaying) {
        self.completion(NO);
        return;
    }

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];

    NSError *err = nil;

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_7_0
    // Route playback to the speaker.
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride),
                            &audioRouteOverride);
#else
    [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
#endif

    [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];

    [audioSession setActive:YES error:&err];

    if (nil != err) {
        NCLogD(@"[NexconnChatUI]: Exception is thrown when setting audio session");
        self.completion(NO);
        return;
    }
    if (nil == _soundFilePath) {
        NSString *bundlePath = [NCChatUIUtility bundlePathWithName:@"NCChatUI"];

        // no redefined path, use the default
        _soundFilePath = [bundlePath stringByAppendingPathComponent:@"sms-received.caf"];
    }

    if (nil != _soundFilePath) {
        OSStatus error = AudioServicesCreateSystemSoundID(
            (__bridge CFURLRef)[NSURL fileURLWithPath:_soundFilePath], &_soundId);
        if (error !=
            kAudioServicesNoError) { // The sound file could not be registered as a system sound.
            NCLogD(@"[NexconnChatUI]: Exception is thrown when creating system sound ID");
            self.completion(NO);
            return;
        }

        self.isPlaying = YES;
        if (NC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            AudioServicesPlaySystemSoundWithCompletion(_soundId, ^{
              self.isPlaying = NO;
              self.completion(YES);
              return;
            });
        } else {
            AudioServicesPlaySystemSound(_soundId);
            AudioServicesAddSystemSoundCompletion(_soundId, NULL, NULL, playSoundEnd, NULL);
            self.completion(YES);
            return;
        }
    } else {
        NCLogD(@"[NexconnChatUI]: Not found the related sound resource file in NCChatUI.bundle");
        self.completion(NO);
        return;
    }
}

@end
