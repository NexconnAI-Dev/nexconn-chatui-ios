//
//  NCStreamTextContentView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStreamTextContentView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCMessageCellTool.h"
#import "NCStreamTextContentViewModel.h"
@interface NCStreamTextContentView ()

@property (nonatomic, strong) UITextView *textView;

@end

@implementation NCStreamTextContentView
- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.textView];
    }
    return self;
}

- (void)configViewModel:(NCStreamContentViewModel *)contentViewModel {
    [super configViewModel:contentViewModel];
    if (![contentViewModel isKindOfClass:NCStreamTextContentViewModel.class]) {
        return;
    }
    NCStreamTextContentViewModel *viewModel = (NCStreamTextContentViewModel *)contentViewModel;
    self.textView.attributedText = viewModel.attributedContent;
    self.textView.frame =
        CGRectMake(0, 0, viewModel.contentSize.width, viewModel.contentSize.height);
}

- (void)cleanView {
    [super cleanView];
    self.textView.frame = CGRectZero;
    self.textView.attributedText = nil;
}

#pragma mark-- getter

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.editable = NO;
        _textView.scrollEnabled = NO;
        _textView.textContainerInset = UIEdgeInsetsZero;
        _textView.textContainer.lineFragmentPadding = 0;
        [_textView setFont:[[NCChatUIConfig defaultConfig].font fontOfSecondLevel]];
        _textView.userInteractionEnabled = NO;
    }
    return _textView;
}
@end
