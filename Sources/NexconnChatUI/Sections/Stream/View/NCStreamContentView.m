//
//  NCStreamContentView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStreamContentView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCMessageCellTool.h"
#import "NCMessageModel+StreamCellVM.h"
#import "NCStreamMarkdownContentViewModel.h"

@interface NCStreamContentView ()

@property (nonatomic, strong) NCMessageModel *model;

@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger dotCount;

@property (nonatomic, weak) NCStreamContentViewModel *contentViewModel;

@end

@implementation NCStreamContentView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.statusLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.statusLabel.hidden) {
        self.statusLabel.frame = self.bounds;
    }
}

- (void)dealloc {
    [self invalidTimer];
}

- (void)configViewModel:(NCStreamContentViewModel *)contentViewModel {
    self.statusLabel.hidden = YES;
    [self invalidTimer];
    self.contentViewModel = contentViewModel;
}

- (void)cleanView {
    self.statusLabel.frame = CGRectZero;
    self.statusLabel.text = nil;
}

- (void)showLoading {
    [self bringSubviewToFront:self.statusLabel];
    self.statusLabel.hidden = NO;
    if (self.timer) {
        return;
    }
    // Initialize the dot counter and timer.
    self.dotCount = 1;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                  target:self
                                                selector:@selector(updateLoadingText)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)showFailed {
    [self invalidTimer];
    self.statusLabel.hidden = NO;
    [self bringSubviewToFront:self.statusLabel];
    self.statusLabel.text = [NCStreamContentViewModel failedInfo];
}

#pragma mark-- private

- (void)invalidTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)updateLoadingText {
    // Update the number of loading dots.
    NSString *dots = @"";
    for (int i = 0; i < self.dotCount; i++) {
        dots = [dots stringByAppendingString:@"."];
    }
    NSString *loading =
        [NSString stringWithFormat:@"%@%@", NCUILocalizedString(@"stream_message_typing"), dots];
    self.statusLabel.text = loading;
    // Cycle the loading dot count.
    if (self.dotCount == 3) {
        self.dotCount = 1;
    } else {
        self.dotCount++;
    }
}

#pragma mark - getter

- (UILabel *)statusLabel {
    if (!_statusLabel) {
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.numberOfLines = 0;
        [_statusLabel setFont:[[NCChatUIConfig defaultConfig].font fontOfSecondLevel]];
    }
    return _statusLabel;
}
@end
