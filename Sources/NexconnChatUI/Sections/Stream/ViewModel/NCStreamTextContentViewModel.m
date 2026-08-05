//
//  NCStreamTextContentViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStreamTextContentViewModel.h"
#import "NCStreamMessageCellViewModel+internal.h"
#import "NCChatUIConfig.h"
#import "NCMessageCellTool.h"
#import "NCMMMarkdown.h"
#import "NCChatUICommonDefine.h"
#import "NCStreamTextContentView.h"
@interface NCStreamTextContentViewModel ()

@property (nonatomic, copy) NSAttributedString *attributedContent;

@end

@implementation NCStreamTextContentViewModel

#pragma mark -- NCStreamViewModelProtocol

- (CGSize)calculateContentSize {
    self.contentSize = [self coreText];
    return self.contentSize;
}

- (void)streamContentDidUpdate:(nonnull NSString *)content {
    if ([self.content isEqualToString:content]) {
        return;
    }
    self.content = content;
    self.attributedContent = [self coverAttributedContent];
    if ([self.delegate respondsToSelector:@selector(streamContentLayoutWillUpdate)]) {
        [self.delegate streamContentLayoutWillUpdate];
    }
}

- (NCStreamContentView *)streamContentView{
    return [NCStreamTextContentView new];
}

#pragma mark -- private

- (CGSize)coreText {
    CGFloat maxWidth = [self contentMaxWidth];
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX); // Allow unbounded height.
    
    // Calculate the required height with boundingRectWithSize:options:attributes:context:.
    CGRect textRect = [self.attributedContent boundingRectWithSize:maxSize
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];
    return CGSizeMake(maxWidth, ceilf(textRect.size.height));
}

- (NSAttributedString *)coverAttributedContent {
    NSString *content = self.content;
    if (!content) {
        return nil;
    }
    UIColor *color = NCDynamicColor(@"text_primary_color");
    if (!color) {
        color = [NCChatUIUtility generateDynamicColor:HEXCOLOR(0x262626) darkColor:NCMASKCOLOR(0xffffff, 0.8)];
    }
    NSAttributedString *attributedStr =
    [[NSAttributedString alloc] initWithString:self.content
                                    attributes:@{NSFontAttributeName: [[NCChatUIConfig defaultConfig].font fontOfSecondLevel],
                                                 NSForegroundColorAttributeName: color}];
    return attributedStr;
}

@end
