//
//  NCSightRecorder.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@protocol NCSightRecorderDelegate;

/**
 Video recorder responsible for generating video files.
 */
@interface NCSightRecorder : NSObject

/**
 Initializes the recorder.

 @param videoSettings Video settings.
 @param audioSettings Audio settings.
 @param dispatchQueue Queue.
 @return Recorder object.
 */
- (instancetype)initWithVideoSettings:(NSDictionary *)videoSettings
                        audioSettings:(NSDictionary *)audioSettings
                        dispatchQueue:(dispatch_queue_t)dispatchQueue;

/**
 Recorder delegate.
 */
@property (nonatomic, readwrite, weak) id<NCSightRecorderDelegate> delegate;

/**
  Prepares to record.

 @param orientation Recording orientation.
 */
- (void)prepareToRecord:(AVCaptureVideoOrientation)orientation;

/**
 Processes media samples (video frames and audio samples) in the recorder.

 @param sampleBuffer Unencoded video sample.
 */
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 Finishes recording.

 @discussion Called asynchronously. sightRecorderDidFinishRecording is called on completion, and sightRecorder:didFailWithError: is called on failure.
 */
- (void)finishRecording;

@end

@protocol NCSightRecorderDelegate <NSObject>
@required
/**
 Called when video recording completes.

 @param recorder Recorder instance.
 @param outputURL File storage path.
 */
- (void)sightRecorder:(NCSightRecorder *)recorder didWriteMovieAtURL:(NSURL *)outputURL;

/**
 Called when recording fails or an error occurs.

 @param recorder Recorder instance.
 @param error Error description.
 @param status AVAssetWriter status.
 */
- (void)sightRecorder:(NCSightRecorder *)recorder
     didFailWithError:(NSError *)error
               status:(NSInteger)status;

@end
