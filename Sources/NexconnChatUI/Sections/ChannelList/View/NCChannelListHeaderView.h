//
//  NCChannelListHeaderView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelModel.h"
#import "NCMessageBubbleTipView.h"
#import "NCChatUIThemeDefine.h"
#import "NCImageView.h"
#import <UIKit/UIKit.h>

@interface NCChannelListHeaderView : UIView

@property (nonatomic, strong) NCImageView *headerImageView;

@property (nonatomic, assign) NCUserAvatarStyle headerImageStyle;

@property (nonatomic, strong) NCMessageBubbleTipView *bubbleView;

@property (nonatomic, strong) UIView *backgroundView; // Backward-compatible API.

- (void)updateBubbleUnreadNumber:(int)unreadNumber;

- (void)resetDefaultLayout:(NCChannelModel *)reuseModel;

@end
