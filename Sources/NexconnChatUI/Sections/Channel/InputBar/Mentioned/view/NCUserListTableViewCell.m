//
//  NCUserListTableViewCell.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUserListTableViewCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
@implementation NCUserListTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = NCDynamicColor(@"common_background_color");
        // Lay out the cell content.
        [self setUpView];
    }
    return self;
}

#pragma mark - setUpView
- (void)setUpView {
    [super setupView];

    // Avatar
    [self.contentView addSubview:self.headImageView];
    // Name
    [self.contentView addSubview:self.nameLabel];
}

- (void)setHeadImageView:(UIImageView *)headImageView {
    [_headImageView removeFromSuperview];
    _headImageView = headImageView;
    if ([NCChatUIUtility isRTL]) {
        CGRect frame = self.nameLabel.frame;
        frame.origin.x = CGRectGetMinX(_headImageView.frame) - frame.size.width - 10;
        _nameLabel.frame = frame;
    }
    [self.contentView addSubview:_headImageView];
}

#pragma mark - Getters and Setters

- (NCBaseLabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[NCBaseLabel alloc] init];
        [_nameLabel setFont:[[NCChatUIConfig defaultConfig].font fontOfSecondLevel]];
        _nameLabel.textAlignment =
            [NCChatUIUtility isRTL] ? NSTextAlignmentRight : NSTextAlignmentLeft;
        _nameLabel.textColor = NCDynamicColor(@"text_primary_color");
        CGRect frame = CGRectMake(60.0, 5.0, self.bounds.size.width - 60.0, 40.0);
        _nameLabel.frame = frame;
    }
    return _nameLabel;
}

@end
