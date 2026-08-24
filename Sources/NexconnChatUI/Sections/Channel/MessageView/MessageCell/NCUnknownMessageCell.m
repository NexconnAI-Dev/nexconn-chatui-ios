//
//  NCUnknownMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUnknownMessageCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
@implementation NCUnknownMessageCell

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

- (void)setDataModel:(NCMessageModel *)model {
    [super setDataModel:model];

    CGFloat maxMessageLabelWidth = self.baseContentView.bounds.size.width - 30 * 2;

    [self.messageLabel setText:NCUILocalizedString(@"unknown_message_cell_tip")
           dataDetectorEnabled:NO];

    NSString *__text = self.messageLabel.text;
    CGSize __textSize =
        [NCChatUIUtility getTextDrawingSize:__text
                                       font:[[NCChatUIConfig defaultConfig].font fontOfFourthLevel]
                            constrainedSize:CGSizeMake(maxMessageLabelWidth, MAXFLOAT)];
    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize = CGSizeMake(__textSize.width + 5, __textSize.height + 6);

    self.messageLabel.frame =
        CGRectMake((self.baseContentView.bounds.size.width - __labelSize.width) / 2.0f, 0,
                   __labelSize.width, __labelSize.height);
}

#pragma mark - Private Methods

- (void)initialize {
    self.messageLabel = [NCTipLabel greyTipLabel];
    self.messageLabel.backgroundColor = NCDynamicColor(@"common_background_color");
    self.messageLabel.textColor = NCDynamicColor(@"text_secondary_color");
    [self.baseContentView addSubview:self.messageLabel];
    self.messageLabel.marginInsets = UIEdgeInsetsMake(0.5f, 0.5f, 0.5f, 0.5f);
}
@end
