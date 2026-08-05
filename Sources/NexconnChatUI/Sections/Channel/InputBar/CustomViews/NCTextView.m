//
//  NCTextView.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCTextView.h"

@implementation NCTextView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _disableActionMenu = NO;
    }
    return self;
}
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (self.disableActionMenu) {
        return NO;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    _disableActionMenu = NO;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    if (self.textChangeDelegate && [self.textChangeDelegate respondsToSelector:@selector(nctextView:textDidChange:)]) {
        [self.textChangeDelegate nctextView:self textDidChange:text];
    }
}
@end
