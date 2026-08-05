//
//  NCProfileGenderViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCProfileGenderCellViewModel.h"
#import "NCListViewModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class NCUserProfile;

@interface NCProfileGenderViewModel : NCBaseViewModel<NCListViewModelProtocol>

@property (nonatomic, strong) NCUserProfile *profle;

@property (nonatomic, strong) NSArray <NCProfileGenderCellViewModel *> *dataSource;

- (void)updateUserProfileGender:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
