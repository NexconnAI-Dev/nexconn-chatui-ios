//
//  NCSightPlayerView.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightPlayerOverlay.h"
#import "NCSightPlayerTransport.h"
#import <UIKit/UIKit.h>

@interface NCSightPlayerView : UIView

- (instancetype)initWithPlayer:(AVPlayer *)player;

@property (nonatomic, readonly) id<NCSightPlayerTransport, NCSightPlayerOverlay> transport;

@property (nonatomic, strong) AVPlayer *player;

@end
