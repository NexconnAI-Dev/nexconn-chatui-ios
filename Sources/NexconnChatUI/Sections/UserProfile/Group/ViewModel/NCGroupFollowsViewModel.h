//
//  NCGroupFollowsViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCListViewModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN
/// Group favorites view model
@interface NCGroupFollowsViewModel : NCBaseViewModel <NCListViewModelProtocol>
/// Creates an `NCGroupFollowsViewModel` instance
///
/// @param groupId The group owner identifier
+ (instancetype)viewModelWithGroupId:(NSString *)groupId;

/// Binds the responder
- (void)bindResponder:(id<NCListViewModelResponder>)responder;

/// Fetches the group favorites list
- (void)fetchGroupFollows;

@end

NS_ASSUME_NONNULL_END
