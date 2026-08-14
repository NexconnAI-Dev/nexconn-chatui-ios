//
//  NCGroupFollowsViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupFollowsViewModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCGroupFollowCellViewModel.h"
#import "NCGroupManager.h"
#import "NCChatUICommonDefine.h"
#import "NCSelectGroupMemberViewController.h"
#import "NCAlertView.h"
#import "NCGroupMemberAdditionalCellViewModel.h"
#import "NCChatUI.h"

static BOOL NCGroupFollowsOperationInvalidatesCurrentUser(NCGroupOperationEvent *event) {
    if (event.operation == NCGroupOperationDismiss) {
        return YES;
    }
    if (event.operation != NCGroupOperationKick && event.operation != NCGroupOperationQuit) {
        return NO;
    }
    NSString *currentUserId = [NCEngine getCurrentUserId] ?: @"";
    if (currentUserId.length == 0) {
        return NO;
    }
    for (NCGroupMemberInfo *memberInfo in event.memberInfos) {
        if ([memberInfo.userId isEqualToString:currentUserId]) {
            return YES;
        }
    }
    return NO;
}

@interface NCGroupFollowsViewModel ()<NCGroupFollowCellViewModelDelegate, NCGroupChannelHandler>
@property (nonatomic, copy) NSString *groupId;
@property (nonatomic, strong) NSMutableArray <NCBaseCellViewModel *>*mutableFollowList;
@property (nonatomic, strong) NSMutableArray *followUserIds;
@property (nonatomic, weak) id<NCListViewModelResponder> responder;
@property (nonatomic, copy) NSString *groupEventHandlerId;
@end

@implementation NCGroupFollowsViewModel
+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    NCGroupFollowsViewModel *viewModel = [NCGroupFollowsViewModel new];
    viewModel.groupId = groupId;
    viewModel.groupEventHandlerId = [NSString stringWithFormat:@"nc.group.follows.%p", viewModel];
    [NCEngine addGroupChannelHandlerWithIdentifier:viewModel.groupEventHandlerId handler:viewModel];
    return viewModel;
}

- (void)dealloc {
    [NCEngine removeGroupChannelHandlerForIdentifier:self.groupEventHandlerId];
}

- (void)fetchGroupFollows {
    NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId ?: @""];
    if (!channel) {
        return;
    }
    [channel getFavoritesWithCompletion:^(NSArray<NCGroupFavoriteInfo *> * _Nullable followInfos, NCError * _Nullable error) {
        if (error) {
            return;
        }
        self.followUserIds = nil;
        if (followInfos.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resetMutableFollowList];
                [self removeSeparatorLineIfNeed:@[self.mutableFollowList]];
                [self.responder reloadData:YES];
            });
            return;
        }
        NSMutableArray *userIds = [NSMutableArray array];
        for (NCGroupFavoriteInfo *info in followInfos) {
            if (info.userId) {
                [userIds addObject:info.userId];
            }
        }
        self.followUserIds = userIds;
        [self getDetailInfo:^(NSArray<NCGroupFollowCellViewModel *> *cellVMs) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resetMutableFollowList];
                [self.mutableFollowList addObjectsFromArray:cellVMs];
                if (self.mutableFollowList.count) {
                    [self removeSeparatorLineIfNeed:@[self.mutableFollowList]];
                }
                [self.responder reloadData:self.mutableFollowList.count == 1];
            });
        }];
    }];
}

- (void)bindResponder:(id<NCListViewModelResponder>)responder {
    self.responder = responder;
}

#pragma mark -- NCGroupChannelHandler

- (void)onGroupFavoritesChangedSync:(NCGroupFavoritesChangedSyncEvent *)event {
    if ([event.groupId isEqualToString:self.groupId]) {
        [self fetchGroupFollows];
    }
}

- (void)onGroupOperation:(NCGroupOperationEvent *)event {
    if (![event.groupId isEqualToString:self.groupId] ||
        !NCGroupFollowsOperationInvalidatesCurrentUser(event)) {
        return;
    }
    void (^leaveBlock)(void) = ^{
        UIViewController *viewController = [self.responder currentViewController];
        [viewController.navigationController popViewControllerAnimated:YES];
        [NCAlertView showAlertController:nil message:NCUILocalizedString(@"not_in_group") hiddenAfterDelay:1];
    };
    if ([NSThread isMainThread]) {
        leaveBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), leaveBlock);
    }
}


#pragma mark -- NCGroupFollowCellViewModelDelegate

- (void)actionButtonDidClick:(NCGroupFollowCellViewModel *)cellViewModel {
    NSString *name;
    if (cellViewModel.remark.length > 0) {
        name = cellViewModel.remark;
    } else if (cellViewModel.memberInfo.nickname.length > 0) {
        name = cellViewModel.memberInfo.nickname;
    } else {
        name = cellViewModel.memberInfo.name;
    }
    NSString *message = [NSString stringWithFormat:NCUILocalizedString(@"remove_group_follows_alert"),name];
    [NCAlertView showAlertController:nil message:message actionTitles:nil cancelTitle:NCUILocalizedString(@"cancel") confirmTitle:NCUILocalizedString(@"confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
        NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:self.groupId ?: @""];
        [channel removeFavoritesWithUserIds:@[cellViewModel.memberInfo.userId ?: @""] completion:^(NCError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NCAlertView showAlertController:nil message:NCUILocalizedString(@"remove_failed") hiddenAfterDelay:1];
                });
                return;
            }
            [self fetchGroupFollows];
            dispatch_async(dispatch_get_main_queue(), ^{
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"remove_success") hiddenAfterDelay:1];
            });
        }];
    } inViewController:[self.responder currentViewController]];
}

#pragma mark -- NCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [NCGroupFollowCellViewModel registerCellForTableView:tableView];
    [NCGroupMemberAdditionalCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self pushSelectVC:viewController];
        
    }
}

- (NSInteger)numberOfSections {
    return 1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return self.mutableFollowList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.mutableFollowList[indexPath.row] tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.mutableFollowList[indexPath.row] tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark -- private
- (void)getDetailInfo:(void (^)(NSArray <NCGroupFollowCellViewModel *> *cellVMs))complete {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *mutableCellVMs = [NSMutableArray array];
        for (int i = 0; i < self.followUserIds.count; i+=100) {
            NSArray *tempUserIds = [self.followUserIds subarrayWithRange:NSMakeRange(i, MIN(100, self.followUserIds.count - i))];
            [mutableCellVMs addObjectsFromArray:[self getFollowsCellViewModels:tempUserIds]];
        }
        complete(mutableCellVMs);
    });
}

- (NSArray <NCGroupFollowCellViewModel *> *)getFollowsCellViewModels:(NSArray *)userIds {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); // Coordinate the two asynchronous requests.
    __block NSMutableArray *list = [NSMutableArray array];
    // Fetch the group member asynchronously.
    [NCGroupManager getGroupMemberInfos:self.groupId userIds:userIds complete:^(NSArray<NCGroupMemberInfo *> * _Nullable members) {
        if (!members) {
            dispatch_semaphore_signal(semaphore); // Mark the member request complete.
            return;
        }
        // Fetch friend info asynchronously.
        [NCGroupManager fetchFriendInfosWithUserIds:userIds complete:^(NSArray<NCFriendInfo *> * _Nullable friendInfos) {
            [list addObjectsFromArray:[self processMembers:members withFriendInfos:friendInfos]];
            dispatch_semaphore_signal(semaphore); // Mark the friend request complete.
        }];
    }];
    
    // Wait for both requests before assembling the result.
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return list;
}

- (NSArray <NCGroupFollowCellViewModel *> *)processMembers:(NSArray<NCGroupMemberInfo *> *)members withFriendInfos:(NSArray<NCFriendInfo *> *)friendInfos{
    NSMutableArray *list = [NSMutableArray array];
    for (NCGroupMemberInfo *member in members) {
        NCGroupFollowCellViewModel *cellVM = [[NCGroupFollowCellViewModel alloc] initWithMember:member];
        cellVM.delegate = self;
        if (friendInfos.count > 0) {
            cellVM.remark = [NCGroupManager friendWithUserId:member.userId inFriendInfos:friendInfos].remark;
        }
        [list addObject:cellVM];
    }
    return list;
}

- (void)resetMutableFollowList {
    self.mutableFollowList = [NSMutableArray array];
    UIImage *image = NCDynamicImage(@"group_manage_add_member_img");
    NCGroupMemberAdditionalCellViewModel *addVM = [[NCGroupMemberAdditionalCellViewModel alloc] initWithTitle:NCUILocalizedString(@"add_follows_member")
                                                                                                     portrait:image];
    [self.mutableFollowList addObject:addVM];
}

- (void)pushSelectVC:(UIViewController *)viewController {
    NCSelectGroupMemberViewModel *viewModel = [NCSelectGroupMemberViewModel viewModelWithGroupId:self.groupId existingUserIds:self.followUserIds];
    viewModel.hideUserIds = @[[NCEngine getCurrentUserId]];
    viewModel.maxSelectCount = 100;
    __weak typeof(self) weakSelf = self;
    [viewModel setSelectionDidCompelteBlock:^(NSArray<NSString *> * _Nonnull selectUserIds, UIViewController * _Nonnull selectVC) {
        NCGroupChannel *channel = [[NCGroupChannel alloc] initWithChannelId:weakSelf.groupId ?: @""];
        [channel addFavoritesWithUserIds:selectUserIds completion:^(NCError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NCAlertView showAlertController:nil message:NCUILocalizedString(@"add_failed") hiddenAfterDelay:1];
                });
                return;
            }
            [weakSelf fetchGroupFollows];
            dispatch_async(dispatch_get_main_queue(), ^{
                [selectVC.navigationController popViewControllerAnimated:YES];
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"add_success") hiddenAfterDelay:1];
            });
        }];
    }];
    NCSelectGroupMemberViewController *vc = [[NCSelectGroupMemberViewController alloc] initWithViewModel:viewModel];
    vc.title = NCUILocalizedString(@"select_group_member_vc_title");
    [viewController.navigationController pushViewController:vc animated:YES];
}
@end
