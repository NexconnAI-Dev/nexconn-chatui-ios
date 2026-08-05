//
//  NCSizeCalculateLabel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSizeCalculateLabel.h"

@implementation NCSizeCalculateLabel
- (void)layoutSubviews {
    [super layoutSubviews];
    if ([self.delegate respondsToSelector:@selector(labelLayoutFinished:natureSize:)]) {
        CGSize size = [self sizeThatFits:CGSizeMake(self.bounds.size.width, 1000)];
        [self.delegate labelLayoutFinished:self natureSize:size];
    }
}
@end
