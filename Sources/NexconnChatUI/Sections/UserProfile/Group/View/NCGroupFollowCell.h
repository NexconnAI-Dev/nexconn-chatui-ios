//
//  NCGroupFollowCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCButton.h"
#import "NCImageView.h"
#import "NCStackTableViewCell.h"
NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString *_Nonnull const NCGroupFollowCellIdentifier;

@interface NCGroupFollowCell : NCStackTableViewCell

@property (nonatomic, strong) NCImageView *portraitImageView;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) NCButton *actionButton;

@property (nonatomic, copy) void (^actionBlock)(void);
@end

NS_ASSUME_NONNULL_END
