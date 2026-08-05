//
//  NCSightManager.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCSightManager : NSObject

/**
 Initializes NCSightViewController.

 @param mode Function mode.
 @return NCSightViewController instance.
 */
+ (id)createSightViewControllerWithCaptureMode:(NSUInteger)mode;

/**
 Initializes NCSightPlayerController.

 @param assetURL Local or remote URL of the video.
 @param isauto Whether to start playback automatically after initialization.
 @return SightPlayerController instance.
 */
+ (id)createSightPlayerControllerWithURL:(NSURL *)assetURL autoPlay:(BOOL)isauto;

@end

NS_ASSUME_NONNULL_END
