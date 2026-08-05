//
//  NCMessageReadDetailCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageReadDetailCell.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCImageView.h"

@interface NCMessageReadDetailCell ()

/// Avatar image view.
@property (nonatomic, strong) NCImageView *portraitImageView;

/// Display name label.
@property (nonatomic, strong) UILabel *nameLabel;

/// Timestamp label.
@property (nonatomic, strong) UILabel *timeLabel;

@end

@implementation NCMessageReadDetailCell

+ (NSString *)reuseIdentifier {
    return NSStringFromClass([self class]);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.portraitImageView.image = nil;
    self.nameLabel.text = nil;
    self.timeLabel.text = nil;
    self.timeLabel.hidden = YES;
}

- (void)setupView {
    [super setupView];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Avatar.
    self.portraitImageView = [[NCImageView alloc] initWithPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
    [self.contentView addSubview:self.portraitImageView];
    
    // Display name.
    [self.contentView addSubview:self.nameLabel];
    // Timestamp.
    [self.contentView addSubview:self.timeLabel];
    
}

- (void)setupConstraints {
    [super setupConstraints];
    self.portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat padding = 16;
    CGFloat avatarSize = 40;
    CGFloat spacing = 12;
    
    self.portraitImageView.layer.cornerRadius = avatarSize/2.0;
    self.portraitImageView.clipsToBounds = YES;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.portraitImageView.widthAnchor constraintEqualToConstant:avatarSize],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:avatarSize],
        [self.portraitImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:padding],
        [self.portraitImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.portraitImageView.trailingAnchor constant:spacing],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.timeLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.nameLabel.trailingAnchor constant:spacing],
        [self.timeLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-padding],
        [self.timeLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
    ]];
}

- (void)bindViewModel:(NCMessageReadDetailCellViewModel *)viewModel {
    // Set the display name.
    self.nameLabel.text = viewModel.userInfo.name ?: viewModel.userInfo.userId;
    
    // Set the avatar.
    if (viewModel.userInfo.avatarUrl.length > 0) {
        self.portraitImageView.imageURL = [NSURL URLWithString:viewModel.userInfo.avatarUrl];
    } else {
        self.portraitImageView.image = NCDynamicImage(@"channel-list_cell_portrait_msg_img");
    }
    
    // Set the timestamp.
    if (viewModel.displayReadTime.length > 0) {
        self.timeLabel.hidden = NO;
        self.timeLabel.text = viewModel.displayReadTime;
    } else {
        self.timeLabel.hidden = YES;
    }
}

#pragma mark - Getter

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = NCDynamicColor(@"text_secondary_color");
        // Keep the timestamp visible by giving it higher compression resistance.
        [_timeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_timeLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _timeLabel;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textColor = NCDynamicColor(@"text_primary_color");
		[_nameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_nameLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _nameLabel;
}

- (NCImageView *)portraitImageView{
    if (!_portraitImageView) {
        _portraitImageView = [[NCImageView alloc] initWithPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
     }
    return _portraitImageView;
}

@end
