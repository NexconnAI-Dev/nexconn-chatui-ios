//
//  NCSelectChannelCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSelectChannelCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCUserInfoCacheManager.h"
#import "NCImageView.h"
#import "NCChannelModel.h"
#import "NCBaseImageView.h"
#import "NCBaseLabel.h"
#import "NCChatUIGroup.h"
#import "NCChatUIUserInfo.h"
#import "NCInfoUpdateCenter.h"
@interface NCSelectChannelCell () <NCInfoUpdateDelegate>
/*!
 The cell's data model.
 */
@property (nonatomic, strong) NCBaseChannel *model;

@property (nonatomic, strong) NCBaseImageView *selectedImageView;

@property (nonatomic, strong) NCImageView *headerImageView;

@property (nonatomic, strong) NCBaseLabel *nameLabel;

@end

@implementation NCSelectChannelCell
#pragma mark - Life Cycle
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = NCDynamicColor(@"common_background_color");
        [self.contentView addSubview:self.selectedImageView];
        [self.contentView addSubview:self.headerImageView];
        [self.contentView addSubview:self.nameLabel];
        
        [self registerObserver];
    }
    return self;
}

- (void)registerObserver {
    [NCInfoUpdateCenter addInfoUpdateDelegate:self];
}

- (void)dealloc {
    [NCInfoUpdateCenter removeInfoUpdateDelegate:self];
}

#pragma mark - Public Methods

- (void)setConversation:(NCBaseChannel *)conversation ifSelected:(BOOL)ifSelected {
    if (!conversation) {
        return;
    }
    self.model = conversation;
    NCChannelModel *channelModel = [[NCChannelModel alloc] initWithChannel:conversation extend:nil];
    UIImage *defaultHeaderImg = [NCChatUIUtility defaultConversationHeaderImage:channelModel];
    [self.headerImageView setPlaceholderImage:defaultHeaderImg];
    
    if (ifSelected) {
        [self.selectedImageView setImage:NCDynamicImage(@"channel_msg_cell_select_img")];
    } else {
        [self.selectedImageView setImage:NCDynamicImage(@"channel_msg_cell_unselect_img")];
    }
    if (conversation.channelType == NCChannelTypeGroup) {
        NCChatUIGroup *group = [[NCUserInfoCacheManager sharedManager] getGroupInfo:conversation.channelId];
        if (group) {
            [self.headerImageView setImageURL:[NSURL URLWithString:group.avatarUrl]];
            [self.nameLabel setText:group.groupName];
        } else {
            [self.headerImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_group_portrait_img")];
            [self.nameLabel setText:conversation.channelId];
        }
    } else {
        NCChatUIUserInfo *userInfo = [[NCUserInfoCacheManager sharedManager] getUserInfo:conversation.channelId];
        if (userInfo) {
            [self.headerImageView setImageURL:[NSURL URLWithString:userInfo.avatarUrl]];
            [self.nameLabel setText:[NCChatUIUtility getDisplayName:userInfo]];
        } else {
            [self.headerImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
            [self.nameLabel setText:conversation.channelId];
        }
    }
}

#pragma mark - Private Methods

- (void)resetSubviews {
    [self.selectedImageView setImage:NCDynamicImage(@"channel_msg_cell_unselect_img")];
    [self.headerImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
    self.nameLabel.text = nil;
}

#pragma mark - Notification selector
- (void)onUserInfoUpdate:(NCChatUIUserInfo *)userInfo {
    NCChatUIUserInfo *updateUserInfo = userInfo;
    NSString *updateUserId = userInfo.userId;

    if (![updateUserId isEqualToString:self.model.channelId]) {
        return;
    }
    if (self.model.channelType == NCChannelTypeGroup) {
        return;
    }
    if (updateUserInfo) {
        [self.headerImageView setImageURL:[NSURL URLWithString:updateUserInfo.avatarUrl]];
        [self.nameLabel setText:[NCChatUIUtility getDisplayName:updateUserInfo]];
    }
}

- (void)onGroupInfoUpdate:(NCChatUIGroup *)groupInfo {
    if (![self.model.channelId isEqualToString:groupInfo.groupId]) {
        return;
    }
    
    if (self.model.channelType != NCChannelTypeGroup) {
        return;
    }
    
    if (groupInfo) {
        [self.headerImageView setImageURL:[NSURL URLWithString:groupInfo.avatarUrl]];
        [self.nameLabel setText:groupInfo.groupName];
    }
}

#pragma mark - Getters and Setters

- (NCBaseImageView *)selectedImageView {
    if (!_headerImageView) {
        _selectedImageView = [[NCBaseImageView alloc] init];
        if ([NCChatUIUtility isRTL]) {
            // At this point, self.bounds is (origin = (x = 0, y = 0), size = (width = 320, height = 44)).
            _selectedImageView.frame = CGRectMake(self.bounds.size.width + 20 + 5, 25, 20, 20);
        } else {
            _selectedImageView.frame = CGRectMake(10, 25, 20, 20);
        }
        [_selectedImageView setImage:NCDynamicImage(@"channel_msg_cell_unselect_img")];
    }
    return _selectedImageView;
}

- (NCImageView *)headerImageView {
    if (!_headerImageView) {
        _headerImageView = [[NCImageView alloc] init];
        _headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        [_headerImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
        if ([NCChatUIUtility isRTL]) {
            _headerImageView.frame = CGRectMake(self.bounds.size.width - 45, 5, 60, 60);
        } else {
            _headerImageView.frame = CGRectMake(40, 5, 60, 60);
        }
        _headerImageView.layer.cornerRadius = 5;
        _headerImageView.layer.masksToBounds = YES;
    }
    return _headerImageView;
}

- (NCBaseLabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[NCBaseLabel alloc] init];
        if ([NCChatUIUtility isRTL]) {
            _nameLabel.frame = CGRectMake(0, 5, self.bounds.size.width - 55, 60);
        } else {
            _nameLabel.frame = CGRectMake(110, 5, self.bounds.size.width - 110, 60);
        }
        _nameLabel.textColor = NCDynamicColor(@"text_primary_color");
    }
    return _nameLabel;
}

@end
