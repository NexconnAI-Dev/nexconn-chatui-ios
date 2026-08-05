//
//  NCMyProfileViewModel.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMyProfileViewModel.h"
#import "NCProfileCommonCellViewModel.h"
#import "NCProfileCommonTextCell.h"
#import "NCProfileCommonImageCell.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <NexconnChatUI/NCChatUILog.h>
#import "NCChatUICommonDefine.h"
#import "NCNameEditViewController.h"
#import "NCGenderSelectViewController.h"
#import "NCProfileViewModel+private.h"
@interface NCMyProfileViewModel ()

@property (nonatomic, strong) NCUserProfile *userProfile;

@end

@implementation NCMyProfileViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCProfileCommonTextCell class]
      forCellReuseIdentifier:NCProfileTextCellIdentifier];
    [tableView registerClass:[NCProfileCommonImageCell class]
      forCellReuseIdentifier:NCProfileImageCellIdentifier];
}

- (void)updateProfile {
    [[NCEngine userModule] getMyUserProfileWithCompletion:^(NCUserProfile * _Nullable userProfile, NCError * _Nullable error) {
        if (error) {
            NCLogE(@"get my User Profiles error");
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.profileList = [self reloadDataSource:userProfile];
            [self.responder reloadData:NO];
        });
    }];
}

#pragma mark -- NCListViewModelProtocol

- (void)viewController:(UIViewController *)viewController tableView:(UITableView *)tableView didSelectRow:(NSIndexPath *)indexPath {
    NCProfileCellViewModel *cellViewModel = self.profileList[indexPath.section][indexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(profileViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate profileViewModel:self viewController:viewController tableView:tableView didSelectRow:indexPath cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }
    
    if (![cellViewModel isKindOfClass:NCProfileCommonCellViewModel.class]) {
        return;
    }
    
    NCProfileCommonCellViewModel *commonCellViewModel = (NCProfileCommonCellViewModel *)cellViewModel;
    if ([commonCellViewModel.title isEqualToString:NCUILocalizedString(@"name")]) {
        NCNameEditViewModel *viewModel = [NCNameEditViewModel viewModelWithUserId:[NCEngine getCurrentUserId] ?: @"" groupId:nil type:NCNameEditTypeName];
        NCNameEditViewController *nameEditVC = [[NCNameEditViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:nameEditVC animated:YES];
    } else if([commonCellViewModel.title isEqualToString:NCUILocalizedString(@"gender")]) {
        NCProfileGenderViewModel *viewModel = [[NCProfileGenderViewModel alloc] init];
        viewModel.profle = self.userProfile;
        NCGenderSelectViewController *genderVC = [[NCGenderSelectViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:genderVC animated:YES];
    }
}

#pragma mark -- private

- (NSArray<NSArray<NCProfileCellViewModel *> *> *)reloadDataSource:(NCUserProfile *)userProfile {
    self.userProfile = userProfile;
    NCProfileCommonCellViewModel *portraitViewModel = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeImage title:NCUILocalizedString(@"portrait") detail:self.userProfile.avatarUrl];
    portraitViewModel.hiddenArrow = YES;
    
    NCProfileCommonCellViewModel *nameViewModel = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"name") detail:self.userProfile.name];
    
    NCProfileCommonCellViewModel *uniqueIdViewModel = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"application_number") detail:self.userProfile.uniqueId];
    uniqueIdViewModel.hiddenArrow = YES;
    
    NCProfileCommonCellViewModel *genderViewModel = [[NCProfileCommonCellViewModel alloc] initWithCellType:NCUProfileCellTypeText title:NCUILocalizedString(@"gender") detail:[self getGenderString:self.userProfile.gender]];
    genderViewModel.hideSeparatorLine = YES;
    NSArray *array = @[
        @[portraitViewModel, nameViewModel, uniqueIdViewModel, genderViewModel]
    ];
    return array;
}

- (NSString *)getGenderString:(NSInteger)gender {
    switch (gender) {
        case 1:
            return NCUILocalizedString(@"male");
        case 2:
            return NCUILocalizedString(@"female");
        default:
            break;
    }
    return NCUILocalizedString(@"unknown");
}

@end
