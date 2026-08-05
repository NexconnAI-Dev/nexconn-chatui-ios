//
//  NCSightViewController.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCSightAdaptiveHeader.h"
NS_ASSUME_NONNULL_BEGIN

@class NCSightViewController;
@protocol NCSightViewControllerDelegate;

typedef NS_ENUM(NSInteger, NCSightViewControllerCameraCaptureMode) {
    NCSightViewControllerCameraCaptureModeSight, /// Record short videos or take photos. This is the default mode.
    NCSightViewControllerCameraCaptureModePhoto  // Take photos only.
};

/**
 Video preview view controller.
 */
@interface NCSightViewController : NCBaseViewController

- (instancetype)initWithCaptureMode:(NCSightViewControllerCameraCaptureMode)mode;

/**
 Video preview view controller delegate.
 */
@property (nonatomic, weak, nullable) id<NCSightViewControllerDelegate> delegate;

@end

@protocol NCSightViewControllerDelegate <NSObject>

/**
 Called when the user chooses to send a captured still image.

 @param sightVC Video preview view controller instance.
 @param image Still image object.
 */
- (void)sightViewController:(NCSightViewController *)sightVC didFinishCapturingStillImage:(UIImage *)image;

/**
 Called when the user chooses to send a recorded short video.

 @param sightVC Video preview view controller instance.
 @param url Storage URL of the current short video.
 @param thumnail Image object for the first frame of the short video.
 @param duration Duration of the short video, in seconds.
 */
- (void)sightViewController:(NCSightViewController *)sightVC
         didWriteSightAtURL:(NSURL *)url
                  thumbnail:(UIImage *)thumnail
                   duration:(NSUInteger)duration;

@optional
/// Callback when short video recording fails.
/// @param sightVC Video preview view controller instance.
/// @param error Failure description.
/// @param status AVAssetWriter status.
- (void)sightViewController:(NCSightViewController *)sightVC
         didWriteFailedWith:(NSError *)error
                  status:(NSInteger)status;
@end

NS_ASSUME_NONNULL_END
