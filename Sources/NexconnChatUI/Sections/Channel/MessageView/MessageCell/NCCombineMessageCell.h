//
//  NCCombineMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"
#import "NexconnChatUI.h"
NS_ASSUME_NONNULL_BEGIN

@interface NCCombineMessageCell : NCMessageCell

/// The message background view.
@property (nonatomic, strong) NCBaseView *backView;

/// The label that displays the message title.
@property (nonatomic, strong) NCBaseLabel *titleLabel;

/// The label that displays the message preview content.
@property (nonatomic, strong) NCBaseLabel *contentLabel;

/// The label that displays the chat history text.
@property (nonatomic, strong) NCBaseLabel *historyLabel;

@end

NS_ASSUME_NONNULL_END
