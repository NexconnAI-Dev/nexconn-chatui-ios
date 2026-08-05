//
//  NCProfileCommonImageCell.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileCommonImageCell.h"
#import "NCImageView.h"
#import "NCProfileCommonCellViewModel.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"

#define NCProfileImageCellPortraitSize 32

NSString  * const NCProfileImageCellIdentifier = @"NCProfileImageCellIdentifier";
@interface NCProfileCommonImageCell ()

@property (nonatomic, strong) NSLayoutConstraint *portraitTrailingToArrowConstraint;
@property (nonatomic, strong) NSLayoutConstraint *portraitTrailingToContentViewConstraint;

@end

@implementation NCProfileCommonImageCell

- (void)setupView {
    [super setupView];
    [self.contentStackView addArrangedSubview:self.titleLabel];
    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.arrowView];
}

- (void)hiddenArrow:(BOOL)hiddenArrow {
    self.arrowView.hidden = hiddenArrow;
}

#pragma mark - getter
- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[NCImageView alloc] init];
        if (NCChatUIConfigCenter.ui.globalConversationAvatarStyle == NC_USER_AVATAR_CYCLE &&
            NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = NCProfileImageCellPortraitSize/2;
        }else{
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_portraitImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
        [NSLayoutConstraint activateConstraints:@[
            [_portraitImageView.widthAnchor constraintEqualToConstant:NCProfileImageCellPortraitSize],
            [_portraitImageView.heightAnchor constraintEqualToConstant:NCProfileImageCellPortraitSize]
        ]];
    }
    return _portraitImageView;
}
@end
