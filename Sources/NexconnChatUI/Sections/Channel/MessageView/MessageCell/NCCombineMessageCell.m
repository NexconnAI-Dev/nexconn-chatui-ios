//
//  NCCombineMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCCombineMessageCell.h"
#import "NCChatUICommonDefine.h"
#import "NCCombineMessageUtility.h"
#import "NCMessageCellTool.h"
#import "NCChatUIConfig.h"
#define NCCOMBINECELLWIDTH 230.0f
#define NCCOMBINEBACKVIEWLEFT 12.0f
#define NCCOMBINETITLELABLETOP 6.0f
#define NCCOMBINETITLELABLEHEIGHT 24.0f
#define NCCOMBINECONTENTLABELTOPSPACE 4.0f
#define NCCOMBINECONTENTLABELSINGLEHEIGHT 18.5f
#define NCCOMBINELINEVIEWTOPSPACE 10.0f
#define NCCOMBINELINEVIEWHEIGHT 0.5f
#define NCCOMBINEHISTORYLABELTOPSPACE 4.0f
#define NCCOMBINEHISTORYLABELHEIGHT 16.5f
#define NCCOMBINEHISTORYLABELBOTTOMSPACE 6.0f
#define NCCOMBINECELLHEIGHTOVERCONTENTLABEL (NCCOMBINETITLELABLETOP + NCCOMBINETITLELABLEHEIGHT + NCCOMBINECONTENTLABELTOPSPACE + NCCOMBINELINEVIEWTOPSPACE + NCCOMBINELINEVIEWHEIGHT + NCCOMBINEHISTORYLABELTOPSPACE + NCCOMBINEHISTORYLABELHEIGHT + NCCOMBINEHISTORYLABELBOTTOMSPACE)
#define CONTENTLINESPACE 5

@interface NCMessageModel (NCCombineMessageCell)

- (NSString *)combineMessageSummaryTitle;
- (NSString *)combineMessageSummaryContent;

@end

@interface NCCombineMessageCell ()

@property (nonatomic, strong) UILabel *lineLable;

@end

@implementation NCCombineMessageCell

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
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(NCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height;
    __messagecontentview_height = [NCCombineMessageCell calculateCellHeight:model];
    if (__messagecontentview_height < NCChatUIConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = NCChatUIConfigCenter.ui.globalMessagePortraitSize.height;
    }
    __messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(NCMessageModel *)model {
    if (!model) {
        return;
    }
    [super setDataModel:model];
    [self resetSubViews];
    [self calculateContenViewSize:model];
    NSString *title = [model combineMessageSummaryTitle];
    self.titleLabel.text = title;
    NSString *summaryContent = [model combineMessageSummaryContent] ?: @"";
    NSMutableAttributedString *attriString =
    [[NSMutableAttributedString alloc] initWithString:summaryContent];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:CONTENTLINESPACE]; // Set the line spacing.
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    if([NCChatUIUtility isRTL]){
        paragraphStyle.alignment = NSTextAlignmentRight;
    }else{
        paragraphStyle.alignment = NSTextAlignmentLeft;
    }
    [attriString addAttribute:NSParagraphStyleAttributeName
                        value:paragraphStyle
                        range:NSMakeRange(0, [summaryContent length])];
    self.contentLabel.attributedText = attriString;
    [self updateStatusContentView:self.model];
}

#pragma mark - Private Methods

+ (CGFloat)calculateCellHeight:(NCMessageModel *)model {
    CGFloat height = NCCOMBINECELLHEIGHTOVERCONTENTLABEL;
    NSString *summary = [model combineMessageSummaryContent];
    CGSize size = [self getTextDrawingSize:summary
                                      font:[[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel]
                           constrainedSize:CGSizeMake(NCCOMBINECELLWIDTH - 25, 9999) lineSpace:CONTENTLINESPACE];
    height += ceilf(size.height);
    if (height > NCCOMBINECELLHEIGHTOVERCONTENTLABEL + NCCOMBINECONTENTLABELSINGLEHEIGHT * 4) {
        height = NCCOMBINECELLHEIGHTOVERCONTENTLABEL + NCCOMBINECONTENTLABELSINGLEHEIGHT * 4;
    }
    return height;
}

+ (CGSize)getTextDrawingSize:(NSString *)text font:(UIFont *)font constrainedSize:(CGSize)constrainedSize lineSpace:(NSInteger)lineSpace{
    if (text.length <= 0) {
        return CGSizeZero;
    }

    if ([text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        // NSStringDrawingUsesLineFragmentOrigin enables width-constrained line layout, so an explicit lineBreakMode is unnecessary.
        // paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        paragraphStyle.lineSpacing = lineSpace;
        NSDictionary *attributes = @{NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle};

        return [text boundingRectWithSize:constrainedSize
                                  options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                               attributes:attributes
                                  context:nil].size;
    }
    return CGSizeZero;
}


- (void)initialize {
    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.backView];
    [self.backView addSubview:self.titleLabel];
    [self.backView addSubview:self.contentLabel];
    [self.backView addSubview:self.lineLable];
    [self.backView addSubview:self.historyLabel];
}

- (void)resetSubViews {
    self.titleLabel.text = nil;
    self.contentLabel.text = nil;
}

- (void)calculateContenViewSize:(NCMessageModel *)model {
    CGFloat messageContentViewHeight = [NCCombineMessageCell calculateCellHeight:model];
    self.messageContentView.contentSize = CGSizeMake(NCCOMBINECELLWIDTH, messageContentViewHeight);
    [self autoLayoutSubViews];
}

- (void)autoLayoutSubViews {
    if(self.model.messageDirection == NCMessageDirectionReceive){
        [self.titleLabel setTextColor: NCDynamicColor(@"text_primary_color")];
        self.lineLable.backgroundColor = NCDynamicColor(@"line_background_color");
        self.contentLabel.textColor = NCDynamicColor(@"text_secondary_color");
        self.historyLabel.textColor =
        NCDynamicColor(@"text_secondary_color");
    }else{
        [self.titleLabel setTextColor:NCDynamicColor(@"text_primary_color")];
        self.lineLable.backgroundColor = NCDynamicColor(@"line_background_color");
        self.contentLabel.textColor = NCDynamicColor(@"text_secondary_color");
        self.historyLabel.textColor = NCDynamicColor(@"text_secondary_color");
    }
    self.backView.frame = CGRectMake(NCCOMBINEBACKVIEWLEFT, 0,
                                     self.messageContentView.frame.size.width - NCCOMBINEBACKVIEWLEFT * 2,
                                     self.messageContentView.frame.size.height);
    self.titleLabel.frame = CGRectMake(0, NCCOMBINETITLELABLETOP, self.backView.frame.size.width, NCCOMBINETITLELABLEHEIGHT);
    self.contentLabel.frame = CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame)+NCCOMBINECONTENTLABELTOPSPACE, self.backView.frame.size.width, self.messageContentView.frame.size.height - NCCOMBINECELLHEIGHTOVERCONTENTLABEL);
    self.lineLable.frame = CGRectMake(0, CGRectGetMaxY(self.contentLabel.frame) + NCCOMBINELINEVIEWTOPSPACE, self.backView.frame.size.width, NCCOMBINELINEVIEWHEIGHT);
    self.historyLabel.frame = CGRectMake(0, CGRectGetMaxY(self.lineLable.frame) + NCCOMBINEHISTORYLABELTOPSPACE, self.backView.frame.size.width, NCCOMBINEHISTORYLABELHEIGHT);
}

- (void)longPressed:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        NCLogD(@"long press end");
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(didLongTouchMessageCell:inView:)]) {
            [self.delegate didLongTouchMessageCell:self.model inView:self.backView];
        }
    }
}

#pragma mark - Getters and Setters
- (NCBaseView *)backView {
    if (!_backView) {
        _backView = [[NCBaseView alloc] initWithFrame:CGRectZero];
        _backView.userInteractionEnabled = NO;
        _backView.backgroundColor = [UIColor clearColor];
    }
    return _backView;
}

- (NCBaseLabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[NCBaseLabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
        _titleLabel.numberOfLines = 1;
        _titleLabel.backgroundColor = [UIColor clearColor];
    }
    return _titleLabel;
}

- (NCBaseLabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[NCBaseLabel alloc] initWithFrame:CGRectZero];
        _contentLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
        _contentLabel.numberOfLines = 0;
        [_contentLabel sizeToFit];
        _contentLabel.backgroundColor = [UIColor clearColor];
    }
    return _contentLabel;
}

- (UILabel *)lineLable {
    if (!_lineLable) {
        _lineLable = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    return _lineLable;
}

- (NCBaseLabel *)historyLabel {
    if (!_historyLabel) {
        _historyLabel = [[NCBaseLabel alloc] initWithFrame:CGRectZero];
        _historyLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
        _historyLabel.numberOfLines = 1;
        _historyLabel.backgroundColor = [UIColor clearColor];
        _historyLabel.text = NCUILocalizedString(@"chat_history");
    }
    return _historyLabel;
}
@end
