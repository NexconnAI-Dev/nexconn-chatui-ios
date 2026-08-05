//
//  NCGroupNoticeView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"
#import "NCPlaceholderTextView.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCGroupNoticeView : NCBaseView

@property (nonatomic, strong) NCPlaceholderTextView *textView;

@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIImageView *emptyImageView;

- (void)updateTextViewHeight:(BOOL)canEdit;
- (void)showEmptylabel:(BOOL)show;
@end

NS_ASSUME_NONNULL_END
