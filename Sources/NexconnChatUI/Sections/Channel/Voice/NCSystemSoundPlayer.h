//
//  NCSystemSoundPlayer.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

@class NCMessage;

typedef void (^NCSystemSoundPlayerCompletion)(BOOL complete);

@interface NCSystemSoundPlayer : NSObject

+ (NCSystemSoundPlayer *)defaultPlayer;

- (void)setSystemSoundPath:(NSString *)path;

- (void)playSoundByMessage:(NCMessage *)message
             completeBlock:(NCSystemSoundPlayerCompletion)completion;

/// Sets the channel whose ringing should be ignored.
- (void)setIgnoreChannelType:(NCChannelType)channelType channelId:(NSString *)channelId;

/// Clears the channel whose ringing should be ignored.
- (void)resetIgnoreConversation;

@end
