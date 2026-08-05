//
//  NCChannelListStatusView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelListStatusView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChannelModel+RRS.h"
#import "NCChannelModel+Display.h"
#import "NCRRSUtil.h"

@interface NCChannelListStatusView ()
@property (nonatomic, strong) NCChannelModel *backupModel;
@property (nonatomic, strong) UIStackView *stackView;
@end

@implementation NCChannelListStatusView

#pragma mark - Life Cycle
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSubviewsLayout];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviewsLayout];
    }
    return self;
}

- (void)initSubviewsLayout {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.stackView];
    [self addSubviewConstraint];
}

- (void)updateNotificationStatus:(NCChannelModel *)model {
    self.conversationNotificationStatusView.hidden = YES;
    self.backupModel = model;
    if ([model isEqual:self.backupModel]) {
        if ([model conversationIsMuted]) {
            self.conversationNotificationStatusView.hidden = NO;
        } else {
            self.conversationNotificationStatusView.hidden = YES;
        }
    }
    [self updatePinStatus:model];
    [self updateLayout];
}

- (void)updateReadStatus:(NCChannelModel *)model {
    if (model.draft.length == 0
        && model.editedMessageDraft.content.length == 0
        && [model hasLatestMessage]
        && [model lastMessageIsSend]
        && ![model lastMessageIsSending]
        && ![model lastMessageIsFailed]
        && [model isChannelType:NCChannelTypeDirect]
        && [model isReadReceiptEnabledForCurrentChannelType]) {
        
        NSString *uid = model.latestMessageId;
        if (uid && uid.length > 0) {
            // Default unread icon.
            UIImage *image = NCDynamicImage(@"channel_msg_rrs_unread_gray_img");
            
            if ([model rrs_shouldFetchConversationReadReceipt]) {
                if (model.readReceiptInfo.readCount > 0 && model.readReceiptInfo.unreadCount == 0) {
                    // Read.
                    image = NCDynamicImage(@"channel_msg_rrs_read_img");
                }
            }
            self.messageReadStatusView.hidden = NO;
            self.messageReadStatusView.image = image;
            [self updateLayout];
        }
    }
}

- (void)updatePinStatus:(NCChannelModel *)model {
    self.conversationPinView.hidden = !model.isTop;
}

- (void)updateLayout {
    if (self.messageReadStatusView.hidden &&
        self.conversationNotificationStatusView.hidden &&
        self.conversationPinView.hidden) {
        return;
    }

    for (UIView *view in self.stackView.arrangedSubviews) {
        [self.stackView removeArrangedSubview:view];
    }
    
    if (!self.conversationNotificationStatusView.hidden) {
        [self.stackView addArrangedSubview:self.conversationNotificationStatusView];
    }
    
    if (!self.conversationPinView.hidden) {
        [self.stackView addArrangedSubview:self.conversationPinView];
    }
}

- (void)resetDefaultLayout:(NCChannelModel *)reuseModel {
    self.conversationNotificationStatusView.hidden = YES;
    self.messageReadStatusView.hidden = YES;
    self.conversationPinView.hidden = YES;
}

#pragma mark - Constraint
- (void)addSubviewConstraint {
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
        [self.stackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    ]];
}


#pragma mark - Getter & Setter
- (NCBaseImageView *)conversationNotificationStatusView {
    if(!_conversationNotificationStatusView) {
        _conversationNotificationStatusView = [[NCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _conversationNotificationStatusView.backgroundColor = [UIColor clearColor];
        _conversationNotificationStatusView.image =
        NCDynamicImage(@"channel-list_cell_block_notification_img");
        _conversationNotificationStatusView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [_conversationNotificationStatusView.widthAnchor constraintEqualToConstant:16],
            [_conversationNotificationStatusView.heightAnchor constraintEqualToConstant:16]
        ]];
    }
    return _conversationNotificationStatusView;
}

- (NCBaseImageView *)messageReadStatusView {
    if (!_messageReadStatusView) {
        _messageReadStatusView = [[NCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _messageReadStatusView.backgroundColor = [UIColor clearColor];
        _messageReadStatusView.image = NCDynamicImage(@"channel-list_cell_msg_read_img");
        _messageReadStatusView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [_messageReadStatusView.widthAnchor constraintEqualToConstant:16],
            [_messageReadStatusView.heightAnchor constraintEqualToConstant:16]
        ]];
    }
    return _messageReadStatusView;
}

- (NCBaseImageView *)conversationPinView {
    if (!_conversationPinView) {
        _conversationPinView = [[NCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _conversationPinView.backgroundColor = [UIColor clearColor];
        _conversationPinView.image = NCDynamicImage(@"channel-list_cell_pin_img");
        _conversationPinView.accessibilityLabel = @"_conversationPinView";
        _conversationPinView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [_conversationPinView.widthAnchor constraintEqualToConstant:16],
            [_conversationPinView.heightAnchor constraintEqualToConstant:16]
        ]];
    }
    return _conversationPinView;
}
- (UIStackView *)stackView {
    if (!_stackView) {
        // Use a horizontal stack view for statusView and titleLabel.
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.axis = UILayoutConstraintAxisHorizontal; // Lay out arranged views horizontally.
        stackView.alignment = UIStackViewAlignmentTrailing;
        stackView.distribution = UIStackViewDistributionEqualSpacing;
        stackView.spacing = 5;
        _stackView = stackView;
    }
    return _stackView;
}

@end
