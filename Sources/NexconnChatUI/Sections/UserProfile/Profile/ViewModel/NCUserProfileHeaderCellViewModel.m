//
//  NCUserProfileHeaderCellViewModel.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUserProfileHeaderCellViewModel.h"
#import "NCUserProfileHeaderCell.h"
#import "NCChatUICommonDefine.h"
#import "NCUserOnlineStatusUtil.h"

#define NCUserProfileHeaderCellHeight 82

@implementation NCUserProfileHeaderCellViewModel
- (instancetype)initWithPortrait:(NSString *)portrait name:(NSString *)name remark:(NSString *)remark {
    self = [super init];
    if (self) {
        self.portrait = portrait;
        self.name = name;
        self.remark = remark;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCUserProfileHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:NCUserProfileHeaderCellIdentifier forIndexPath:indexPath];
    if (self.remark.length > 0) {
        cell.remarkLabel.text = self.remark;
        cell.nameLabel.text = [NSString stringWithFormat:@"%@: %@",NCUILocalizedString(@"name"), self.name];
    } else {
        cell.remarkLabel.text = self.name;
    }
    [cell hiddenNameLabel:!self.remark.length];
    [cell.portraitImageView setImageURL:[NSURL URLWithString:self.portrait]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    [cell hiddenOnlineStatusView:!self.displayOnlineStatus];
    [cell updateOnlineStatus:self.isOnline];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NCUserProfileHeaderCellHeight;
}

@end
