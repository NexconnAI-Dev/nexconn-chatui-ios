//
//  NCVideoPlayer.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol NCVideoPlayerDelegate <NSObject>
- (void)itemWillPlay;
- (void)itemDidPlayToEnd;
@end

@interface NCVideoPlayer : UIView

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, weak) id<NCVideoPlayerDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)play;

- (void)pause;

@end
