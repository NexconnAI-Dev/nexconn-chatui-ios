//
//  NCUserProfileHeaderCellViewModel.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCUserProfileHeaderCellViewModel : NCProfileCellViewModel

@property (nonatomic, copy) NSString *portrait;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *remark;

/// Whether to display online status.
/// Defaults to NO.
@property (nonatomic, assign) BOOL displayOnlineStatus;

/// Defaults to NO, indicating offline status.
@property (nonatomic, assign) BOOL isOnline;

/// Whether the online status has been resolved (non-nil). Defaults to NO.
@property (nonatomic, assign) BOOL hasOnlineStatus;

- (instancetype)initWithPortrait:(NSString *)portrait
                            name:(NSString *)name
                          remark:(NSString *)remark;

@end

NS_ASSUME_NONNULL_END
