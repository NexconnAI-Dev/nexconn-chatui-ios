//
//  NCSightCapturer.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

/**
 Output delegate for audio and video samples captured by the capturer.
 */
@protocol NCSightCapturerOutputDelegate <NSObject>

@required

/**
 Called when an audio or video sample is output.

 @param sampleBuffer Audio or video sample.
 */
- (void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@optional

/**
 Called when focusing completes.

 @param point Focus center point.
 */
- (void)focusDidfinish:(CGPoint)point;

@end

/**
 Video, audio, and image capturer.
 */
@interface NCSightCapturer : NSObject

- (instancetype)initWithVideoPreviewPlayer:(AVCaptureVideoPreviewLayer *)layer;

/**
 Capture preview layer.
 */
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;

/**
 Output delegate for video frames and audio samples. These data are usually passed to SightRecorder.
 */
@property (nonatomic, weak) id<NCSightCapturerOutputDelegate> delegate;

/**
 Audio and video sample output queue.
 */
@property (nonatomic, strong, readonly) dispatch_queue_t sessionQueue;

/**
 Video compression settings recommended by the capturer.
 */
@property (nonatomic, copy, readonly) NSDictionary *recommendedVideoCompressionSettings;

/**
 Audio compression settings recommended by the capturer.
 */
@property (nonatomic, copy, readonly) NSDictionary *recommendedAudioCompressionSettings;

/**
 Starts capturing.
 */
- (void)startRunning;

/**
 Stops capturing.
 */
- (void)stopRunning;

/**
 Switches the camera.

 @return YES on success, NO on failure.
 */
- (BOOL)switchCamera;

/**
 Focuses at the specified point.

 @param point Coordinate.
 */
- (void)focusAtPoint:(CGPoint)point;

/**
 Whether focus is supported.

 @return YES if supported; otherwise NO.
 */
- (BOOL)cameraSupportsTapToFocus;

/**
  Captures a still image.

 @param orientation Capture orientation.
 @param completion Callback block for the captured image.
 */
- (void)captureStillImage:(AVCaptureVideoOrientation)orientation completion:(void (^)(UIImage *image))completion;

- (BOOL)resetSessionInput;
- (void)resetAudioSession;
@end
