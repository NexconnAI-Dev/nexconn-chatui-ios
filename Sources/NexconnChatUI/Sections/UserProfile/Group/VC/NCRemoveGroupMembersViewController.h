//
//  NCGroupRemoveMembersViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCRemoveGroupMembersViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCRemoveGroupMembersViewController : NCBaseViewController

- (instancetype)initWithViewModel:(NCRemoveGroupMembersViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
