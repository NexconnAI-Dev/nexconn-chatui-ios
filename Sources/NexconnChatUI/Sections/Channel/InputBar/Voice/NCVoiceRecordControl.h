//
//  NCVoiceRecordControl.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

@protocol NCVoiceRecordControlDelegate;
@interface NCVoiceRecordControl : NSObject

@property (nonatomic, weak) id<NCVoiceRecordControlDelegate> delegate;

- (instancetype)initWithConversationType:(NCChannelType)channelType;

- (void)onBeginRecordEvent;

- (void)onEndRecordEvent;

- (void)dragExitRecordEvent;

- (void)dragEnterRecordEvent;

- (void)onCancelRecordEvent;
@end

@protocol NCVoiceRecordControlDelegate <NSObject>

- (BOOL)recordWillBegin;
/// Starts recording a voice message.
- (void)voiceRecordControlDidBegin:(NCVoiceRecordControl *)voiceRecordControl;

/// Cancels recording a voice message.
- (void)voiceRecordControlDidCancel:(NCVoiceRecordControl *)voiceRecordControl;

/// Finishes recording a voice message.
- (void)voiceRecordControl:(NCVoiceRecordControl *)voiceRecordControl
                    didEnd:(NSData *)recordData
                  duration:(long)duration
                     error:(NSError *)error;
@end
