//
//  NCReferencedContentView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCReferencedContentView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUserInfo.h"
#import "NCChatUIUtility.h"
#import "NCInfoUpdateCenter.h"
#import "NCMessageCellTool.h"
#import "NCMessageEditUtil.h"
#import "NCMessageSenderInfo.h"
#define leftLine_width 2
#define name_and_leftLine_space 4
#define name_height 17
@interface NCReferencedContentView () <NCInfoUpdateDelegate>
@property (nonatomic, strong) NCMessageModel *referModel;
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NCMessageContent *referedContent;
@property (nonatomic, copy) NSString *referedSenderId;
@property (nonatomic, assign) NCReferenceMessageStatus referMsgStatus;
@end

@implementation NCReferencedContentView
- (instancetype)init {
    if (self = [super init]) {
        self.frame = CGRectZero;
    }
    return self;
}

- (void)dealloc {
    [NCInfoUpdateCenter removeInfoUpdateDelegate:self];
}

- (void)setMessage:(NCMessageModel *)message contentSize:(CGSize)contentSize {
    [self resetReferencedContentView];
    self.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);
    self.referModel = message;
    self.contentSize = contentSize;
    if (![self fetchReferedContentInfo]) {
        return;
    }
    [self addNotification];
    [self setUserDisplayName];
    [self setContentInfo];
    [self setupSubviews];
}

#pragma mark - Private Methods
- (BOOL)fetchReferedContentInfo {
    if ([self.referModel.content isKindOfClass:[NCReferenceMessage class]]) {
        NCReferenceMessage *content = (NCReferenceMessage *)self.referModel.content;
        self.referedContent = content.referMsg;
        self.referedSenderId = content.referMsgSenderId;
        self.referMsgStatus = content.referMsgStatus;
        return YES;
    } else if ([self.referModel.content isKindOfClass:[NCStreamMessage class]]) {
        NCStreamMessage *content = (NCStreamMessage *)self.referModel.content;
        self.referedContent = content.referenceInfo.content;
        self.referedSenderId = content.referenceInfo.senderUserId;
        self.referMsgStatus = NCReferenceMessageStatusDefault;
        return YES;
    }
    return NO;
}

- (void)setContentInfo {
    if (self.referMsgStatus == NCReferenceMessageStatusDeleted) {
        self.textLabel.text = NCUILocalizedString(@"referenced_message_deleted");
    } else if (self.referMsgStatus == NCReferenceMessageStatusRecalled) {
        self.textLabel.text = NCUILocalizedString(@"referenced_message_recalled");
    }
    if (self.referMsgStatus == NCReferenceMessageStatusDeleted ||
        self.referMsgStatus == NCReferenceMessageStatusRecalled) {
        self.textLabel.textColor = [NCMessageEditUtil editedTextColor];
        return;
    }
    NSString *messageInfo = @"";
    if ([self.referedContent isKindOfClass:[NCFileMessage class]]) {
        NCFileMessage *msg = (NCFileMessage *)self.referedContent;
        messageInfo =
            [NSString stringWithFormat:@"%@ %@", NCUILocalizedString(@"file_message"), msg.name];
    } else if ([self.referedContent isKindOfClass:[NCImageMessage class]]) {
        NCImageMessage *msg = (NCImageMessage *)self.referedContent;
        self.msgImageView.image = msg.thumbnailImage;
        CGSize imageSize = [NCMessageCellTool getThumbnailImageSize:msg.thumbnailImage];
        if ([NCChatUIUtility isRTL]) {
            self.msgImageView.frame =
                CGRectMake(self.frame.size.width - imageSize.width, name_and_image_view_space,
                           imageSize.width, imageSize.height);
        } else {
            self.msgImageView.frame =
                CGRectMake(0, name_and_image_view_space, imageSize.width, imageSize.height);
        }
    } else if ([self.referedContent isKindOfClass:[NCTextMessage class]] ||
               [self.referedContent isKindOfClass:[NCReferenceMessage class]]) {
        // Set textColor before text so the label's attributeDictionary uses the correct color.
        messageInfo = [NCChatUIUtility formatMessage:self.referedContent
                                           channelId:self.referModel.channelId
                                         channelType:self.referModel.channelType
                                        isAllMessage:YES];
    } else if ([self.referedContent isKindOfClass:[NCStreamMessage class]]) {
        NCStreamMessage *msg = (NCStreamMessage *)self.referedContent;
        messageInfo = msg.content;
    } else if ([self.referedContent isKindOfClass:[NCMessageContent class]]) {
        messageInfo = [NCChatUIUtility formatMessage:self.referedContent
                                           channelId:self.referModel.channelId
                                         channelType:self.referModel.channelType
                                        isAllMessage:YES];
        if (messageInfo.length <= 0) {
            messageInfo = NCUILocalizedString(@"unknown_message_cell_tip");
        }
    }
    if (messageInfo.length > 0) {
        messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
        messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        messageInfo = [messageInfo stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
        self.textLabel.text = messageInfo;
    }

    if (self.referModel.messageDirection == NCMessageDirectionSend) {
        self.leftLimitLine.backgroundColor = NCDynamicColor(@"text_secondary_color");
        self.nameLabel.textColor = NCDynamicColor(@"text_secondary_color");
        if ([self.referedContent isKindOfClass:[NCFileMessage class]]) {
            self.textLabel.textColor = NCDynamicColor(@"primary_color");
        } else {
            self.textLabel.textColor = NCDynamicColor(@"text_secondary_color");
        }
    } else {
        self.nameLabel.textColor = NCDynamicColor(@"text_secondary_color");
        self.leftLimitLine.backgroundColor = NCDynamicColor(@"text_secondary_color");
        if ([self.referedContent isKindOfClass:[NCFileMessage class]]) {
            self.textLabel.textColor = NCDynamicColor(@"primary_color");
        } else {
            self.textLabel.textColor = NCDynamicColor(@"text_secondary_color");
        }
    }

    if (([self.referedContent isKindOfClass:[NCTextMessage class]] ||
         [self.referedContent isKindOfClass:[NCReferenceMessage class]]) &&
        self.textLabel.text.length > 0 && self.referMsgStatus == NCReferenceMessageStatusUpdated) {
        NSString *originalText = self.textLabel.text;
        UIColor *originalColor = NCDynamicColor(@"text_secondary_color");
        UIFont *font = [[NCChatUIConfig defaultConfig].font fontOfFourthLevel];
        NSString *displayText = [NCMessageEditUtil displayTextForOriginalText:originalText
                                                                     isEdited:YES];

        if (displayText.length > originalText.length) {
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc]
                initWithString:displayText
                    attributes:@{
                        NSFontAttributeName : font,
                        NSForegroundColorAttributeName : originalColor
                    }];

            self.textLabel.attributedText = attributedText;
        }
    }
}

- (void)setupSubviews {
    [self addSubview:self.leftLimitLine];
    [self addSubview:self.nameLabel];
    [self addSubview:self.contentView];
    BOOL isDeletedOrRecalled = (self.referMsgStatus == NCReferenceMessageStatusRecalled ||
                                self.referMsgStatus == NCReferenceMessageStatusDeleted);
    // Show the text label after removing the recalled image.
    if ([self.referedContent isKindOfClass:[NCImageMessage class]] && !isDeletedOrRecalled) {
        [self.contentView addSubview:self.msgImageView];
    } else if ([self.referedContent isKindOfClass:[NCFileMessage class]]) {
        [self.contentView addSubview:self.textLabel];
    } else {
        [self.contentView addSubview:self.textLabel];
    }
}

- (void)resetReferencedContentView {
    // Remove every subview created by this view.
    for (UIView *v in self.subviews) {
        [v removeFromSuperview];
    }
    self.msgImageView = nil;
    self.textLabel = nil;
    self.nameLabel = nil;
    self.leftLimitLine = nil;
    self.contentView = nil;
}

- (void)setUserDisplayName {
    NCMessageSenderInfo *senderInfo = [self senderInfoForReferencedMessage];
    self.referModel.userInfo = senderInfo.userInfo;
    NSString *name = senderInfo.name ?: @"";
    __weak typeof(self) weakSelf = self;
    dispatch_main_async_safe(^{
      if ([NCChatUIUtility isRTL]) {
          weakSelf.nameLabel.text = [@":" stringByAppendingString:name ?: @""];
      } else {
          weakSelf.nameLabel.text = [name stringByAppendingString:@":"];
      }
    });
}

- (NCMessageSenderInfo *)senderInfoForReferencedMessage {
    NCChatUIUserInfo *userInfo =
        [NCMessageSenderUserInfoResolver userInfoForChannelType:self.referModel.channelType
                                                      channelId:self.referModel.channelId
                                                   senderUserId:self.referedSenderId
                                                 senderUserInfo:self.referedContent.senderUserInfo];
    return [NCMessageSenderInfo infoWithUserInfo:userInfo];
}

- (NSDictionary *)attributeDictionary {
    return [NCMessageCellTool
        getTextLinkOrPhoneNumberAttributeDictionary:self.referModel.messageDirection];
}

- (void)addNotification {
    [NCInfoUpdateCenter addInfoUpdateDelegate:self];
}

- (void)didTapContentView:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTapReferencedContentView:)]) {
        [self.delegate didTapReferencedContentView:self.referModel];
    }
}

#pragma mark - UserInfo Update
- (void)onUserInfoUpdate:(NCChatUIUserInfo *)userInfo {
    if ([self.referModel.content isKindOfClass:[NCReferenceMessage class]]) {
        if ([self.referedSenderId isEqualToString:userInfo.userId]) {
            // Reload the merged user information.
            [self setUserDisplayName];
        }
    }
}

- (void)onGroupMemberInfoUpdate:(NCChatUIUserInfo *)userInfo groupId:(NSString *)groupId {
    if (self.referModel.channelType == NCChannelTypeGroup &&
        [self.referModel.content isKindOfClass:[NCReferenceMessage class]]) {
        if ([self.referModel.channelId isEqualToString:groupId] &&
            [self.referedSenderId isEqualToString:userInfo.userId]) {
            // Reload the merged user information.
            [self setUserDisplayName];
        }
    }
}

#pragma mark - Getters and Setters
- (UIView *)leftLimitLine {
    if (!_leftLimitLine) {
        if ([NCChatUIUtility isRTL]) {
            _leftLimitLine =
                [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - leftLine_width, 2,
                                                         leftLine_width, 13)];
        } else {
            _leftLimitLine = [[UIView alloc] initWithFrame:CGRectMake(0, 2, leftLine_width, 13)];
        }
        _leftLimitLine.backgroundColor = NCDynamicColor(@"text_secondary_color");
    }
    return _leftLimitLine;
}

- (NCBaseLabel *)nameLabel {
    if (!_nameLabel) {
        CGFloat nameX = CGRectGetMaxX(self.leftLimitLine.frame) + name_and_leftLine_space;
        if ([NCChatUIUtility isRTL]) {
            nameX = 0;
            _nameLabel = [[NCBaseLabel alloc]
                initWithFrame:CGRectMake(nameX, 0,
                                         self.contentSize.width - nameX - name_and_leftLine_space,
                                         name_height)];
        } else {
            _nameLabel = [[NCBaseLabel alloc]
                initWithFrame:CGRectMake(nameX, 0, self.contentSize.width - nameX, name_height)];
        }
        _nameLabel.font = [[NCChatUIConfig defaultConfig].font fontOfFourthLevel];
    }
    return _nameLabel;
}

- (UIView *)contentView {
    if (!_contentView) {
        if ([NCChatUIUtility isRTL]) {
            _contentView =
                [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.nameLabel.frame),
                                                         CGRectGetWidth(self.nameLabel.frame),
                                                         self.frame.size.height -
                                                             CGRectGetMaxY(self.nameLabel.frame))];
        } else {
            _contentView = [[UIView alloc]
                initWithFrame:CGRectMake(
                                  CGRectGetMaxX(self.leftLimitLine.frame) + name_and_leftLine_space,
                                  CGRectGetMaxY(self.nameLabel.frame),
                                  CGRectGetWidth(self.nameLabel.frame),
                                  self.frame.size.height - CGRectGetMaxY(self.nameLabel.frame))];
        }
        UITapGestureRecognizer *messageTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(didTapContentView:)];
        messageTap.numberOfTapsRequired = 1;
        messageTap.numberOfTouchesRequired = 1;
        [_contentView addGestureRecognizer:messageTap];
        _contentView.userInteractionEnabled = YES;
    }
    return _contentView;
}

- (NCBaseLabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[NCBaseLabel alloc] initWithFrame:self.contentView.bounds];
        _textLabel.numberOfLines = 1;
        [_textLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
        _textLabel.font = [[NCChatUIConfig defaultConfig].font fontOfFourthLevel];
    }
    return _textLabel;
}

- (NCBaseImageView *)msgImageView {
    if (!_msgImageView) {
        _msgImageView = [[NCBaseImageView alloc] init];
        _msgImageView.layer.masksToBounds = YES;
        _msgImageView.layer.cornerRadius = 3;
    }
    return _msgImageView;
}
@end
