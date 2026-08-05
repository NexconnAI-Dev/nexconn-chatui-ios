//
//  NCApplyFriendCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCApplyFriendCellViewModel.h"
#import "NCApplyFriendOperationCell.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCApplyFriendAlertView.h"
#import "NCAlertView.h"

NSInteger const NCFriendApplyCellHeight = 78;
@interface NCApplyFriendCellViewModel()
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong)  NSIndexPath *indexPath;
@property (nonatomic, assign) CGFloat cellHeightOfExpand;
@property (nonatomic, weak) UIViewController <NCListViewModelResponder> *responder;
@end

@implementation NCApplyFriendCellViewModel

- (instancetype)initWithApplicationInfo:(NCFriendApplicationInfo *)application
{
    self = [super init];
    if (self) {
        self.application = application;
    }
    return self;
}

- (BOOL)shouldHideExpandButton:(CGSize)size natureSize:(CGSize)natureSize {
    if (self.style == NCFriendApplyCellStyleFolder) {
        return NO;
    }
    if (self.style == NCFriendApplyCellStyleNone) {
        if (natureSize.height > size.height) {
            self.style = NCFriendApplyCellStyleFolder;
            self.cellHeightOfExpand = NCFriendApplyCellHeight-size.height+natureSize.height;
            return NO;
        } else {
            self.style = NCFriendApplyCellStyleNormal;
        }
    }
    return YES;
}

#pragma mark - NCCellViewModelProtocol
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.tableView = tableView;
    self.indexPath = indexPath;
    NCApplyFriendCell *cell = nil;
    if (self.application.applicationStatus == NCFriendApplicationStatusUnHandled &&
        self.application.applicationType == NCFriendApplicationTypeReceived ) {
        cell = [tableView dequeueReusableCellWithIdentifier:NCFriendApplyOperationCellIdentifier
                                                                           forIndexPath:indexPath];
        if (!cell) {
            cell = [[NCApplyFriendOperationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NCFriendApplyOperationCellIdentifier];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:NCFriendApplyCellIdentifier
                                                                  forIndexPath:indexPath];
        if (!cell) {
            cell = [[NCApplyFriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NCFriendApplyCellIdentifier];
        }
    }
    cell.hideSeparatorLine = self.hideSeparatorLine;
    [cell updateWithViewModel:self];
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
    
}
#pragma mark - Function
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
                                    completion:(void(^)(NSInteger errorCode))completion {
    /* Temporarily disabled for the initial release.
    UITableViewRowAction *actionDelete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NCUILocalizedString(@"delete") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [self deleteApplication:completion];
    }];
 
    return @[actionDelete];
     */
    return nil;
}


- (void)approveApplication {
    [[NCEngine userModule] acceptFriendApplicationWithUserId:self.application.userId
                                                  completion:^(NCError * _Nullable error) {
        if (error) {
            [self showTips:NCUILocalizedString(@"friend_application_accept_failed")];
            return;
        }
        self.application.applicationStatus = NCFriendApplicationStatusAccepted;
        [self reloadCell];
        }];
}

- (void)showTips:(NSString *)tips {
    if ([self.responder respondsToSelector:@selector(showTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder showTips:tips];
        });
    }
}

- (void)rejectApplication {
    [self showRefuseAlertView];
}

- (void)commitRefuse:(NSString *)reason {
    (void)reason;
    [[NCEngine userModule] refuseFriendApplicationWithUserId:self.application.userId completion:^(NCError * _Nullable error) {
        if (error) {
            [self showTips:NCUILocalizedString(@"friend_application_refuse_failed")];
            return;
        }
        self.application.applicationStatus = NCFriendApplicationStatusRefused;
        [self reloadCell];
    }];
}

- (void)showRefuseAlertView {
    [NCAlertView showAlertController:nil message:[NSString stringWithFormat:@"%@?", NCUILocalizedString(@"friend_apply_refuse_title")] actionTitles:nil cancelTitle:NCUILocalizedString(@"cancel") confirmTitle:NCUILocalizedString(@"confirm") preferredStyle:UIAlertControllerStyleAlert actionsBlock:nil cancelBlock:^{
    } confirmBlock:^{
        [self commitRefuse:@""];  
    } inViewController:self.responder];
    
//    [NCApplyFriendAlertView showAlert:NCUILocalizedString(@"friend_apply_refuse_title")
//                          placeholder:NCUILocalizedString(@"friend_apply_refuse_placeholder")
//                          lengthLimit:64
//                           completion:^(NSString * text) {
//        [self commitRefuse:text];
//    }];
}

- (void)expandRemark {
    self.style = NCFriendApplyCellStyleExpand;
    [self reloadCell];
}

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCApplyFriendCell class]
      forCellReuseIdentifier:NCFriendApplyCellIdentifier];
    [tableView registerClass:[NCApplyFriendOperationCell class]
      forCellReuseIdentifier:NCFriendApplyOperationCellIdentifier];
}

- (CGFloat)cellHeight {
    if (self.style != NCFriendApplyCellStyleExpand) {
        return NCFriendApplyCellHeight;
    } else {
        return self.cellHeightOfExpand;
    }
}

- (void)bindResponder:(UIViewController <NCListViewModelResponder>*)responder {
    self.responder = responder;
}
#pragma mark - Private

- (void)setApplication:(NCFriendApplicationInfo *)application {
    _application = application;
    if (_application.extra.length == 0) {
        _application.extra = NCUILocalizedString(@"friend_application_default_extra");
    }
}

- (void)reloadCell {
    if (self.indexPath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadRowsAtIndexPaths:@[self.indexPath] withRowAnimation:UITableViewRowAnimationFade];
        });
    }
}
@end
