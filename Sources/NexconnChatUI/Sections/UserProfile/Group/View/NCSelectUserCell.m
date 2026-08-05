//
//  NCSelectUserCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSelectUserCell.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
NSString  * const NCSelectUserCellIdentifier = @"NCSelectUserCellIdentifier";

#define NCSelectUserCellSelectLeading 12
#define NCSelectUserCellSelectSize 20
#define NCSelectUserCellPortraitLeading 8
#define NCSelectUserCellPortraitSize 32
#define NCSelectUserCellNameFont 17
#define NCSelectUserCellNameLeadingSpace 12

@interface NCSelectUserCell ()
@end

@implementation NCSelectUserCell

- (void)setupView {
    [super setupView];
    self.contentStackView.spacing = NCSelectUserCellSelectLeading;
    [self.contentStackView addArrangedSubview:self.selectImageView];
    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.nameLabel];

}

- (void)appendViewAtEnd:(UIView *)view {
    if (view) {
        [self.contentStackView addArrangedSubview:view];
    }
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:80 trailing:-10];
    [NSLayoutConstraint activateConstraints:@[
        [self.portraitImageView.widthAnchor constraintEqualToConstant:NCSelectUserCellPortraitSize],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:NCSelectUserCellPortraitSize],
        
        [self.selectImageView.widthAnchor constraintEqualToConstant:NCSelectUserCellSelectSize],
        [self.selectImageView.heightAnchor constraintEqualToConstant:NCSelectUserCellSelectSize]
    ]];
}

- (void)updateSelectState:(NCSelectState)state {
    switch (state) {
        case NCSelectStateUnselect:
            self.selectImageView.image = NCDynamicImage(@"channel_msg_cell_unselect_img");
            break;
        case NCSelectStateSelect:
            self.selectImageView.image = NCDynamicImage(@"channel_msg_cell_select_img");
            break;
        case NCSelectStateDisable:
            self.selectImageView.image = NCDynamicImage(@"group_member_disable_select_img");
            break;
        default:
            break;
    }
}

#pragma mark - getter

- (NCImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[NCImageView alloc] init];
        if (NCChatUIConfigCenter.ui.globalConversationAvatarStyle == NC_USER_AVATAR_CYCLE &&
            NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = NCSelectUserCellPortraitSize/2;
        }else{
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _portraitImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = NCDynamicColor(@"text_primary_color");
        _nameLabel.font = [UIFont systemFontOfSize:NCSelectUserCellNameFont];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_nameLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_nameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        _nameLabel.textAlignment = NSTextAlignmentNatural;
    }
    return _nameLabel;
}

- (NCBaseImageView *)selectImageView {
   if (!_selectImageView) {
       _selectImageView = [[NCBaseImageView alloc] init];
       _selectImageView.translatesAutoresizingMaskIntoConstraints = NO;
   }
   return _selectImageView;
}

@end
