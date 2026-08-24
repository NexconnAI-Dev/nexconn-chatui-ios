//
//  NCSightPlayerController+ChatUI.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NCSightPlayerController_ChatUI_h
#define NCSightPlayerController_ChatUI_h
#if __has_include("NCSightPlayerController.h")
#import "NCSightPlayerController.h"
#else
@interface NCSightPlayerController : NCBaseViewController
@property (nonatomic, weak, nullable) id delegate;
@property (strong, nonatomic) NSURL *_Nullable sightURL;
@property (strong, nonatomic, nullable) UIImage *firstFrameImage;
@property (nonatomic, assign, getter=isAutoPlay) BOOL autoPlay;
- (void)setFirstFrameThumbnail:(nullable UIImage *)image;
- (void)play;
- (void)resetSightPlayer:(BOOL)inactivateAudioSession;
@end
#endif

@interface NCSightPlayerController (ChatUIInternal)
@property (nonatomic, copy, nullable) NSString *preferredDownloadFileName;
@end

#endif /* NCSightPlayerController_ChatUI_h */
