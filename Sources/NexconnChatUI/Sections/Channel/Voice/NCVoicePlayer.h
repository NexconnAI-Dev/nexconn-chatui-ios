//
//  NCVoicePlayer.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageModel.h"
#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>

/// Notification posted when voice message playback stops.
UIKIT_EXTERN NSString *const kNotificationVoiceWillPlayNotification;
UIKIT_EXTERN NSString *const kNotificationStopVoicePlayer;
UIKIT_EXTERN NSString *const kNotificationPlayVoice;
UIKIT_EXTERN NSString *const kNCContinuousPlayNotification;

@protocol NCVoicePlayerObserver;
@interface NCVoicePlayer : NSObject

@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, assign) long messageClientId;
@property (nonatomic, assign) NCChannelType channelType;
@property (nonatomic, copy) NSString *channelId;

+ (NCVoicePlayer *)defaultPlayer;

- (void)playAudio:(NCMessageModel *)model;

//- (BOOL)playVoice:(NSString *)clientId voiceData:(NSData *)data
// observer:(id<NCVoicePlayerObserver>)observer;
- (BOOL)playVoice:(NCChannelType)channelType
          channelId:(NSString *)channelId
    messageClientId:(long)messageClientId
          voiceData:(NSData *)data
           observer:(id<NCVoicePlayerObserver>)observer;

- (void)stopPlayVoice;

- (void)resetPlayer;

@end

@protocol NCVoicePlayerObserver <NSObject>

- (void)PlayerDidFinishPlaying:(BOOL)isFinish;

- (void)audioPlayerDecodeErrorDidOccur:(NSError *)error;

@end
