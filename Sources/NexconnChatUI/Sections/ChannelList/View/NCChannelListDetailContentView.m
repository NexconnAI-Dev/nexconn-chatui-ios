//
//  NCChannelListDetailContentView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelListDetailContentView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCChatUIConfig.h"
#import "NCResendManager.h"
#import "NCEditInputBarConfig.h"
#import "NCChannelModel+RRS.h"
#import "NCChannelModel+Display.h"
#import "NCRRSUtil.h"

@interface NCChannelListDetailContentView ()
@property (nonatomic, strong) NSArray *constraints;
@property (nonatomic, copy) NSString *prefixName;
@end

@implementation NCChannelListDetailContentView
#pragma mark - Life Cycle
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupSemanticContentAttribute];
        [self initSubviewsLayout];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSemanticContentAttribute];
        [self initSubviewsLayout];
    }
    return self;
}

- (void)initSubviewsLayout {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:self.messageContentLabel];
    [self addSubview:self.hightlineLabel];
    [self addSubview:self.sentStatusView];

    [self addSubviewConstraint];
}

- (void)setupSemanticContentAttribute {
    BOOL isRTL = [NCChatUIUtility isRTL];
    UISemanticContentAttribute attribute = isRTL ? UISemanticContentAttributeForceRightToLeft : UISemanticContentAttributeForceLeftToRight;
    self.semanticContentAttribute = attribute;
}

- (void)updateContent:(NCChannelModel *)model prefixName:(NSString *)prefixName {
    self.prefixName = prefixName;
    [self updateContent:model];
}

/// Whether to show the read status on the leading edge.
/// - Parameter model: model
- (BOOL)shouldShowReadStatusAtLeading:(NCChannelModel *)model {
    if (model.draft.length == 0
        && model.editedMessageDraft.content.length == 0
        && [model hasLatestMessage]
        && [model lastMessageIsSend]
        && [model isChannelType:NCChannelTypeDirect]
        && [model isReadReceiptEnabledForCurrentChannelType]
        && model.latestMessageId
        && model.latestMessageId.length > 0) {
        return YES;
    }
    return NO;
}

- (void)updateContent:(NCChannelModel *)model {
    if ([self isShowDraft:model]) {
        self.sentStatusView.hidden = YES;
        self.hightlineLabel.text = NCUILocalizedString(@"draft");
        self.hightlineLabel.textColor = NCDynamicColor(@"hint_color");
    } else if ([model lastMessageIsSend] && [model lastMessageIsFailed]) {
        self.sentStatusView.hidden = NO;
        self.hightlineLabel.text = nil;
        if ([[NCResendManager sharedManager] needResend:model.latestMessageClientId]) {
            self.sentStatusView.image = NCDynamicImage(@"channel-list_cell_msg_sending_img");
        } else {
            self.sentStatusView.image = NCDynamicImage(@"channel-list_cell_msg_fail_img");
        }
    } else if ([model lastMessageIsSend] && [model lastMessageIsSending]) {
        self.sentStatusView.hidden = NO;
        self.sentStatusView.image = NCDynamicImage(@"channel-list_cell_msg_sending_img");
        self.hightlineLabel.text = nil;
    } else if (model.hasUnreadMentioned) {
        self.sentStatusView.hidden = YES;
        self.hightlineLabel.text = NCUILocalizedString(@"have_mentioned");
        self.hightlineLabel.textColor = NCDynamicColor(@"hint_color");
    } else if([self shouldShowReadStatusAtLeading:model]) { // The Lively theme shows read status on the leading edge.
        // Default unread icon.
        UIImage *image = NCDynamicImage(@"channel_msg_rrs_unread_gray_img");;
        if ([model rrs_shouldFetchConversationReadReceipt]) {
            if (model.readReceiptInfo.readCount > 0 && model.readReceiptInfo.unreadCount == 0) {
                // Read.
                image = NCDynamicImage(@"channel_msg_rrs_read_img");
            }
        }
        self.sentStatusView.hidden = NO;
        self.sentStatusView.image = image;
        self.hightlineLabel.text = nil;
    } else {
        self.sentStatusView.hidden = YES;
        self.hightlineLabel.text = nil;
    }

    NSString *messageContent = nil;
    if ([self isShowDraft:model]) {
        NSString *editedDraftContent = model.editedMessageDraft.content;
        if (editedDraftContent.length) {
            NCEditInputBarConfig *config = [[NCEditInputBarConfig alloc] initWithData:editedDraftContent];
            messageContent = config.textContent;
        } else {
            messageContent = model.draft;
        }
    } else if ([model hasLatestMessage]) {
        if (self.prefixName.length == 0 || [model lastMessageIsSend] ||
            [model.latestMessage isKindOfClass:[NCUnknownMessage class]]) {
            messageContent = [model formattedLastMessageContent];
        } else {
            messageContent = [NSString stringWithFormat:@"%@: %@", self.prefixName, [model formattedLastMessageContent]];
        }
    }
    if (messageContent == nil) {
        messageContent = @"";
    } else {
        messageContent = [self getOneLineString:messageContent];
    }
    BOOL isVoiceMessage = [model.latestMessage isKindOfClass:[NCHDVoiceMessage class]];
    NSMutableAttributedString *attibuteText = [[NSMutableAttributedString alloc] initWithString:messageContent];
    if (model.draft.length == 0 && [model hasLatestMessage] && isVoiceMessage
         &&
        ![model lastMessageIsListened] && [model lastMessageIsReceive]) {
        NSRange range;
        if (self.prefixName.length == 0 || messageContent.length == 0) {
            range = NSMakeRange(0, messageContent.length);
        } else {
            range = [messageContent rangeOfString:[model formattedLastMessageContent]];
        }
        UIColor *attributeColor = NCDynamicColor(@"hint_color");
        if (attributeColor) {
            [attibuteText addAttribute:NSForegroundColorAttributeName value:attributeColor range:range];
        }
     
    }
    self.messageContentLabel.attributedText = attibuteText;
    [self updateLayout];
}

- (void)updateLayout {
    if (self.constraints) {
        [NSLayoutConstraint deactivateConstraints:self.constraints];
    }

    NSString *layoutFormat = nil;
    if (!self.sentStatusView.hidden) {
        layoutFormat = @"H:|-0-[_sentStatusView(width)]-3.5-[_messageContentLabel]-0-|";
    } else if (self.hightlineLabel.text.length > 0) {
        layoutFormat = @"H:|-0-[_hightlineLabel(width)]-3.5-[_messageContentLabel]-0-|";
    } else {
        layoutFormat = @"H:|-0-[_messageContentLabel]-0-|";
    }

    self.constraints =
        [NSLayoutConstraint constraintsWithVisualFormat:layoutFormat
                                                options:0
                                                metrics:@{
                                                    @"width" : @([self getLeftViewWidth])
                                                }
                                                  views:NSDictionaryOfVariableBindings(_sentStatusView, _hightlineLabel,
                                                                                       _messageContentLabel)];
    [NSLayoutConstraint activateConstraints:self.constraints];
}

- (NSString *)getOneLineString:(NSString *)oldString {
    NSString *newString = [oldString stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
    newString = [newString stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    newString = [newString stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    return newString;
}

- (void)resetDefaultLayout:(NCChannelModel *)reuseModel {
    self.hightlineLabel.text = nil;
    self.messageContentLabel.attributedText = nil;
    self.sentStatusView.hidden = YES;
}

- (CGFloat)getLeftViewWidth {
    if (!self.sentStatusView.hidden) {
        // Keep the width at 16 to match sentStatusView initialization and its height constraint.
        return 16;
    } else if (self.hightlineLabel.text.length > 0) {
        CGSize size = [NCChatUIUtility getTextDrawingSize:self.hightlineLabel.text
                                                  font:self.hightlineLabel.font
                                       constrainedSize:CGSizeMake(MAXFLOAT, self.bounds.size.height)];
        return ceilf(size.width);
    } else {
        return 0;
    }
}

// Whether to show the draft.
- (BOOL)isShowDraft:(NCChannelModel *)model {
    return (model.editedMessageDraft.content.length > 0 || model.draft.length > 0) && !model.hasUnreadMentioned;
}

#pragma mark - Constraint
- (void)addSubviewConstraint {
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageContentLabel
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.hightlineLabel
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.sentStatusView
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    // sentStatusView height constraint; VFL determines its width.
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.sentStatusView
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:16]];
}

#pragma mark - Getter & Setter
- (UILabel *)messageContentLabel {
    if(!_messageContentLabel) {
        _messageContentLabel = [[UILabel alloc] init];
        _messageContentLabel.backgroundColor = [UIColor clearColor];
        _messageContentLabel.font = [[NCChatUIConfig defaultConfig].font fontOfFourthLevel];
        _messageContentLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _messageContentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _messageContentLabel;
}

- (UILabel *)hightlineLabel {
    if(!_hightlineLabel) {
        _hightlineLabel = [[UILabel alloc] init];
        _hightlineLabel.backgroundColor = [UIColor clearColor];
        _hightlineLabel.font = [[NCChatUIConfig defaultConfig].font fontOfFourthLevel];
        _hightlineLabel.textColor = NCDynamicColor(@"hint_color");
        _hightlineLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _hightlineLabel.accessibilityLabel = @"_hightlineLabel";
    }
    return _hightlineLabel;
}

- (NCBaseImageView *)sentStatusView {
    if(!_sentStatusView) {
        _sentStatusView = [[NCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _sentStatusView.translatesAutoresizingMaskIntoConstraints = NO;
        _sentStatusView.image = NCDynamicImage(@"channel-list_cell_msg_fail_img");
    }
    return _sentStatusView;
}
@end
