//
//  NCProfileCommonTextCell.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileCommonTextCell.h"
#import "NCChatUICommonDefine.h"

#define NCProfileTextCellDetailFont 15

NSString *const NCProfileTextCellIdentifier = @"NCProfileTextCellIdentifier";

@implementation NCProfileCommonTextCell

- (void)setupView {
    [super setupView];
    [self.contentStackView addArrangedSubview:self.titleLabel];
    [self.contentStackView addArrangedSubview:self.detailLabel];
    [self.contentStackView addArrangedSubview:self.arrowView];
}
#pragma mark - getter

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _detailLabel.font = [UIFont systemFontOfSize:NCProfileTextCellDetailFont];
        _detailLabel.textAlignment = NSTextAlignmentNatural;
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_detailLabel setContentHuggingPriority:UILayoutPriorityRequired
                                        forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _detailLabel;
}
@end
