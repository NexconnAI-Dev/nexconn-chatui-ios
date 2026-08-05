//
//  NCUserProfileViewModel.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileViewModel.h"

NS_ASSUME_NONNULL_BEGIN
/// User profile view model
@interface NCUserProfileViewModel : NCProfileViewModel

/// User identifier
@property (nonatomic, copy, readonly) NSString *userId;

/// Associated group identifier
@property (nonatomic, copy, readonly) NSString *groupId;

/// Verifies the friendship status
@property (nonatomic, assign) BOOL verifyFriend;

/// Whether to show channel setting items when used as a direct-chat detail page.
@property (nonatomic, assign) BOOL showsChannelSettings;

/// Creates an instance
+ (NCProfileViewModel *)viewModelWithUserId:(NSString *)userId;

/// Whether to display group member nicknames
- (void)showGroupMemberInfo:(NSString *)groupId;

@end

NS_ASSUME_NONNULL_END
