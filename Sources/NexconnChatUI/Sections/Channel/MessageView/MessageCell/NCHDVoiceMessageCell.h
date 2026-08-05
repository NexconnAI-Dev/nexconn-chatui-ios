//
//  NCHDVoiceMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NexconnChatUI.h"

/// Voice message cell
@interface NCHDVoiceMessageCell : NCMessageCell

/// View for voice playback
@property (nonatomic, strong) NCBaseImageView *playVoiceView;

/// View indicating whether the voice has been played
@property (nonatomic, strong) NCBaseImageView *voiceUnreadTagView;

/// Label displaying the voice duration
@property (nonatomic, strong) UILabel *voiceDurationLabel;

/// Play the voice message
- (void)playVoice;

/// Stop playing the voice message
- (void)stopPlayingVoice;

@end
