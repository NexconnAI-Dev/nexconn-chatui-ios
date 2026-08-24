//
//  NCChannelListDetailContentView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseImageView.h"
#import "NCChannelModel.h"
#import <UIKit/UIKit.h>
@interface NCChannelListDetailContentView : UIView

@property (nonatomic, strong) UILabel *hightlineLabel;

@property (nonatomic, strong) NCBaseImageView *sentStatusView;

@property (nonatomic, strong) UILabel *messageContentLabel;

- (void)updateContent:(NCChannelModel *)model;

- (void)updateContent:(NCChannelModel *)model prefixName:(NSString *)prefixName;

- (void)resetDefaultLayout:(NCChannelModel *)reuseModel;

- (void)updateLayout;
@end
