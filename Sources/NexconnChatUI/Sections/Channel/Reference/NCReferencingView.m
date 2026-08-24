//
//  NCReferencingView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCReferencingView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUserInfo.h"
#import "NCChatUIUtility.h"
#import "NCInfoUpdateCenter.h"
#import "NCMessageSenderInfo.h"
#import "NCStreamUtilities.h"
@interface NCReferencingView () <NCInfoUpdateDelegate>
@property (nonatomic, strong) UIView *inView;
@end

#define textlabel_left_space 12
#define textlabel_and_dismiss_space 8
#define dismiss_right_space 12
#define dismiss_width 16

@implementation NCReferencingView
- (instancetype)initWithModel:(NCMessageModel *)model inView:(UIView *)view {
    if (self = [super init]) {
        self.backgroundColor = NCDynamicColor(@"common_background_color");
        self.inView = view;
        self.referModel = model;
        [self addNotification];
        [self setContentInfo];
        [self setupSubviews];
    }
    return self;
}

- (void)dealloc {
    [NCInfoUpdateCenter removeInfoUpdateDelegate:self];
}

- (void)setOffsetY:(CGFloat)offsetY {
    [UIView animateWithDuration:0.25
                     animations:^{
                       CGRect rect = self.frame;
                       rect.origin.y = offsetY;
                       self.frame = rect;
                     }];
}

#pragma mark - Private Methods

- (void)setupSubviews {
    self.frame = CGRectMake(0, self.inView.frame.size.height, self.inView.frame.size.width, 60);
    if ([NCChatUIUtility isRTL]) {
        self.dismissButton.frame =
            CGRectMake(dismiss_right_space, (self.frame.size.height - dismiss_width) / 2,
                       dismiss_width, dismiss_width);
        self.nameLabel.frame =
            CGRectMake(textlabel_left_space, 10,
                       self.frame.size.width - self.dismissButton.frame.origin.x -
                           textlabel_left_space - textlabel_and_dismiss_space,
                       20);
        self.textLabel.frame =
            CGRectMake(textlabel_left_space, CGRectGetMaxY(self.nameLabel.frame),
                       self.frame.size.width - self.dismissButton.frame.origin.x -
                           textlabel_left_space - textlabel_and_dismiss_space,
                       20);
    } else {
        self.dismissButton.frame =
            CGRectMake(self.frame.size.width - dismiss_width - dismiss_right_space, 10,
                       dismiss_width, dismiss_width);
        self.nameLabel.frame = CGRectMake(textlabel_left_space, 10,
                                          self.dismissButton.frame.origin.x - textlabel_left_space -
                                              textlabel_and_dismiss_space,
                                          20);
        self.textLabel.frame = CGRectMake(textlabel_left_space, CGRectGetMaxY(self.nameLabel.frame),
                                          self.dismissButton.frame.origin.x - textlabel_left_space -
                                              textlabel_and_dismiss_space,
                                          20);
    }
    [self addSubview:self.dismissButton];
    [self addSubview:self.nameLabel];
    [self addSubview:self.textLabel];
}

- (void)setContentInfo {
    NSString *messageInfo;
    if ([self.referModel.content isKindOfClass:[NCFileMessage class]]) {
        NCFileMessage *msg = (NCFileMessage *)self.referModel.content;
        messageInfo =
            [NSString stringWithFormat:@"%@ %@", NCUILocalizedString(@"file_message"), msg.name];
    } else if ([self.referModel.content isKindOfClass:[NCTextMessage class]] ||
               [self.referModel.content isKindOfClass:[NCReferenceMessage class]]) {
        messageInfo = [NCChatUIUtility formatMessage:self.referModel.content
                                           channelId:self.referModel.channelId
                                         channelType:self.referModel.channelType
                                        isAllMessage:YES];
    } else if ([self.referModel.content isKindOfClass:[NCStreamMessage class]]) {
        NCStreamMessage *msg = (NCStreamMessage *)self.referModel.content;
        if (msg.sync) {
            messageInfo = msg.content;
        } else {
            NCStreamSummaryModel *summary = [NCStreamUtilities parserStreamSummary:self.referModel];
            if (summary.isComplete) {
                messageInfo = summary.summary;
                msg.content = summary.summary;
            }
        }
    } else if ([self.referModel.content isKindOfClass:[NCMessageContent class]]) {
        messageInfo = [NCChatUIUtility formatMessage:self.referModel.content
                                           channelId:self.referModel.channelId
                                         channelType:self.referModel.channelType
                                        isAllMessage:YES];
        if (messageInfo <= 0 || [messageInfo isEqualToString:self.referModel.objectName]) {
            messageInfo = NCUILocalizedString(@"unknown_message_cell_tip");
        }
    }
    NSString *separator = NCUILocalizedString(@"message_sender_separator");
    if ([NCChatUIUtility isRTL]) {
        self.nameLabel.text =
            [NSString stringWithFormat:@"%@%@", separator, [self getUserDisplayName]];
    } else {
        self.nameLabel.text =
            [NSString stringWithFormat:@"%@%@", [self getUserDisplayName], separator];
    }

    // Replace line breaks with spaces.
    messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
    messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    self.textLabel.text = [NSString stringWithFormat:@"%@", messageInfo];
}

- (void)didClickDismissButton:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissReferencingView:)]) {
        [self.delegate dismissReferencingView:self];
    }
}

- (NSString *)getUserDisplayName {
    NCMessageSenderInfo *senderInfo = [self senderInfoForReferencingModel];
    self.referModel.userInfo = senderInfo.userInfo;
    return senderInfo.name;
}

- (NCMessageSenderInfo *)senderInfoForReferencingModel {
    NCChatUIUserInfo *userInfo = [NCMessageSenderUserInfoResolver
        userInfoForChannelType:self.referModel.channelType
                     channelId:self.referModel.channelId
                  senderUserId:self.referModel.senderUserId
                senderUserInfo:self.referModel.content.senderUserInfo];
    return [NCMessageSenderInfo infoWithUserInfo:userInfo];
}

- (void)addNotification {
    [NCInfoUpdateCenter addInfoUpdateDelegate:self];
}

- (void)didTapContentView:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTapReferencingView:)]) {
        [self.delegate didTapReferencingView:self.referModel];
    }
}

#pragma mark - UserInfo Update
- (void)onUserInfoUpdate:(NCChatUIUserInfo *)userInfo {
    if ([self.referModel.senderUserId isEqualToString:userInfo.userId]) {
        // Reload the merged user information.
        [self setContentInfo];
    }
}

- (void)onGroupMemberInfoUpdate:(NCChatUIUserInfo *)userInfo groupId:(NSString *)groupId {
    if (self.referModel.channelType == NCChannelTypeGroup) {
        if ([self.referModel.channelId isEqualToString:groupId] &&
            [self.referModel.senderUserId isEqualToString:userInfo.userId]) {
            // Reload the merged user information.
            [self setContentInfo];
        }
    }
}

#pragma mark - Getters and Setters
- (NCBaseButton *)dismissButton {
    if (!_dismissButton) {
        _dismissButton = [NCBaseButton buttonWithType:UIButtonTypeCustom];
        [_dismissButton setImage:NCDynamicImage(@"channel_msg_referencing_dismiss_img")
                        forState:UIControlStateNormal];
        [_dismissButton addTarget:self
                           action:@selector(didClickDismissButton:)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissButton;
}

- (NCBaseLabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[NCBaseLabel alloc] init];
        _nameLabel.textColor = NCDynamicColor(@"text_primary_color");
        _nameLabel.font = [[NCChatUIConfig defaultConfig].font fontOfGuideLevel];
    }
    return _nameLabel;
}

- (NCBaseLabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[NCBaseLabel alloc] init];
        _textLabel.numberOfLines = 1;
        [_textLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        _textLabel.font = [[NCChatUIConfig defaultConfig].font fontOfGuideLevel];
        _textLabel.textColor = NCDynamicColor(@"text_primary_color");
        UITapGestureRecognizer *messageTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(didTapContentView:)];
        messageTap.numberOfTapsRequired = 1;
        messageTap.numberOfTouchesRequired = 1;
        [_textLabel addGestureRecognizer:messageTap];
    }
    return _textLabel;
}
@end
