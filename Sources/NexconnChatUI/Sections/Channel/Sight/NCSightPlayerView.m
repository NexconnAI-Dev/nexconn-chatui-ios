//
//  NCSightPlayerView.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightPlayerView.h"
#import "NCSightPlayerOverlayView.h"
#import "NCSightAdaptiveHeader.h"

@interface NCSightPlayerView ()
@property (strong, nonatomic) NCSightPlayerOverlayView *overlayView;
@end

@implementation NCSightPlayerView
#pragma mark - Properties
- (NCSightPlayerOverlayView *)overlayView {
    if (!_overlayView) {
        _overlayView = [[NCSightPlayerOverlayView alloc] init];
    }
    return _overlayView;
}

#pragma mark - override
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

#pragma mark - api

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.overlayView];
    }
    return self;
}

- (instancetype)initWithPlayer:(AVPlayer *)player {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

        [(AVPlayerLayer *)[self layer] setPlayer:player];

        [self addSubview:self.overlayView];
    }
    return self;
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.overlayView.frame = self.bounds;
}

- (id<NCSightPlayerTransport, NCSightPlayerOverlay>)transport {
    return self.overlayView;
}

- (void)dealloc {
}

@end
