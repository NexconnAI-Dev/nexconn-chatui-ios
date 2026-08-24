//
//  NCSightManager.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightManager.h"
#import "NCSightPlayerController.h"
#import "NCSightViewController.h"

@implementation NCSightManager

+ (id)createSightViewControllerWithCaptureMode:(NSUInteger)mode {
    NCSightViewController *sightViewController =
        [[NCSightViewController alloc] initWithCaptureMode:mode];
    return sightViewController;
}

+ (id)createSightPlayerControllerWithURL:(NSURL *)assetURL autoPlay:(BOOL)isaut {
    NCSightPlayerController *sightPlayerController =
        [[NCSightPlayerController alloc] initWithURL:assetURL autoPlay:isaut];
    return sightPlayerController;
}

@end
