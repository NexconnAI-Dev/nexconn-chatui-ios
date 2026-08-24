//
//  NCGroupMemberHeaderCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCollectionViewCell.h"
#import "NCImageView.h"

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString *_Nonnull const NCGroupMemberHeaderCellIdentifier;

@interface NCGroupMemberHeaderCell : NCBaseCollectionViewCell

@property (nonatomic, strong) NCImageView *portraitImageView;

@property (nonatomic, strong) UILabel *nameLabel;

@end

NS_ASSUME_NONNULL_END
