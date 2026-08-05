//
//  NCVideoPlayer.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCVideoPlayer.h"
#import "NCChatUICommonDefine.h"

@interface NCVideoPlayer ()

@property (nonatomic, weak) AVPlayer *player;

@end

@implementation NCVideoPlayer

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
        AVPlayerLayer *layer = (AVPlayerLayer *)self.layer;
        layer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
    return self;
}

#pragma mark - Super Methods
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

#pragma mark - Public Methods
- (void)play {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                         context:nil];

    [self.player play];
}

- (void)pause {
    [self.player pause];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (![keyPath isEqualToString:@"status"]) {
        return;
    }
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        [self.delegate itemWillPlay];
    }
}

#pragma mark - Notification Selector
- (void)playToEnd:(NSNotification *)notification {
    if (notification.object == self.playerItem) {
        [self.delegate itemDidPlayToEnd];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

#pragma mark - Getters and Setters
- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    _playerItem = playerItem;
    AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    [(AVPlayerLayer *)[self layer] setPlayer:player];
    self.player = player;
}
@end
