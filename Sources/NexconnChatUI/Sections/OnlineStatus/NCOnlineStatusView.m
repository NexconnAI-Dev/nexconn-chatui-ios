//
//  NCOnlineStatusView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCOnlineStatusView.h"
#import "NCChatUICommonDefine.h"

/// Online status indicator size.
static const CGFloat kOnlineStatusSize = 6.0;

@implementation NCOnlineStatusView

- (void)setupView {
    [super setupView];
    // Make the indicator circular.
    self.layer.cornerRadius = kOnlineStatusSize / 2.0;
    self.layer.masksToBounds = YES;
    
    self.frame = CGRectMake(0, 0, kOnlineStatusSize, kOnlineStatusSize);
    
    // Hidden by default.
    self.hidden = YES;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(kOnlineStatusSize, kOnlineStatusSize);
}

#pragma mark - Public Methods

- (void)setOnline:(BOOL)isOnline {
    _online = isOnline;
    if (self.hidden) {
        return;
    }
    if (isOnline) {
        // Online: green dot.
        self.backgroundColor = NCDynamicColor(@"success_color");
    } else {
        // Offline: gray dot.
        self.backgroundColor = NCDynamicColor(@"disabled_color");
    }
}

- (void)reset {
    self.hidden = YES;
    self.backgroundColor = nil;
}

@end
