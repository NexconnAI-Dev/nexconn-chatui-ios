//
//  NCProfileGenderCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileGenderCell.h"
#import "NCChatUICommonDefine.h"

NSString *const NCProfileGenderCellIdentifier = @"NCProfileGenderCellIdentifier";

#define NCProfileGenderCellTitleFontSize 17
#define NCProfileGenderCellArrowWidth 20
#define NCProfileGenderCellArrowHeight 20

@implementation NCProfileGenderCell

- (void)setupView {
    [super setupView];
    [self.contentStackView addArrangedSubview:self.titleLabel];
    [self.contentStackView addArrangedSubview:self.selectView];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:NCUserManagementPadding trailing:-NCUserManagementPadding];

    [NSLayoutConstraint activateConstraints:@[
        [self.selectView.widthAnchor constraintEqualToConstant:NCProfileGenderCellArrowWidth],
        [self.selectView.heightAnchor constraintEqualToConstant:NCProfileGenderCellArrowHeight],
    ]];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = NCDynamicColor(@"text_primary_color");
        _titleLabel.font = [UIFont systemFontOfSize:NCProfileGenderCellTitleFontSize];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_titleLabel setContentHuggingPriority:UILayoutPriorityDefaultLow
                                       forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _titleLabel;
}

- (NCBaseImageView *)selectView {
    if (!_selectView) {
        _selectView = [[NCBaseImageView alloc]
            initWithImage:NCDynamicImage(@"group_manage_gender_cell_check_img")];
        _selectView.translatesAutoresizingMaskIntoConstraints = NO;
        [_selectView setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                       forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _selectView;
}

@end
