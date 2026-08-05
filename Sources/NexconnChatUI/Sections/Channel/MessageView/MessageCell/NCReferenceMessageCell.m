//
//  NCReferenceMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCReferenceMessageCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCMessageCellTool.h"
#import "NCChatUIConfig.h"
#import "NCAttributedLabel+Edit.h"
#import "NCMessageCell+Edit.h"

#define bubble_top_space 12
#define bubble_bottom_space 12
#define refer_and_text_space 16
#define content_space_left 12
#define content_space_right 12

@interface NCMessageModel (NCReferenceMessageCell)

- (NSString *)referenceMessageContent;
- (BOOL)referenceMessageCanOpenReferencedContent;
- (BOOL)referenceMessageIsDeletedOrRecalled;
- (UIImage *)referenceMessageReferencedThumbnailImage;

@end

@interface NCReferenceMessageCell () <NCAttributedLabelDelegate, NCReferencedContentViewDelegate>
@property (nonatomic, strong) UIView *lineView;
@end
@implementation NCReferenceMessageCell

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
    float maxWidth = [NCMessageCellTool getMessageContentViewMaxWidth];
    NSString *displayText = [NCMessageEditUtil displayTextForOriginalText:[model referenceMessageContent] isEdited:model.hasChanged];
    CGSize textLabelSize = [[self class] getTextLabelSize:displayText
                                                 maxWidth:maxWidth - 33
                                                     font:[[NCChatUIConfig defaultConfig].font fontOfSecondLevel]];
    CGSize contentSize = [[self class] contentInfoSizeWithContent:model maxWidth:maxWidth - 33];
    CGSize messageContentSize =
        CGSizeMake(textLabelSize.width, textLabelSize.height + contentSize.height + bubble_top_space +
                                            bubble_bottom_space + refer_and_text_space);
    CGFloat __messagecontentview_height = messageContentSize.height;
    __messagecontentview_height += extraHeight;
    __messagecontentview_height += [self edit_editStatusBarHeightWithModel:model];
    
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(NCMessageModel *)model {
    [super setDataModel:model];
    [self setAutoLayout];
}

#pragma mark - NCReferencedContentViewDelegate

- (void)didTapReferencedContentView:(NCMessageModel *)message {
    if ([message referenceMessageCanOpenReferencedContent]) {
        if ([self.delegate respondsToSelector:@selector(didTapReferencedContentView:)]) {
            [self.delegate didTapReferencedContentView:message];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
            [self.delegate didTapMessageCell:self.model];
        }
    }
}

#pragma mark - NCAttributedLabelDelegate & NCReferencedContentViewDelegate

- (void)attributedLabel:(NCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    NSString *urlString = [url absoluteString];
    urlString = [NCChatUIUtility checkOrAppendHttpForUrl:urlString];
    if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.delegate didTapUrlInMessageCell:urlString model:self.model];
        return;
    }
}

- (void)attributedLabel:(NCAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    NSString *number = [@"tel://" stringByAppendingString:phoneNumber];
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

    [self.messageContentView addSubview:self.referencedContentView];
    [self.messageContentView addSubview:self.lineView];
    [self.messageContentView addSubview:self.contentLabel];
}

- (void)setAutoLayout {
    if(self.model.messageDirection == NCMessageDirectionReceive){
        [self.contentLabel setTextColor:NCDynamicColor(@"text_primary_color")];
    }else{
        [self.contentLabel setTextColor:NCDynamicColor(@"text_primary_color")];
    }
    if ([self.model referenceMessageContent]) {
        [self.contentLabel edit_setTextWithEditedState:[self.model referenceMessageContent] isEdited:self.model.hasChanged];
    }
    float maxWidth = [NCMessageCellTool getMessageContentViewMaxWidth];
    CGSize textLabelSize = [[self class] getTextLabelSize:self.contentLabel.text
                                                 maxWidth:maxWidth - 33
                                                     font:[[NCChatUIConfig defaultConfig].font fontOfSecondLevel]];
    CGSize contentSize = [[self class] contentInfoSizeWithContent:self.model maxWidth:maxWidth - 33];
    CGSize messageContentSize =
        CGSizeMake(textLabelSize.width + 16 + 10, textLabelSize.height + contentSize.height + bubble_top_space +
                                                      bubble_bottom_space + refer_and_text_space);
    [self.referencedContentView setMessage:self.model contentSize:contentSize];
    
    self.referencedContentView.frame = CGRectMake(content_space_left, 10, contentSize.width, contentSize.height);
    self.lineView.frame = CGRectMake(content_space_left, CGRectGetMaxY(self.referencedContentView.frame) + refer_and_text_space/2, contentSize.width, 1);
    self.contentLabel.frame = CGRectMake(content_space_left, CGRectGetMaxY(self.referencedContentView.frame) + refer_and_text_space,
                                         textLabelSize.width, textLabelSize.height);
    self.messageContentView.contentSize = CGSizeMake(messageContentSize.width, messageContentSize.height);
}

- (NSDictionary *)attributeDictionary {
    return [NCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:self.model.messageDirection];
}

+ (CGSize)contentInfoSizeWithContent:(NCMessageModel *)model maxWidth:(CGFloat)maxWidth {
    CGFloat height = 17; // Height of the sender name.
    UIImage *thumbnailImage = [model referenceMessageReferencedThumbnailImage];
    if (thumbnailImage && ![model referenceMessageIsDeletedOrRecalled]) {
        height = [NCMessageCellTool getThumbnailImageSize:thumbnailImage].height + height + name_and_image_view_space;
    } else {
        height = 34; // Height for two lines of text.
    }
    return CGSizeMake(maxWidth, height);
}

+ (CGSize)getTextLabelSize:(NSString *)message maxWidth:(CGFloat)maxWidth font:(UIFont *)font {
    if ([message length] > 0) {
        CGSize textSize = [NCChatUIUtility getTextDrawingSize:message font:font constrainedSize:CGSizeMake(maxWidth, MAXFLOAT)];
        textSize.height = ceilf(textSize.height);
        return CGSizeMake(maxWidth, textSize.height);
    } else {
        return CGSizeZero;
    }
}

#pragma mark - Getter
- (NCAttributedLabel *)contentLabel{
    if (!_contentLabel) {
        _contentLabel = [[NCAttributedLabel alloc] initWithFrame:CGRectZero];
        _contentLabel.attributeDictionary = [self attributeDictionary];
        _contentLabel.highlightedAttributeDictionary = [self attributeDictionary];
        [_contentLabel setFont:[[NCChatUIConfig defaultConfig].font fontOfSecondLevel]];
        _contentLabel.numberOfLines = 0;
        [_contentLabel setLineBreakMode:NSLineBreakByWordWrapping];
        _contentLabel.delegate = self;
        _contentLabel.userInteractionEnabled = YES;
    }
    return _contentLabel;
}

- (NCReferencedContentView *)referencedContentView{
    if (!_referencedContentView) {
        _referencedContentView = [[NCReferencedContentView alloc] init];
        _referencedContentView.delegate = self;
    }
    return _referencedContentView;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [UIView new];
        _lineView.backgroundColor = NCDynamicColor(@"line_background_color");
    }
    return _lineView;
}
@end
