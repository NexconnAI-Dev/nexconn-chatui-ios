//
//  NCTextMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCTextMessageCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCMessageCellTool.h"
#import "NCChatUIConfig.h"
#import "NCAttributedLabel+Edit.h"
#import "NCMessageCell+Edit.h"
#define TEXT_SPACE_LEFT 12
#define TEXT_SPACE_RIGHT 12
#define TEXT_SPACE_TOP 9.5
#define TEXT_SPACE_BOTTOM 9.5

@interface NCMessageModel (NCTextMessageCell)
- (NSString *)textMessageContent;
@end

@interface NCTextMessageCell ()
@property (nonatomic, strong) NCBaseButton *acceptBtn;
@property (nonatomic, strong) NCBaseButton *rejectBtn;
@property (nonatomic, strong) UIView *separateLine;
@property (nonatomic, strong) UILabel *tipLablel;
@end

@implementation NCTextMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

#pragma mark - Super Methods
+ (CGSize)sizeForMessageModel:(NCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height = [self getMessageContentHeight:model];
    __messagecontentview_height += extraHeight;
    __messagecontentview_height += [self edit_editStatusBarHeightWithModel:model];
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(NCMessageModel *)model {
    [super setDataModel:model];
    [self setAutoLayout];
}

#pragma mark - NCAttributedLabelDelegate

- (void)attributedLabel:(NCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    NSString *urlString = [url absoluteString];
    urlString = [NCChatUIUtility checkOrAppendHttpForUrl:urlString];
    if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.delegate didTapUrlInMessageCell:urlString model:self.model];
        return;
    }
}

/**
 Tells the delegate that the user did select a link to an address.

 @param label The label whose link was selected.
 @param addressComponents The components of the address for the selected link.
 */
- (void)attributedLabel:(NCAttributedLabel *)label didSelectLinkWithAddress:(NSDictionary *)addressComponents {
}

/**
 Tells the delegate that the user did select a link to a phone number.

 @param label The label whose link was selected.
 @param phoneNumber The phone number for the selected link.
 */
- (void)attributedLabel:(NCAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    NSString *number = [NCMessageCellTool phoneURLStringWithPhoneNumber:phoneNumber];
    if (!number) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didTapPhoneNumberInMessageCell:model:)]) {
        [self.delegate didTapPhoneNumberInMessageCell:number model:self.model];
        return;
    }
}

- (void)attributedLabel:(NCAttributedLabel *)label didTapLabel:(NSString *)content {
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}

#pragma mark - Private Methods
- (void)initialize {
    [self showBubbleBackgroundView:YES];

    [self.messageContentView addSubview:self.textLabel];
}


- (void)setAutoLayout {
    CGSize labelSize = [NCTextMessageCell getTextSize:self.model];//textlabelsize
    
    float maxWidth = [NCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat bubbleHeight = [NCTextMessageCell getMessageContentHeight:self.model];
    CGFloat bubbleWidth = labelSize.width + TEXT_SPACE_RIGHT + TEXT_SPACE_LEFT;
    if (bubbleWidth >= maxWidth) {
        bubbleWidth = maxWidth;
    }
    
    [self setCSEvaUILayout:bubbleWidth bubbleHeight:bubbleHeight];

    self.messageContentView.contentSize = CGSizeMake(bubbleWidth, bubbleHeight);

    if (self.model.messageDirection == NCMessageDirectionReceive) {
        [self.textLabel setTextColor:NCDynamicColor(@"text_primary_color")];
        self.textLabel.frame =  CGRectMake(TEXT_SPACE_LEFT, (bubbleHeight - labelSize.height) / 2, labelSize.width, labelSize.height);
    } else {
        [self.textLabel setTextColor:NCDynamicColor(@"text_primary_color")];
        self.textLabel.frame =  CGRectMake(TEXT_SPACE_LEFT, (bubbleHeight - labelSize.height) / 2, labelSize.width, labelSize.height);
    }

    NSString *textContent = [self.model textMessageContent];
    if (textContent) {
        [self.textLabel edit_setTextWithEditedState:textContent isEdited:self.model.hasChanged];
    } else {
        NCLogD(@"[NexconnChatUI]: NCMessageModel.content is NOT NCTextMessage object");
    }
}

- (NSDictionary *)attributeDictionary {
    return [NCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:self.model.messageDirection
                                                             linkColorKey:@"primary_color"];
}

- (void)setCSEvaUILayout:(CGFloat)bubbleWidth bubbleHeight:(CGFloat)bubbleHeight{
    [self.acceptBtn removeFromSuperview];
    [self.rejectBtn removeFromSuperview];
    [self.separateLine removeFromSuperview];
    [self.tipLablel removeFromSuperview];
    self.acceptBtn = nil;
    self.rejectBtn = nil;
    self.separateLine = nil;
    self.tipLablel = nil;
}

+ (CGFloat)getMessageContentHeight:(NCMessageModel *)model{
    CGSize textMessageSize = [self getTextSize:model];
    // Minimum bubble background height.
    CGFloat messagecontentview_height = textMessageSize.height + TEXT_SPACE_TOP + TEXT_SPACE_BOTTOM;

    if (messagecontentview_height < NCChatUIConfigCenter.ui.globalMessagePortraitSize.height) {
        messagecontentview_height = NCChatUIConfigCenter.ui.globalMessagePortraitSize.height;
    }
    return messagecontentview_height;
}

+ (CGSize)getTextSize:(NCMessageModel *)model{
    CGFloat textMaxWidth = [NCMessageCellTool getMessageContentViewMaxWidth] - TEXT_SPACE_LEFT - TEXT_SPACE_RIGHT;
    CGSize textMessageSize;
    UIFont *font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
    textMessageSize = [NCMessageEditUtil sizeForText:[model textMessageContent] isEdited:model.hasChanged font:font constrainedSize:CGSizeMake(textMaxWidth, 80000)];
    if (textMessageSize.width > textMaxWidth) {
        textMessageSize.width = textMaxWidth;
    }
    textMessageSize = CGSizeMake(ceilf(textMessageSize.width), ceilf(textMessageSize.height));
    return textMessageSize;
}

#pragma mark - Getter & Setter
- (NCAttributedLabel *)textLabel{
    if (!_textLabel) {
        _textLabel = [[NCAttributedLabel alloc] initWithFrame:CGRectZero];
        [_textLabel setFont:[[NCChatUIConfig defaultConfig].font fontOfSecondLevel]];
        _textLabel.numberOfLines = 0;
        [_textLabel setLineBreakMode:NSLineBreakByWordWrapping];
        if([NCChatUIUtility isRTL]){
            _textLabel.textAlignment = NSTextAlignmentRight;
        }else{
            _textLabel.textAlignment = NSTextAlignmentLeft;
        }
        _textLabel.delegate = self;
        _textLabel.userInteractionEnabled = YES;
        _textLabel.attributeDictionary = [self attributeDictionary];
        _textLabel.highlightedAttributeDictionary = [self attributeDictionary];
    }
    return _textLabel;
}

@end
