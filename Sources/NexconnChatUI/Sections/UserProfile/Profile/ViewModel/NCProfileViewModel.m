//
//  NCUserProfileViewModel.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileViewModel.h"

@interface NCProfileViewModel ()

@property (nonatomic, strong) NCProfileFooterViewModel *footerViewModel;

@property (nonatomic, strong) NSArray<NSArray<NCProfileCellViewModel *> *> *profileList;

@end

@implementation NCProfileViewModel
@dynamic delegate;

- (void)updateProfile {
}

- (void)configFooterViewModel:(NCProfileFooterViewModel *)viewModel {
    if ([self.delegate
            respondsToSelector:@selector(profileViewModel:willLoadProfileFooterViewModel:)]) {
        self.footerViewModel = [self.delegate profileViewModel:self
                                willLoadProfileFooterViewModel:viewModel];
    } else {
        self.footerViewModel = viewModel;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.responder reloadFooterView];
    });
}

- (UIView *)loadFooterView {
    return [self.footerViewModel loadView];
}

- (void)setProfileList:(NSArray<NSArray<NCProfileCellViewModel *> *> *)profileList {
    NSArray *array = nil;
    if ([self.delegate
            respondsToSelector:@selector(profileViewModel:willLoadProfileCellViewModel:)]) {
        array = [self.delegate profileViewModel:self willLoadProfileCellViewModel:profileList];
    } else {
        array = profileList;
    }
    for (NSArray *tmp in array) {
        if ([tmp isKindOfClass:[NSArray class]]) {
            NCBaseCellViewModel *vm = [tmp lastObject];
            if ([vm isKindOfClass:[NCBaseCellViewModel class]]) {
                vm.hideSeparatorLine = YES;
            }
        }
    }
    _profileList = array;
}

@end
