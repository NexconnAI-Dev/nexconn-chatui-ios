//
//  NCFriendListPermanentCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStackTableViewCell.h"
#import "NCOnlineStatusView.h"
UIKIT_EXTERN NSString * _Nullable const NCFriendListPermanentCellIdentifier;
@class NCImageView;

NS_ASSUME_NONNULL_BEGIN

@interface NCFriendListPermanentCell : NCStackTableViewCell
/*!
Avatar of the message sender
*/
@property (nonatomic, strong) NCImageView *portraitImageView;
@property (nonatomic, strong) NCOnlineStatusView *onlineStatusView;
@property (nonatomic, strong) UILabel *labName;
- (void)showPortraitByImage:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
