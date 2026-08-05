//
//  NCGroupMemberCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupMemberCellViewModel.h"
#import "NCGroupMemberCell.h"
#import "NCChatUICommonDefine.h"

@interface NCGroupMemberCellViewModel ()

@property (nonatomic, strong) NCGroupMemberInfo *memberInfo;

@end

@implementation NCGroupMemberCellViewModel

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:NCGroupMemberCell.class forCellReuseIdentifier:NCGroupMemberCellIdentifier];
}

- (instancetype)initWithMember:(NCGroupMemberInfo *)memberInfo {
    self = [super init];
    if (self) {
        self.memberInfo = memberInfo;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCGroupMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:NCGroupMemberCellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self.cellPortraitImage) {
        cell.portraitImageView.image = self.cellPortraitImage;

    } else {
        cell.portraitImageView.imageURL = [NSURL URLWithString:self.memberInfo.avatarUrl];
    }
    if (self.remark.length > 0) {
        cell.nameLabel.text = self.remark;
    } else if (self.memberInfo.nickname.length > 0) {
        cell.nameLabel.text = self.memberInfo.nickname;
    } else {
        cell.nameLabel.text = self.memberInfo.name;
    }
    cell.roleLabel.text = [self getRoleString:self.memberInfo.role];
    cell.hideSeparatorLine = self.hideSeparatorLine;
    [cell hiddenArrow:self.hiddenArrow];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NCUserManagementCellHeight;
}

#pragma mark -- private

- (NSString *)getRoleString:(NCGroupMemberRole)role {
    NSString *string;
    switch (role) {
        case NCGroupMemberRoleOwner:
            string = NCUILocalizedString(@"group_owner");
            break;
        case NCGroupMemberRoleAdmin:
            string = NCUILocalizedString(@"group_manager");
            break;
        default:
            break;
    }
    return string;
}
@end
