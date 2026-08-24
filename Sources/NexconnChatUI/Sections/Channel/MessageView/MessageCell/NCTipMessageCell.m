//
//  NCTipMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCTipMessageCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCInfoUpdateCenter.h"
#import "NCMessageCellTool.h"
#import "NCUserInfoCacheManager.h"

@interface NCMessageModel (NCTipMessageCell)

- (NSString *)formattedTipMessageText;
- (NSMutableSet *)tipMessageRelatedUserIdList;

@end

@interface NCTipMessageCell () <NCAttributedLabelDelegate, NCInfoUpdateDelegate>

@property (nonatomic, strong) NSMutableSet *relatedUserIdList;

@end

@implementation NCTipMessageCell
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.baseContentView addSubview:self.tipMessageLabel];
    }
    return self;
}

- (void)dealloc {
    [NCInfoUpdateCenter removeInfoUpdateDelegate:self];
}

#pragma mark - Super Methods
+ (CGSize)sizeForMessageModel:(NCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat height = [self getTipLabelSize:model].height;
    height += extraHeight;
    return CGSizeMake(collectionViewWidth, height);
}

- (void)setDataModel:(NCMessageModel *)model {
    [super setDataModel:model];

    self.relatedUserIdList = [model tipMessageRelatedUserIdList];

    self.tipMessageLabel.text = [model formattedTipMessageText];
    CGSize labelSize = [NCTipMessageCell getTipLabelSize:model];

    self.tipMessageLabel.textAlignment = NSTextAlignmentCenter;
    self.tipMessageLabel.frame =
        CGRectMake((self.baseContentView.bounds.size.width - labelSize.width) / 2.0f - 5, 0,
                   labelSize.width + 10, labelSize.height);
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

- (void)attributedLabel:(NCAttributedLabel *)label
    didSelectLinkWithAddress:(NSDictionary *)addressComponents {
}

- (void)attributedLabel:(NCAttributedLabel *)label
    didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
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
+ (CGSize)getTipLabelSize:(NCMessageModel *)model {
    NSString *localizedMessage = [model formattedTipMessageText];
    CGSize textSize =
        [NCChatUIUtility getTextDrawingSize:localizedMessage
                                       font:[[NCChatUIConfig defaultConfig].font fontOfFourthLevel]
                            constrainedSize:CGSizeMake([self getMaxLabelWidth], MAXFLOAT)];
    textSize = CGSizeMake(ceilf(textSize.width), ceilf(textSize.height));
    CGSize labelSize = CGSizeMake(textSize.width + 10, textSize.height + 6);
    return labelSize;
}

+ (CGFloat)getMaxLabelWidth {
    return SCREEN_WIDTH - 30 * 2;
}

- (void)onUserInfoUpdate:(NCChatUIUserInfo *)userInfo {
}

#pragma mark - Getter
- (NCTipLabel *)tipMessageLabel {
    if (!_tipMessageLabel) {
        _tipMessageLabel = [NCTipLabel greyTipLabel];
        _tipMessageLabel.textColor = NCDynamicColor(@"control_title_white_color");
        _tipMessageLabel.delegate = self;
        _tipMessageLabel.userInteractionEnabled = YES;
        _tipMessageLabel.marginInsets = UIEdgeInsetsMake(0.5f, 0.5f, 0.5f, 0.5f);
    }
    return _tipMessageLabel;
}

@end
