//
//  NCSightPlayerTransport.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol NCSightTransportDelegate <NSObject>

- (void)play;
- (void)pause;
- (void)stop;
- (void)cancel;

- (void)scrubbingDidStart;
- (void)scrubbedToTime:(NSTimeInterval)time;
- (void)scrubbingDidEnd;

- (void)jumpedToTime:(NSTimeInterval)time;

@optional
- (void)subtitleSelected:(NSString *)subtitle;
- (BOOL)prefersControlBardHidden;
- (BOOL)prefersBottomBarHidden;

@end

@protocol NCSightPlayerTransport <NSObject>

@property (weak, nonatomic) id<NCSightTransportDelegate> delegate;

/**
 Sets the thumbnail image.

 @param img Thumbnail image object.
 */
- (void)setThumbnailImage:(UIImage *)img;

/**
 Sets whether the control bar is hidden or shown.

 @param hidden YES to hide, NO to show.
 */
- (void)setControlBarHidden:(BOOL)hidden;

- (void)hideCenterPlayBtn;
- (void)startIndicatorViewAnimating;
- (void)stopIndicatorViewAnimating;
- (void)setCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration;
- (void)setScrubbingTime:(NSTimeInterval)time;

/**
 The player is ready to play.
 */
- (void)readyToPlay;

/**
 Called before playback starts.
 */
- (void)willPlay;
- (void)playbackComplete;

@end
