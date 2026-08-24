//
//  NCContentView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCContentView.h"
@interface NCContentView ()
/*!
 Callback invoked when the frame changes.
 */
@property (nonatomic, copy) void (^eventBlock)(CGRect frame);

/*!
 Callback invoked when the size changes.
 */
@property (nonatomic, copy) void (^changeSizeBlock)(CGSize size);
@end
@implementation NCContentView

- (id)init {
    self = [super init];
    if (self) {
        _eventBlock = NULL;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.contentSize = frame.size;
    if (_eventBlock) {
        _eventBlock(frame);
    }
}

- (void)registerFrameChangedEvent:(void (^)(CGRect frame))eventBlock {
    self.eventBlock = eventBlock;
}

- (void)registerSizeChangedEvent:(void (^)(CGSize size))eventBlock {
    self.changeSizeBlock = eventBlock;
}

- (void)setContentSize:(CGSize)contentSize {
    CGSize beforeSize = self.contentSize;
    _contentSize = contentSize;
    if (beforeSize.width != contentSize.width || beforeSize.height != contentSize.height) {
        if (_changeSizeBlock) {
            _changeSizeBlock(contentSize);
        }
    }
}
@end
