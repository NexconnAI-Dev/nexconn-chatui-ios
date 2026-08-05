//
//  NCUserSearchViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUserSearchViewModel.h"
#import "NCSearchUserProfileViewModel.h"
#import "NCUserProfileViewModel.h"
#import "NCProfileViewController.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIErrorCode.h"

@interface NCUserSearchViewModel()<NCSearchUserProfileViewModelDelegate>
@property (nonatomic, strong) NCSearchUserProfileViewModel *searchBarVM;
@property (nonatomic, strong) NCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, weak) UIViewController <NCListViewModelResponder> *responder;

@end

@implementation NCUserSearchViewModel
@dynamic delegate;

#pragma mark - Public

- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureSearchBarViewModelForUserSearchViewModel:)]) {
        self.searchBarVM = [self.delegate willConfigureSearchBarViewModelForUserSearchViewModel:self];
    } else if(!self.searchBarVM) {
        NCSearchUserProfileViewModel *vm = [[NCSearchUserProfileViewModel alloc] initWithPlaceholder:NCUILocalizedString(@"user_search_application_number")];
        vm.delegate = self;
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForUserSearchViewModel:)]) {
        self.naviItemsVM = [self.delegate willConfigureRightNavigationItemsForUserSearchViewModel:self];
    } else if(!self.naviItemsVM) {
        NCNavigationItemsViewModel *vm = [[NCNavigationItemsViewModel alloc] initWithResponder:viewController];
        self.naviItemsVM = vm;
    }
    return [self.naviItemsVM rightNavigationBarItems];
}

- (void)endEditingState {
    [self.searchBarVM endEditingState];
}

- (void)bindResponder:(UIViewController <NCListViewModelResponder>*)responder {
    self.responder = responder;
}


#pragma mark - NCSearchUserProfileViewModelDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadData:NO];
}

- (void)searchUserProfileWithText:(NSString *)text {
    if ([self.delegate respondsToSelector:@selector(userSearchViewModel:searchUserProfileWithText:)]) {
        BOOL ret = [self.delegate userSearchViewModel:self
                            searchUserProfileWithText:text];
        if (ret) {
            return;
        }
    }
    [self startLoading];
    [[NCEngine userModule] getUserProfilesWithUserIds:@[text ?: @""]
                                           completion:^(NSArray<NCUserProfile *> * _Nullable userProfiles, NCError * _Nullable error) {
        if (error) {
            [self showTipsWithCode:error.code];
            if (error.code == NCChatUIErrorCodeUserProfileUserNotExist) {
                [self reloadData:YES];
            }
            [self endLoading];
            return;
        }
        NCUserProfile *userProfile = userProfiles.firstObject;
        [self reloadData:userProfile == nil];
        if (userProfile) {
            [self showUserProfile:userProfile];
        }
        if (userProfiles.count == 0) {
            [self reloadData:YES];
        }
        [self endLoading];
    }];
}
#pragma mark -- Private
- (void)startLoading {
    if ([self.responder respondsToSelector:@selector(startLoading)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder startLoading];
        });
    }
}

- (void)endLoading {
    if ([self.responder respondsToSelector:@selector(endLoading)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder endLoading];
        });
    }
}

- (void)showUserProfile:(NCUserProfile *)profile {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(userSearchViewModel:showUserProfile:)]) {
            BOOL ret = [self.delegate userSearchViewModel:self
                                          showUserProfile:profile];
            if (ret) {
                return;
            }
        }
        NCProfileViewModel *viewModel = [NCUserProfileViewModel viewModelWithUserId:profile.userId];
        NCProfileViewController *vc = [[NCProfileViewController alloc] initWithViewModel:viewModel];
        [self.responder.navigationController pushViewController:vc
                                                       animated:YES];
    });
}
- (void)showTipsWithCode:(NCChatUIErrorCode)errorCode {
    if ([self.responder respondsToSelector:@selector(showTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder showTips:NCUILocalizedString(@"user_search_failed")];
        });
    }
}

- (void)reloadData:(BOOL)ret {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder reloadData:ret];
        });
    }
}

@end
