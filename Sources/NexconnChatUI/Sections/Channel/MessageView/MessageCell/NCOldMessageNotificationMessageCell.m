//
//  NCOldMessageNotificationMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCOldMessageNotificationMessageCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCChatUIConfig.h"

@interface NCOldMessageNotificationMessageCell ()
@property (nonatomic, strong) UIView *leftView;
@property (nonatomic, strong) UIView *rightView;
@end

@implementation NCOldMessageNotificationMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NCTipLabel *tip = [[NCTipLabel alloc] init];
        tip.marginInsets = UIEdgeInsetsMake(5.f, 5.f, 5.f, 5.f);
        tip.textColor = NCDynamicColor(@"text_secondary_color");
        tip.numberOfLines = 0;
        tip.lineBreakMode = NSLineBreakByCharWrapping;
        tip.textAlignment = NSTextAlignmentCenter;
        tip.font = [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
        tip.layer.masksToBounds = YES;
        tip.layer.cornerRadius = 5.f;
        self.tipMessageLabel = tip;
        [self.baseContentView addSubview:self.tipMessageLabel];
        self.tipMessageLabel.marginInsets = UIEdgeInsetsMake(0.5f, 0.5f, 0.5f, 0.5f);
        self.leftView = [[UIView alloc] init];
        self.leftView.backgroundColor = NCDynamicColor(@"text_secondary_color");
        self.leftView.alpha = 0.5;
        [self.baseContentView addSubview:self.leftView];
        self.rightView = [[UIView alloc] init];
        self.rightView.backgroundColor = NCDynamicColor(@"text_secondary_color");
        self.rightView.alpha = 0.5;
        [self.baseContentView addSubview:self.rightView];
    }
    return self;
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(NCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat height = 37.f;
    return CGSizeMake(collectionViewWidth, height);
}

- (void)setDataModel:(NCMessageModel *)model {
    [super setDataModel:model];
    CGFloat maxMessageLabelWidth = [self labelWiden:self.tipMessageLabel];
    NSString *__text = NCUILocalizedString(@"history_message_tip");
    CGSize __textSize = [NCChatUIUtility getTextDrawingSize:__text
                                                    font:[[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel]
                                         constrainedSize:CGSizeMake(maxMessageLabelWidth, MAXFLOAT)];
    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize = CGSizeMake(__textSize.width + 10, __textSize.height + 6);
    self.tipMessageLabel.text = __text;
    self.tipMessageLabel.frame = CGRectMake((self.baseContentView.bounds.size.width - __labelSize.width) / 2.0f, 0,
                                            __labelSize.width, __labelSize.height);

    [self.leftView setFrame:CGRectMake(10, CGRectGetMidY(self.tipMessageLabel.frame) - 0.5,
                                       CGRectGetMinX(self.tipMessageLabel.frame) - 17, 1)];

    [self.rightView
        setFrame:CGRectMake(CGRectGetMaxX(self.tipMessageLabel.frame) + 7, CGRectGetMinY(self.leftView.frame),
                            CGRectGetWidth(self.baseContentView.frame) - 7 - CGRectGetMaxX(self.tipMessageLabel.frame) -
                                10,
                            1)];
}

#pragma mark - Private Methods

- (CGFloat)labelWiden:(UILabel *)sender {
    CGRect rect = [sender.text boundingRectWithSize:CGSizeMake(2000, sender.frame.size.height)
                                            options:(NSStringDrawingUsesLineFragmentOrigin)
                                         attributes:@{
                                             NSFontAttributeName : [[NCChatUIConfig defaultConfig].font fontOfFourthLevel]
                                         }
                                            context:nil];
    return rect.size.width;
}

@end
