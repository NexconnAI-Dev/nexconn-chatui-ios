//
//  NCFriendListCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFriendListCellViewModel.h"
#import "NCFriendListCell.h"
#import "NCProfileViewController.h"
#import "NCUserProfileViewModel.h"
@interface NCFriendListCellViewModel ()
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *indexPath;
@end

@implementation NCFriendListCellViewModel

- (instancetype)initWithFriend:(NCFriendInfo *)friendInfo {
    self = [super init];
    if (self) {
        self.friendInfo = friendInfo;
    }
    return self;
}

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCFriendListCell class]
        forCellReuseIdentifier:NCFriendListCellIdentifier];
}

- (void)refreshWithFriend:(NCFriendInfo *)friendInfo {
    self.friendInfo = friendInfo;
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.indexPath) {
          NCFriendListCell *cell = [self.tableView cellForRowAtIndexPath:self.indexPath];
          if (cell && [cell isKindOfClass:[NCFriendListCell class]]) {
              [cell showPortrait:self.friendInfo.avatarUrl];
              cell.labName.text = self.friendInfo.name;
          }
      }
    });
}

- (void)refreshOnlineStatus:(NCSubscribeUserOnlineStatus *)onlineStatus {
    self.onlineStatus = onlineStatus;
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.indexPath) {
          NCFriendListCell *cell = [self.tableView cellForRowAtIndexPath:self.indexPath];
          if (cell && [cell isKindOfClass:[NCFriendListCell class]]) {
              cell.onlineStatusView.hidden = (onlineStatus == nil);
              if (onlineStatus) {
                  cell.onlineStatusView.online = onlineStatus.isOnline;
              }
          }
      }
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.indexPath = indexPath;
    self.tableView = tableView;
    NCFriendListCell *cell = [tableView dequeueReusableCellWithIdentifier:NCFriendListCellIdentifier
                                                             forIndexPath:indexPath];
    cell.hideSeparatorLine = self.hideSeparatorLine;
    if (self.friendInfo) {
        [cell showPortrait:self.friendInfo.avatarUrl];
        cell.labName.text =
            self.friendInfo.remark.length > 0 ? self.friendInfo.remark : self.friendInfo.name;
        cell.onlineStatusView.hidden = !self.displayOnlineStatus || (self.onlineStatus == nil);
        if (self.displayOnlineStatus && self.onlineStatus) {
            cell.onlineStatusView.online = self.onlineStatus.isOnline;
        }
    }
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
    if (self.friendInfo.userId.length == 0) {
        return;
    }
    NCProfileViewModel *viewModel =
        [NCUserProfileViewModel viewModelWithUserId:self.friendInfo.userId];
    NCProfileViewController *profile =
        [[NCProfileViewController alloc] initWithViewModel:viewModel];
    [vc.navigationController pushViewController:profile animated:YES];
}
@end
