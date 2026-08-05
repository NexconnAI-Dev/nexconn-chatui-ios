//
//  NCGroupProfileViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileViewModel.h"

NS_ASSUME_NONNULL_BEGIN
/// Group profile view model
@interface NCGroupProfileViewModel : NCProfileViewModel

/// Group identifier
@property (nonatomic, copy, readonly) NSString *groupId;

/// Maximum number of group members to display. Defaults to 30, range: [5, 50].
@property (nonatomic, assign, setter=setDisplayMaxMemberCount:) NSInteger displayMaxMemberCount;

/// Creates an `NCGroupProfileViewModel` instance
///
/// @param groupId The group identifier
+ (instancetype)viewModelWithGroupId:(NSString *)groupId;

@end

NS_ASSUME_NONNULL_END
