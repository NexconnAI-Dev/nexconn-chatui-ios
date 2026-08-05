//
//  NCSightCollectionViewCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightCollectionViewCell.h"
#import "NexconnChatUI.h"
#import "NCSightPlayerController+ChatUI.h"
#import "NCSightModel.h"
#import "NCSightModel+internal.h"
#import "NCBaseImageView.h"

@interface NCSightCollectionViewCell ()

@property (nonatomic, strong) NCBaseImageView *thumbnailView;

@property (nonatomic, strong) UIButton *playBtn;

@property (nonatomic, strong) NCSightPlayerController *playerController;

@property (nonatomic, strong) NCSightModel *messageModel;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

@end

@implementation NCSightCollectionViewCell
#pragma mark - Life Cycle

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.playerController resetSightPlayer:NO];
    [self removeCurrentPlayerView];
    self.playerController.delegate = nil;
    self.playerController = nil;
    self.messageModel = nil;
    self.autoPlay = NO;
}

#pragma mark - Public Methods
- (void)setDataModel:(NCSightModel *)model {
    if (self.playerController != model.playerController) {
        [self.playerController resetSightPlayer:NO];
    }
    [self removeCurrentPlayerView];
    self.messageModel = model;
    self.playerController = model.playerController;
    if (self.playerController) {
        self.playerController.delegate = self;
        self.playerController.autoPlay = YES;
        [self.contentView addSubview:self.playerController.view];
        [self strechToSuperview:self.playerController.view];
        self.longPressGestureRecognizer =
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
        [self.playerController.view addGestureRecognizer:self.longPressGestureRecognizer];
    }
    self.label.text = [NSString stringWithFormat:@"%ld", model.messageModel.clientId];
}

- (void)stopPlay {
    if (self.playerController) {
        [self.playerController resetSightPlayer:YES];
    }
}

- (void)resetPlay {
    if (self.playerController) {
        [self.playerController resetSightPlayer:NO];
    }
}

#pragma mark - constraint helpers
- (void)strechToSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *formats = @[ @"H:|[view]|", @"V:|[view]|" ];
    for (NSString *each in formats) {
        NSArray *constraints =
            [NSLayoutConstraint constraintsWithVisualFormat:each options:0 metrics:nil views:@{
                @"view" : view
            }];
        [view.superview addConstraints:constraints];
    }
}

- (void)constraintCenterInSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *constraintY = [NSLayoutConstraint constraintWithItem:view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:view.superview
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0f
                                                                    constant:0];
    [view.superview addConstraint:constraintY];

    NSLayoutConstraint *constraintX = [NSLayoutConstraint constraintWithItem:view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:view.superview
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0f
                                                                    constant:0];

    [view.superview addConstraint:constraintX];
}

- (void)constrainView:(UIView *)view toSize:(CGSize)size {

    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *formats = @[ @"H:[view(==width)]", @"V:[view(==height)]" ];

    for (NSString *each in formats) {
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:each
                                                                       options:0
                                                                       metrics:@{
                                                                           @"width" : @(size.width),
                                                                           @"height" : @(size.height)
                                                                       }
                                                                         views:@{
                                                                             @"view" : view
                                                                         }];
        [view addConstraints:constraints];
    }
}

#pragma mark - Private Methods
- (void)removeCurrentPlayerView {
    if (self.longPressGestureRecognizer) {
        [self.playerController.view removeGestureRecognizer:self.longPressGestureRecognizer];
        self.longPressGestureRecognizer = nil;
    }
    [self.playerController.view removeFromSuperview];
}

- (void)setAutoPlay:(BOOL)autoPlay {
    _autoPlay = autoPlay;
    if (_autoPlay) {
        [self.playerController play];
    }
}

- (void)closeSightPlayer {
    [self.delegate closeSight];
}

- (void)playToEnd {
    if ([self.delegate respondsToSelector:@selector(playEnd)]) {
        [self.delegate performSelector:@selector(playEnd) withObject:nil];
    }
}

- (void)longPressed:(id)sender {
    NCShortVideoMessage *sightMessage = (NCShortVideoMessage *)self.messageModel.messageModel.content;
    NSString *localPath = nil;
    if (sightMessage.localPath && [[NSFileManager defaultManager] fileExistsAtPath:sightMessage.localPath]) {
        localPath = sightMessage.localPath;
    } else if (self.playerController.sightURL.isFileURL &&
               [[NSFileManager defaultManager] fileExistsAtPath:self.playerController.sightURL.path]) {
        localPath = self.playerController.sightURL.path;
    } else {
        NCLogD(@"LocalPath and sightUrl are nil");
    }

    if (localPath && [[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
        if (press.state == UIGestureRecognizerStateEnded) {
            return;
        } else if (press.state == UIGestureRecognizerStateBegan) {
            if ([self.delegate respondsToSelector:@selector(sightLongPressed:)]) {
                [self.delegate performSelector:@selector(sightLongPressed:) withObject:localPath];
            }
        }
    }
}

@end
