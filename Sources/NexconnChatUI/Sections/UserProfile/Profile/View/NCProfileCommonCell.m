//
//  NCProfileCommonCell.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileCommonCell.h"
#import "NCChatUICommonDefine.h"
#import "NCSemanticContext.h"

#define NCProfileCommonCellTitleFontSize 17
#define NCProfileCommonCellTitleLeading 16
#define NCProfileCommonCellTitleWidth 150
#define NCProfileCommonCellTitleHeight 20

#define NCProfileCommonCellArrowTrailing 16
#define NCProfileCommonCellArrowWidth 8
#define NCProfileCommonCellArrowHeight 15

@interface NCProfileCommonCell ()
@end

@implementation NCProfileCommonCell

- (void)setupView {
    [super setupView];
    [self.paddingContainerView addSubview:self.contentStackView];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:NCUserManagementPadding trailing:-NCUserManagementPadding];

    [NSLayoutConstraint activateConstraints:@[
        [self.contentStackView.leadingAnchor
            constraintEqualToAnchor:self.paddingContainerView.leadingAnchor
                           constant:NCProfileCommonCellArrowTrailing],
        [self.contentStackView.trailingAnchor
            constraintEqualToAnchor:self.paddingContainerView.trailingAnchor
                           constant:-NCProfileCommonCellArrowTrailing],
        [self.contentStackView.topAnchor
            constraintEqualToAnchor:self.paddingContainerView.topAnchor],
        [self.contentStackView.bottomAnchor
            constraintEqualToAnchor:self.paddingContainerView.bottomAnchor],

        [self.titleLabel.widthAnchor
            constraintGreaterThanOrEqualToConstant:NCProfileCommonCellTitleWidth],
        [self.arrowView.widthAnchor constraintEqualToConstant:NCProfileCommonCellArrowWidth],
        [self.arrowView.heightAnchor constraintEqualToConstant:NCProfileCommonCellArrowHeight]
    ]];
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = NCDynamicColor(@"text_primary_color");
        _titleLabel.font = [UIFont systemFontOfSize:NCProfileCommonCellTitleFontSize];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_titleLabel setContentHuggingPriority:UILayoutPriorityDefaultLow
                                       forAxis:UILayoutConstraintAxisHorizontal];
        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                     forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _titleLabel;
}

- (NCBaseImageView *)arrowView {
    if (!_arrowView) {
        UIImage *image = NCDynamicImage(@"cell_right_arrow_img");
        _arrowView =
            [[NCBaseImageView alloc] initWithImage:[NCSemanticContext imageflippedForRTL:image]];
        _arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _arrowView;
}

- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.axis = UILayoutConstraintAxisHorizontal;
        _contentStackView.alignment = UIStackViewAlignmentCenter;
        _contentStackView.distribution = UIStackViewDistributionFill;
        _contentStackView.spacing = 5;
        _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contentStackView;
}
@end
