//
//  NCProfileGenderViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileGenderViewModel.h"
#import "NCAlertView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIErrorCode.h"
#import "NCProfileGenderCell.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
@implementation NCProfileGenderViewModel
@dynamic delegate;

#pragma mark-- NCListViewModelProtocol
- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:NCProfileGenderCell.class
        forCellReuseIdentifier:NCProfileGenderCellIdentifier];
}

- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    [self itemDidSelectedAtIndexPath:indexPath];
}

- (NSArray<NCProfileGenderCellViewModel *> *)dataSource {
    if (!_dataSource) {
        NCProfileGenderCellViewModel *maleVM =
            [NCProfileGenderCellViewModel cellViewModel:NCChatUIUserGenderMale];
        maleVM.isSelect = (self.profle.gender == NCChatUIUserGenderMale);

        NCProfileGenderCellViewModel *femaleVM =
            [NCProfileGenderCellViewModel cellViewModel:NCChatUIUserGenderFemale];
        femaleVM.isSelect = (self.profle.gender == NCChatUIUserGenderFemale);
        femaleVM.hideSeparatorLine = YES;
        _dataSource = @[ maleVM, femaleVM ];
    }
    return _dataSource;
}

- (void)updateUserProfileGender:(UIViewController *)viewController {
    NSInteger gender = 0;
    for (int i = 0; i < self.dataSource.count; i++) {
        NCProfileGenderCellViewModel *cellViewModel = self.dataSource[i];
        if (cellViewModel.isSelect) {
            gender = cellViewModel.gender;
            break;
        }
    }
    self.profle.gender = gender;
    [self loadingWithTip:NCUILocalizedString(@"saving")];

    [[NCEngine userModule]
        updateMyUserProfile:self.profle
                 completion:^(NSArray<NSString *> *_Nullable errorKeys, NCError *_Nullable error) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                     [self stopLoading];
                     if (!error) {
                         [viewController.navigationController popViewControllerAnimated:YES];
                         [NCAlertView showAlertController:nil
                                                  message:NCUILocalizedString(@"set_success")
                                         hiddenAfterDelay:1];
                         return;
                     }
                     NSString *tips = NCUILocalizedString(@"set_failed");
                     if (error.code == NCChatUIErrorCodeInformationAuditFailed) {
                         tips = NCUILocalizedString(@"content_contains_sensitive");
                     }
                     [NCAlertView showAlertController:nil message:tips hiddenAfterDelay:1];
                   });
                 }];
}

- (void)itemDidSelectedAtIndexPath:(NSIndexPath *)indexPath {
    for (int i = 0; i < self.dataSource.count; i++) {
        NCProfileGenderCellViewModel *cellViewModel = self.dataSource[i];
        if (i == indexPath.row) {
            cellViewModel.isSelect = YES;
        } else {
            cellViewModel.isSelect = NO;
        }
        [cellViewModel reloadData];
    }
}
@end
