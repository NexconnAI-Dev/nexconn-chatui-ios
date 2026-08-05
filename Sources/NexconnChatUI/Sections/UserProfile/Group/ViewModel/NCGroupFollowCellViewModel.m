//
//  NCGroupFollowCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupFollowCellViewModel.h"
#import "NCGroupFollowCell.h"
#import "NCAlertView.h"
#import "NCChatUICommonDefine.h"

@interface NCGroupFollowCellViewModel ()
@property (nonatomic, strong) NCGroupMemberInfo *memberInfo;
@end

@implementation NCGroupFollowCellViewModel
+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:NCGroupFollowCell.class forCellReuseIdentifier:NCGroupFollowCellIdentifier];
}

- (instancetype)initWithMember:(NCGroupMemberInfo *)memberInfo {
    self = [super init];
    if (self) {
        self.memberInfo = memberInfo;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCGroupFollowCell *cell = [tableView dequeueReusableCellWithIdentifier:NCGroupFollowCellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.portraitImageView.imageURL = [NSURL URLWithString:self.memberInfo.avatarUrl];
    if (self.remark.length > 0) {
        cell.nameLabel.text = self.remark;
    } else if (self.memberInfo.nickname.length > 0) {
        cell.nameLabel.text = self.memberInfo.nickname;
    } else {
        cell.nameLabel.text = self.memberInfo.name;
    }
    [cell setActionBlock:^{
        if ([self.delegate respondsToSelector:@selector(actionButtonDidClick:)]) {
            [self.delegate actionButtonDidClick:self];
        }
    }];
    cell.actionButton.hidden = self.hiddenButton;
    cell.actionButton.userInteractionEnabled = !self.hiddenButton;
    cell.hideSeparatorLine = self.hideSeparatorLine;
    return cell;
}

@end
