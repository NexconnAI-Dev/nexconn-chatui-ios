//
//  NCPlaceholderTextView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPlaceholderTextView.h"
#import "NCChatUICommonDefine.h"

@interface NCPlaceholderTextView ()

@property (nonatomic, strong) UILabel *placeholderLabel;

@end

@implementation NCPlaceholderTextView
/*
 Position the placeholder from the text view's current caret origin. This keeps
 it aligned with the effective LTR or RTL text layout even when the app-wide
 interface direction has not updated after a language change.
 */
- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.placeholderLabel];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePlaceholder) name:UITextViewTextDidChangeNotification object:self];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self updatePlaceholder];
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    self.placeholderLabel.font = font;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.placeholderLabel.hidden && self.placeholderLabel.text.length > 0) {
        CGRect caretRect = [self caretRectForPosition:self.selectedTextRange.start];
        CGPoint cursorPosition = [self convertPoint:caretRect.origin toView:self];
        CGFloat newX = cursorPosition.x; // Align the placeholder with the caret origin.
        CGFloat newWidth = self.frame.size.width - newX * 2;
        CGRect rect = CGRectMake(newX, 8, newWidth, 0);
        self.placeholderLabel.frame = rect;
        [self.placeholderLabel sizeToFit];
    }
}

- (void)setPlaceholder:(NSString *)placeholder {
    self.placeholderLabel.text = placeholder;
    [self.placeholderLabel sizeToFit];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (NSString *)placeholder {
    return self.placeholderLabel.text;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    self.placeholderLabel.textColor = placeholderColor;
}

- (UIColor *)placeholderColor {
    return self.placeholderLabel.textColor;
}

- (UILabel *)placeholderLabel {
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc] init];
        _placeholderLabel.numberOfLines = 0;
        _placeholderLabel.textColor = NCDynamicColor(@"text_secondary_color");
    }
    return _placeholderLabel;
}

- (void)updatePlaceholder {
    self.placeholderLabel.hidden = self.text.length > 0;
    if (!self.placeholderLabel.hidden) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}


@end
