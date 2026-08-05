//
//  NCUserProfileHeaderCell.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStackTableViewCell.h"
#import "NCImageView.h"
#import "NCOnlineStatusView.h"

UIKIT_EXTERN NSString  * _Nullable const NCUserProfileHeaderCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface NCUserProfileHeaderCell : NCStackTableViewCell

@property (nonatomic, strong) NCImageView *portraitImageView;

/// Online status icon.
/// Hidden by default.
@property (nonatomic, strong) NCOnlineStatusView *onlineStatusView;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *remarkLabel;

- (void)hiddenNameLabel:(BOOL)hidden;

- (void)hiddenOnlineStatusView:(BOOL)hidden;

- (void)updateOnlineStatus:(BOOL)isOnline;

@end

NS_ASSUME_NONNULL_END
