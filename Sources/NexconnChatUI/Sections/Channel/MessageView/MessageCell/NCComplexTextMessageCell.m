//
//  NCComplexTextMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCComplexTextMessageCell.h"
#import "NCAsyncLabel.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCMessageCellTool.h"
#import "NCChatUIConfig.h"
#import "NCMessageModel+Txt.h"
#import "NCBaseButton.h"
#define TEXT_SPACE_LEFT 12
#define TEXT_SPACE_RIGHT 12
#define TEXT_SPACE_TOP 9.5
#define TEXT_SPACE_BOTTOM 9.5

NSString *const NCComplexTextMessageCellIdentifier = @"NCComplexTextMessageCellIdentifier";

@interface NCMessageModel (NCComplexTextMessageCell)

- (NSString *)textMessageContent;

@end

@interface NCComplexTextMessageCell()<NCAsyncLabelDelegate>
@property (nonatomic, strong) NCAsyncLabel *contentAyncLab;
@property (nonatomic, strong) NCBaseButton *acceptBtn;
@property (nonatomic, strong) NCBaseButton *rejectBtn;
@property (nonatomic, strong) UIView *separateLine;
@property (nonatomic, strong) UILabel *tipLablel;
@end

@implementation NCComplexTextMessageCell

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

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.contentAyncLab clean];
}

#pragma mark - Super Methods
+ (CGSize)sizeForMessageModel:(NCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height = [self getMessageContentHeight:model];
    __messagecontentview_height += extraHeight;

    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(NCMessageModel *)model {
    [super setDataModel:model];
    [self setAutoLayout];
}

#pragma mark - Private Methods
- (void)initialize {
    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.contentAyncLab];
}


- (void)setAutoLayout {
    CGSize labelSize = [[self class] getTextSize:self.model];//textlabelsize
    
    float maxWidth = [NCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat bubbleHeight = [[self class] getMessageContentHeight:self.model];
    CGFloat bubbleWidth = labelSize.width + TEXT_SPACE_RIGHT + TEXT_SPACE_LEFT;
    if (bubbleWidth >= maxWidth) {
        bubbleWidth = maxWidth;
    }
    
    [self setCSEvaUILayout:bubbleWidth bubbleHeight:bubbleHeight];

    self.messageContentView.contentSize = CGSizeMake(bubbleWidth, bubbleHeight);
    self.contentAyncLab.frame =  CGRectMake(TEXT_SPACE_LEFT, (bubbleHeight - labelSize.height) / 2, labelSize.width, labelSize.height);

    if([self.model textMessageContent]){
        self.contentAyncLab.text = [self.model textMessageContent];
    }else{
        NCLogD(@"[NexconnChatUI]: NCMessageModel.content is NOT NCTextMessage object");
    }
}

- (NSDictionary *)attributeDictionary {
    return [NCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:self.model.messageDirection];
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
    CGSize textMessageSize = [model txt_textSize];
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
    textMessageSize = [model txt_textSize];
    if (textMessageSize.width > textMaxWidth) {
        textMessageSize.width = textMaxWidth;
    }
    textMessageSize = CGSizeMake(ceilf(textMessageSize.width), ceilf(textMessageSize.height));
    return textMessageSize;
}

#pragma mark - NCAsyncLabelDelegate

- (BOOL)shouldDetectText {
    return YES;
}

- (NSDictionary *)textAttributesInfo {
    if (self.attributeDictionary) {
        return self.attributeDictionary;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    UIColor *linkColor = NCDynamicColor(@"link_color");
    if (linkColor) {
        NSDictionary *numAttr =  @{
             NSForegroundColorAttributeName :linkColor,
             NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
             NSUnderlineColorAttributeName : linkColor
         };
         dic[@(NSTextCheckingTypePhoneNumber)] = numAttr;
        NSDictionary *linkAttr =  @{
            NSForegroundColorAttributeName :linkColor,
            NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
            NSUnderlineColorAttributeName :linkColor
        };
        dic[@(NSTextCheckingTypeLink)] = linkAttr;
    }
   
    if (self.model.messageDirection == NCMessageDirectionReceive) {
        UIColor *color = NCDynamicColor(@"text_primary_color");
        dic[NSForegroundColorAttributeName] = color;
    } else {
        UIColor *color = NCDynamicColor(@"text_primary_color");
        dic[NSForegroundColorAttributeName] = color;
    }
    return dic;
}


- (void)asyncLabel:(NCAsyncLabel *)label didSelectLinkWithURL:(NSURL *)url {
    NCLogD(@"url: %@", url);
    NSString *urlString = [url absoluteString];
    urlString = [NCChatUIUtility checkOrAppendHttpForUrl:urlString];
    if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.delegate didTapUrlInMessageCell:urlString model:self.model];
        return;
    }
}

- (void)asyncLabel:(NCAsyncLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    NCLogD(@"phoneNumber: %@", phoneNumber);
    NSString *number = [@"tel://" stringByAppendingString:phoneNumber];
    if ([self.delegate respondsToSelector:@selector(didTapPhoneNumberInMessageCell:model:)]) {
        [self.delegate didTapPhoneNumberInMessageCell:number model:self.model];
        return;
    }
}

- (void)didTapAsyncLabel:(NCAsyncLabel *)label {
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}
#pragma mark - Property

- (NCAsyncLabel *)contentAyncLab {
    if (!_contentAyncLab) {
        _contentAyncLab = [NCAsyncLabel new];
        _contentAyncLab.delegate = self;
        _contentAyncLab.font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
    }
    return _contentAyncLab;
}

@end
