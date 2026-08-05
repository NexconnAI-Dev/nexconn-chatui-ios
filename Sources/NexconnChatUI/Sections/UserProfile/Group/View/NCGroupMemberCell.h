//
//  NCGroupMemberCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStackTableViewCell.h"
#import "NCImageView.h"

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString  * _Nonnull const NCGroupMemberCellIdentifier;

@interface NCGroupMemberCell : NCStackTableViewCell

@property (nonatomic, strong) NCImageView *portraitImageView;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *roleLabel;

@property (nonatomic, strong) NCBaseImageView *arrowView;

- (void)hiddenArrow:(BOOL)hiddenArrow;

@end

NS_ASSUME_NONNULL_END
