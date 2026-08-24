//
//  NCSelectUserCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSelectUserCellViewModel.h"
#import "NCSelectUserCell.h"

@interface NCSelectUserCellViewModel ()
@property (nonatomic, strong) NCFriendInfo *friendInfo;
@property (nonatomic, assign) BOOL select;
@property (nonatomic, assign) BOOL fixedState;
@property (nonatomic, copy) NSString *groupId;
@end

@implementation NCSelectUserCellViewModel

- (instancetype)initWithFriend:(NCFriendInfo *)friendInfo groupId:(nonnull NSString *)groupId {
    self = [super init];
    if (self) {
        self.friendInfo = friendInfo;
        self.groupId = groupId;
    }
    return self;
}

- (void)updateCell:(UITableViewCell *)cell state:(NCSelectState)state {
    self.selectState = state;
    if ([cell isKindOfClass:NCSelectUserCell.class]) {
        NCSelectUserCell *memberCell = (NCSelectUserCell *)cell;
        [memberCell updateSelectState:self.selectState];
    }
}

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:NCSelectUserCell.class
        forCellReuseIdentifier:NCSelectUserCellIdentifier];
}

#pragma mark-- NCCellViewModelProtocol

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCSelectUserCell *cell =
        [tableView dequeueReusableCellWithIdentifier:NCSelectUserCellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.portraitImageView.imageURL = [NSURL URLWithString:self.friendInfo.avatarUrl];
    if (self.friendInfo.remark.length > 0) {
        cell.nameLabel.text = self.friendInfo.remark;
    } else {
        cell.nameLabel.text = self.friendInfo.name;
    }
    cell.hideSeparatorLine = self.hideSeparatorLine;
    [cell updateSelectState:self.selectState];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NCUserManagementCellHeight;
}
@end
