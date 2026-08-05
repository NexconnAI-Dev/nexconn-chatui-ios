//
//  NCChannelListBaseCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelListBaseCell.h"

@implementation NCChannelListBaseCell

- (void)setDataModel:(NCChannelModel *)model {
    self.model = model;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
