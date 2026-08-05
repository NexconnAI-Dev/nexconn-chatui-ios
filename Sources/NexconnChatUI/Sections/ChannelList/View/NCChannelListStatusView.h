//
//  NCChannelListStatusView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelModel.h"
#import <UIKit/UIKit.h>
#import "NCBaseImageView.h"
#import "NCBaseView.h"
@interface NCChannelListStatusView : NCBaseView

@property (nonatomic, strong) NCBaseImageView *conversationNotificationStatusView;

@property (nonatomic, strong) NCBaseImageView *messageReadStatusView;

@property (nonatomic, strong) NCBaseImageView *conversationPinView;

- (void)updateReadStatus:(NCChannelModel *)model;

- (void)updateNotificationStatus:(NCChannelModel *)model;

- (void)resetDefaultLayout:(NCChannelModel *)reuseModel;

- (void)updatePinStatus:(NCChannelModel *)model;
@end
