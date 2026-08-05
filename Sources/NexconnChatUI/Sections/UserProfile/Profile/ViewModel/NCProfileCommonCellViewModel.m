//
//  NCProfileCommonCellViewModel.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileCommonCellViewModel.h"
#import "NCProfileCommonTextCell.h"
#import "NCProfileCommonImageCell.h"
#import "NCNameEditViewController.h"
#import "NCChatUICommonDefine.h"


@implementation NCProfileCommonCellViewModel

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:NCProfileCommonTextCell.class forCellReuseIdentifier:NCProfileTextCellIdentifier];
    [tableView registerClass:NCProfileCommonImageCell.class forCellReuseIdentifier:NCProfileImageCellIdentifier];
}

- (instancetype)initWithCellType:(NCUProfileCellType)type title:(NSString *)title detail:(NSString *)detail {
    self = [super init];
    if (self) {
        self.title = title;
        self.detail = detail;
        self.type = type;
        self.channelType = NCChannelTypeDirect;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.type == NCUProfileCellTypeText) {
        NCProfileCommonTextCell *cell = [tableView dequeueReusableCellWithIdentifier:NCProfileTextCellIdentifier forIndexPath:indexPath];
        cell.titleLabel.text = self.title;
        cell.detailLabel.text = self.detail;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.arrowView.hidden = self.hiddenArrow;
        cell.hideSeparatorLine = self.hideSeparatorLine;
        return cell;
    }
    
    if (self.type == NCUProfileCellTypeImage) {
        NCProfileCommonImageCell *cell = [tableView dequeueReusableCellWithIdentifier:NCProfileImageCellIdentifier forIndexPath:indexPath];
        cell.titleLabel.text = self.title;
        if (self.channelType == NCChannelTypeGroup) {
            [cell.portraitImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_group_portrait_img")];
        } else {
            [cell.portraitImageView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
        }
        [cell.portraitImageView setImageURL:[NSURL URLWithString:self.detail]];
        [cell hiddenArrow:self.hiddenArrow];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.hideSeparatorLine = self.hideSeparatorLine;
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NCUserManagementCellHeight;
}

@end
