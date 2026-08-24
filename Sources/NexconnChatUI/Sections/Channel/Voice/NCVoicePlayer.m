//
//  NCVoicePlayer.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCVoicePlayer.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCHDVoiceMsgDownloadManager.h"
#import <AVFoundation/AVFoundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

NSString *const kNCContinuousPlayNotification = @"NCContinuousPlayNotification";
NSString *const kNotificationStopVoicePlayer = @"kNotificationStopVoicePlayer";
NSString *const kNotificationVoiceWillPlayNotification = @"kNotificationVoiceWillPlayNotification";
NSString *const kNotificationPlayVoice = @"kNotificationPlayVoice";
static BOOL bSensorStateStart = YES;
static NCVoicePlayer *ncVoicePlayerHandler = nil;

@interface NCMessageModel (NCVoicePlayer)

- (NSString *)hqVoiceMessageRemoteURL;
- (NSString *)hqVoiceMessageDownloadFileName;
- (void)setHQVoiceMessageLocalPath:(NSString *)localPath;

@end

@interface NCVoicePlayer () <AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic, weak) id<NCVoicePlayerObserver> voicePlayerObserver;
@property (nonatomic) NSString *playerCategory;
- (void)enableSystemProperties;
- (void)setDefaultAudioSession:(NSString *)category;
- (void)disableSystemProperties;
- (BOOL)startPlayVoice:(NSData *)data;
- (BOOL)shouldFallbackToRemoteHQVoiceDownloadForModel:(NCMessageModel *)model;
@end

@implementation NCVoicePlayer

+ (NCVoicePlayer *)defaultPlayer {
    @synchronized(self) {
        if (nil == ncVoicePlayerHandler) {
            ncVoicePlayerHandler = [[[self class] alloc] init];
            ncVoicePlayerHandler.playerCategory = AVAudioSessionCategoryPlayback;
        }
    }
    return ncVoicePlayerHandler;
}

- (void)setDefaultAudioSession:(NSString *)category {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NCLogD(@"[NexconnChatUI]: [audioSession category ] %@", [audioSession category]);
    //    // Use speaker playback by default, but do not replace AVAudioSessionCategoryRecord while
    //    recording. if(![[audioSession category ] isEqualToString:AVAudioSessionCategoryRecord])
    [audioSession setCategory:category
                        error:nil]; // 2016-12-05, edited by dulizhao: use this category so audio
                                    // plays in silent mode.
    [audioSession setActive:YES error:nil];
}

// Handles proximity-sensor state changes.
- (void)sensorStateChange:(NSNotification *)notification {
    if (bSensorStateStart) {
        bSensorStateStart = NO;

        dispatch_async(dispatch_get_main_queue(), ^{
          if ([[UIDevice currentDevice] proximityState] == YES) {
              self.playerCategory = AVAudioSessionCategoryPlayAndRecord;
              NCLogD(@"[NexconnChatUI]: Device is close to user");
              [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                                     error:nil];
          } else {
              NCLogD(@"[NexconnChatUI]: Device is not close to user");
              self.playerCategory = AVAudioSessionCategoryPlayback;
              [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                                     error:nil];
          }
          bSensorStateStart = YES;
        });
    }
}

- (void)playAudio:(NCMessageModel *)model {
    [self sendVoiceWillPlayNotification:model];
    if ([model.content isKindOfClass:[NCHDVoiceMessage class]]) {
        [self playHQVoiceMessage:model];
    } else {
        NCLogD(@"[NexconnChatUI]:  messages are not supported play");
    }
}

- (void)playNormalVoiceMessage:(NCMessageModel *)model {
    NCHDVoiceMessage *voiceContent = (NCHDVoiceMessage *)model.content;
    if (voiceContent.localPath.length > 0 &&
        [[NSFileManager defaultManager] fileExistsAtPath:voiceContent.localPath]) {
        NSError *error;
        NSData *wavAudioData = [[NSData alloc] initWithContentsOfFile:voiceContent.localPath
                                                              options:NSDataReadingMappedAlways
                                                                error:&error];
        [self playVoice:model.channelType
                  channelId:model.channelId
            messageClientId:model.clientId
                  voiceData:wavAudioData
                   observer:nil];
    } else {
        NCLogD(@"[NexconnChatUI]: NCHDVoiceMessage.localPath is NULL");
    }
}

- (void)playHQVoiceMessage:(NCMessageModel *)model {
    NCHDVoiceMessage *voiceContent = (NCHDVoiceMessage *)model.content;
    if (voiceContent.localPath.length > 0 &&
        [[NSFileManager defaultManager] fileExistsAtPath:voiceContent.localPath]) {
        NSError *error;
        NSData *wavAudioData = [[NSData alloc] initWithContentsOfFile:voiceContent.localPath
                                                              options:NSDataReadingMappedAlways
                                                                error:&error];
        [self playVoice:model.channelType
                  channelId:model.channelId
            messageClientId:model.clientId
                  voiceData:wavAudioData
                   observer:nil];
    } else if ([self shouldFallbackToRemoteHQVoiceDownloadForModel:model]) {
        self.messageClientId = model.clientId;
        self.channelType = model.channelType;
        self.channelId = model.channelId;
        __weak typeof(self) weakSelf = self;
        [NCBaseChannel downloadMediaUrl:[model hqVoiceMessageRemoteURL]
                               fileName:[model hqVoiceMessageDownloadFileName]
                        progressHandler:nil
                      completionHandler:^(NSString *_Nullable mediaPath, NCError *_Nullable error) {
                        if (error || mediaPath.length == 0) {
                            return;
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                          __strong typeof(weakSelf) strongSelf = weakSelf;
                          if (!strongSelf) {
                              return;
                          }
                          [model setHQVoiceMessageLocalPath:mediaPath];
                          [strongSelf playHQVoiceMessage:model];
                        });
                      }
                          cancelHandler:nil];
    } else {
        self.messageClientId = model.clientId;
        self.channelType = model.channelType;
        self.channelId = model.channelId;
        NCGetMessageByIdParams *params =
            [[NCGetMessageByIdParams alloc] initWithMessageClientId:model.clientId];
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
    }
}

- (BOOL)shouldFallbackToRemoteHQVoiceDownloadForModel:(NCMessageModel *)model {
    if (!model || model.clientId > 0) {
        return NO;
    }
    return [model hqVoiceMessageRemoteURL].length > 0 &&
           [model hqVoiceMessageDownloadFileName].length > 0;
}

- (BOOL)playVoice:(NCChannelType)channelType
          channelId:(NSString *)channelId
    messageClientId:(long)messageClientId
          voiceData:(NSData *)data
           observer:(id<NCVoicePlayerObserver>)observer {
    if (self.isPlaying) {
        [self resetPlayer];
    }

    self.voicePlayerObserver = observer;
    self.messageClientId = messageClientId;
    self.channelType = channelType;
    self.channelId = channelId;
    [self enableSystemProperties];
    [self setDefaultAudioSession:_playerCategory];
    return [self startPlayVoice:data];
}

// Handles normal playback completion.
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NCLogD(@"%s", __FUNCTION__);

    self.isPlaying = self.audioPlayer.playing;
    [self disableSystemProperties];

    // notify at the end
    if ([self.voicePlayerObserver respondsToSelector:@selector(PlayerDidFinishPlaying:)]) {
        [self.voicePlayerObserver PlayerDidFinishPlaying:flag];
    }

    // set the observer to nil
    self.voicePlayerObserver = nil;
    self.audioPlayer = nil;
    if (!NCChatUIConfigCenter.message.isExclusiveSoundPlayer) {
        [[AVAudioSession sharedInstance]
              setActive:NO
            withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                  error:nil];
    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    }
    [self sendPlayFinishNotification];
    [self sendContinuousPlayNotification];
}

- (void)sendContinuousPlayNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNCContinuousPlayNotification
                                                        object:@(self.messageClientId)
                                                      userInfo:@{
                                                          @"channelType" : @(self.channelType),
                                                          @"channelId" : self.channelId
                                                      }];
}

- (void)sendVoiceWillPlayNotification:(NCMessageModel *)model {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kNotificationVoiceWillPlayNotification
                      object:@(model.clientId)
                    userInfo:@{
                        @"channelType" : @(model.channelType),
                        @"channelId" : model.channelId
                    }];
}

- (void)sendPlayStartNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPlayVoice
                                                        object:@(self.messageClientId)
                                                      userInfo:@{
                                                          @"channelType" : @(self.channelType),
                                                          @"channelId" : self.channelId
                                                      }];
}

- (void)sendPlayFinishNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationStopVoicePlayer
                                                        object:@(self.messageClientId)
                                                      userInfo:@{
                                                          @"channelType" : @(self.channelType),
                                                          @"channelId" : self.channelId
                                                      }];
}
// Handles audio decoding failures.
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NCLogD(@"%s", __FUNCTION__);
    // do something
    self.isPlaying = self.audioPlayer.playing;
    [self disableSystemProperties];

    // notify at the end
    if ([self.voicePlayerObserver respondsToSelector:@selector(audioPlayerDecodeErrorDidOccur:)]) {
        [self.voicePlayerObserver audioPlayerDecodeErrorDidOccur:error];
    }
    self.voicePlayerObserver = nil;
    self.audioPlayer = nil;
    if (!NCChatUIConfigCenter.message.isExclusiveSoundPlayer) {
        [[AVAudioSession sharedInstance]
              setActive:NO
            withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                  error:nil];
    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    }
    [self sendPlayFinishNotification];
}

- (BOOL)startPlayVoice:(NSData *)data {
    NSError *error = nil;

    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
    self.audioPlayer.delegate = self;
    self.audioPlayer.volume = 1.0;

    BOOL ready = NO;
    if (!error) {

        NCLogD(@"[NexconnChatUI]: init AudioPlayer %@", error);

        ready = [self.audioPlayer prepareToPlay];
        NCLogD(@"[NexconnChatUI]: prepare audio player %@", ready ? @"success" : @"failed");
        ready = [self.audioPlayer play];
        NCLogD(@"[NexconnChatUI]: async play is %@", ready ? @"success" : @"failed");
        if (ready) {
            [self sendPlayStartNotification];
        }
    }
    self.isPlaying = self.audioPlayer.playing;
    NCLogD(@"self.isPlaying > %d", self.isPlaying);
    NCLogD(@"[NexconnChatUI]: [audioSession category ] %@",
           [[AVAudioSession sharedInstance] category]);
    return ready;
}

- (void)stopPlayVoice {
    [self resetPlayer];
    if (!NCChatUIConfigCenter.message.isExclusiveSoundPlayer) {
        [[AVAudioSession sharedInstance]
              setActive:NO
            withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                  error:nil];
    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    }
}

- (void)resetPlayer {
    if (nil != self.audioPlayer && self.audioPlayer.playing) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;

        [self sendPlayFinishNotification];
        [self disableSystemProperties];
    }
    self.isPlaying = self.audioPlayer.playing;
    self.voicePlayerObserver = nil;
}

- (void)enableSystemProperties {
    [[UIDevice currentDevice]
        setProximityMonitoringEnabled:YES]; // Enable proximity monitoring before playback and
                                            // disable it afterward.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceProximityStateDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sensorStateChange:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}
- (void)disableSystemProperties {
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
    dispatch_after(time, dispatch_get_main_queue(), ^(void) {
      if (!self.isPlaying) {
          self.playerCategory = AVAudioSessionCategoryPlayback;
          [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
          [[NSNotificationCenter defaultCenter]
              removeObserver:self
                        name:UIDeviceProximityStateDidChangeNotification
                      object:nil];
      }
    });
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

@end
