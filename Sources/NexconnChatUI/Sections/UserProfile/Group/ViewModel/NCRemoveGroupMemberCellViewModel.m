//
//  NCRemoveGroupMemberCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCRemoveGroupMemberCellViewModel.h"
#import "NCRemoveGroupMemberCell.h"
#import "NCGroupManager.h"
#import "NCChatUICommonDefine.h"


@interface NCRemoveGroupMemberCellViewModel()

@property (nonatomic, strong) NCGroupMemberInfo *member;

@property (nonatomic, strong) NCRemoveGroupMemberCell *cell;

@property (nonatomic, assign) NCSelectState selectState;

@end

@implementation NCRemoveGroupMemberCellViewModel

- (instancetype)initWithMember:(NCGroupMemberInfo *)member {
    self = [super init];
    if (self) {
        self.member = member;
    }
    return self;
}

- (void)updateCell:(UITableViewCell *)cell state:(NCSelectState)state {
    self.selectState = state;
    if ([cell isKindOfClass:NCRemoveGroupMemberCell.class]) {
        NCRemoveGroupMemberCell *memberCell = (NCRemoveGroupMemberCell *)cell;
        [memberCell updateSelectState:self.selectState];
    }
}

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:NCRemoveGroupMemberCell.class forCellReuseIdentifier:NCRemoveGroupMemberCellIdentifier];
}

#pragma mark -- NCCellViewModelProtocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCRemoveGroupMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:NCRemoveGroupMemberCellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.portraitImageView.imageURL = [NSURL URLWithString:self.member.avatarUrl];
    cell.roleLabel.hidden = self.hiddenRole;
    cell.roleLabel.text = [self getRoleString:self.member.role];
    if (self.remark.length > 0) {
        cell.nameLabel.text = self.remark;
    } else if (self.member.nickname.length > 0) {
        cell.nameLabel.text = self.member.nickname;
    } else {
        cell.nameLabel.text = self.member.name;
    }
    cell.hideSeparatorLine = self.hideSeparatorLine;
    [cell updateSelectState:self.selectState];
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
