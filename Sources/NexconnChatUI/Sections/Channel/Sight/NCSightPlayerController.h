//
//  NCSightPlayerController.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NCSightPlayerControllerDelegate <NSObject>

@optional
/**
 Called when closing the video player, triggered when closeBtn in the overlay is tapped.
 */
- (void)closeSightPlayer;

/**
 Called when playback finishes.
 */
- (void)playToEnd;

@end

@protocol NCSightPlayerOverlay;

@interface NCSightPlayerController : NSObject

/**
 Initializes the video player controller.

 @param assetURL Local or remote URL of the video.
 @param isauto Whether to start playback automatically after initialization.
 @return Controller instance.
 */
- (instancetype)initWithURL:(NSURL *)assetURL autoPlay:(BOOL)isauto;

/**
 Player view.
 */
@property (strong, nonatomic, readonly) UIView *view;

/**
 Player overlay view.
 */
@property (strong, nonatomic, readonly) id<NCSightPlayerOverlay> overlay;

/**
 Player delegate.
 */
@property (weak, nonatomic) id<NCSightPlayerControllerDelegate> delegate;

/**
 Whether to loop playback. The default is NO, meaning playback does not loop.
 */
@property (assign, nonatomic) BOOL isLoopPlayback;

/**
 Local or remote URL of the video.
 @discussion If autoPlay is enabled, setting this property automatically calls the play method.
 */
@property (strong, nonatomic) NSURL *sightURL;

/**
 First-frame image.
 */
@property (strong, nonatomic, nullable) UIImage *firstFrameImage;

/**
 Whether to autoplay after the video download completes. The default is NO.
 */
@property (nonatomic, assign, getter=isAutoPlay) BOOL autoPlay;

/**
 Whether to hide the player's overlay control layer.
 */
@property (nonatomic, assign, getter=isOverlayHidden) BOOL overlayHidden;

/**
 Sets the thumbnail image displayed by the video player.

 @param image Display image.
 */
- (void)setFirstFrameThumbnail:(nullable UIImage *)image;

/**
 Starts playing a local short video, or downloads the video file locally before playback.
 */
- (void)play;

/**
 Pauses playback.
 */
- (void)pause;

/**
 Destroys resources, resets state, and stops playback. Equivalent to resetSightPlayer:YES below.

  @discussion This method does not stop the download. After the download completes, the video file is cached but not played.
  @discussion Due to an App Store review warning, the original reset method was renamed to resetSightPlayer.
 */
- (void)resetSightPlayer;

/**
 Destroys resources, resets state, and stops playback.

 @param inactivateAudioSession Sets AVAudioSession inactive.

 @discussion This method does not stop the download. After the download completes, the video file is cached but not played.
 @discussion Due to an App Store review warning, the original reset: method was renamed to resetSightPlayer:.
 */
- (void)resetSightPlayer:(BOOL)inactivateAudioSession;

- (void)setLoadingCenter:(CGPoint)center;

@end

NS_ASSUME_NONNULL_END
